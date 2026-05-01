#!/bin/bash

###############################################################################
# Platform Detection & Cross-Platform Tool Wrappers
#
# Detects OS and provides consistent interfaces for:
# - Color output (respects NO_COLOR, terminal detection)
# - Path handling (Unix vs Windows)
# - Tool availability (grep, find, sed, date, md5)
# - Home directory resolution
#
###############################################################################

# Detect OS
detect_os() {
  case "$(uname -s)" in
    Linux*)     echo "Linux" ;;
    Darwin*)    echo "Darwin" ;;
    MINGW*|MSYS*|CYGWIN*) echo "Windows" ;;
    *)          echo "Unknown" ;;
  esac
}

PLATFORM_OS=$(detect_os)

# Detect if output supports colors
supports_color() {
  if [[ "${NO_COLOR:-}" != "" ]]; then
    return 1  # NO_COLOR env var set
  fi

  if [[ -t 1 ]]; then
    return 0  # stdout is a terminal
  fi

  return 1
}

# Color codes (set to empty if no color support)
if supports_color; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  NC=''
fi

# Cross-platform home directory
get_home() {
  if [[ "$PLATFORM_OS" == "Windows" ]]; then
    echo "${USERPROFILE}"
  else
    echo "${HOME}"
  fi
}

# Normalize path for current platform
normalize_path() {
  local path="$1"

  # Expand ~ first
  path="${path/#\~/"$(get_home)"}"

  if [[ "$PLATFORM_OS" == "Windows" ]]; then
    # Convert forward slashes to backslashes on Windows (optional - most tools accept /)
    # For now, keep forward slashes as they work on all platforms
    echo "$path"
  else
    echo "$path"
  fi
}

# Cross-platform grep with standard options
platform_grep() {
  local pattern="$1"
  local file="$2"

  if [[ "$PLATFORM_OS" == "Darwin" ]]; then
    # macOS BSD grep
    grep "$pattern" "$file"
  else
    # Linux/GNU grep
    grep "$pattern" "$file"
  fi
}

# Cross-platform grep recursive
platform_grep_r() {
  local pattern="$1"
  shift
  local files=("$@")

  if [[ "$PLATFORM_OS" == "Darwin" ]]; then
    # macOS: use find + xargs + grep to avoid GNU-specific flags
    find "${files[@]}" -type f -print0 2>/dev/null | xargs -0 grep "$pattern" 2>/dev/null || true
  else
    # Linux: GNU grep has --include, use if available
    grep -r "$pattern" "${files[@]}" 2>/dev/null || true
  fi
}

# Cross-platform grep recursive with file type filter
platform_grep_r_type() {
  local pattern="$1"
  local file_pattern="$2"
  local search_dir="$3"

  if [[ "$PLATFORM_OS" == "Darwin" ]]; then
    # macOS: find + grep
    find "$search_dir" -type f -name "$file_pattern" -print0 2>/dev/null | \
      xargs -0 grep "$pattern" 2>/dev/null | cut -d: -f1 | sort -u || true
  else
    # Linux: GNU grep with --include
    grep -r --include="$file_pattern" "$pattern" "$search_dir" 2>/dev/null | \
      cut -d: -f1 | sort -u || true
  fi
}

# Cross-platform find with consistent options
platform_find() {
  local dir="$1"
  local maxdepth="$2"
  shift 2
  local args=("$@")

  if [[ "$PLATFORM_OS" == "Darwin" ]]; then
    # macOS BSD find (supports -maxdepth)
    find "$dir" -maxdepth "$maxdepth" "${args[@]}" 2>/dev/null || true
  else
    # Linux GNU find
    find "$dir" -maxdepth "$maxdepth" "${args[@]}" 2>/dev/null || true
  fi
}

# Cross-platform sed (GNU sed vs BSD sed have different syntax)
platform_sed() {
  local expression="$1"
  local file="$2"

  if [[ "$PLATFORM_OS" == "Darwin" ]]; then
    # macOS BSD sed requires -e for empty extension
    sed -e "$expression" "$file"
  else
    # Linux GNU sed
    sed "$expression" "$file"
  fi
}

# Cross-platform md5 hash
platform_md5() {
  local input="$1"

  if [[ "$PLATFORM_OS" == "Darwin" ]]; then
    # macOS: md5 (part of BSD)
    echo -n "$input" | md5 | awk '{print $1}'
  else
    # Linux: md5sum
    echo -n "$input" | md5sum | awk '{print $1}'
  fi
}

# Cross-platform md5 for files
platform_md5_file() {
  local file="$1"

  if [[ "$PLATFORM_OS" == "Darwin" ]]; then
    # macOS: md5
    md5 "$file" | awk '{print $NF}' | tr -d '()'
  else
    # Linux: md5sum
    md5sum "$file" | awk '{print $1}'
  fi
}

# Cross-platform date ISO 8601 UTC
platform_date_iso8601() {
  if [[ "$PLATFORM_OS" == "Darwin" ]]; then
    # macOS: use gdate if available (from GNU coreutils), fallback to date
    if command -v gdate &>/dev/null; then
      gdate -u +%Y-%m-%dT%H:%M:%SZ
    else
      # BSD date (different format, approximate)
      date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u "+%Y-%m-%dT%H:%M:%SZ"
    fi
  else
    # Linux: GNU date
    date -u +%Y-%m-%dT%H:%M:%SZ
  fi
}

# Export functions and variables for sourced scripts
export PLATFORM_OS RED GREEN YELLOW BLUE NC
export -f get_home normalize_path platform_grep platform_grep_r \
  platform_grep_r_type platform_find platform_sed platform_md5 \
  platform_md5_file platform_date_iso8601
