#!/bin/bash

###############################################################################
# YAML Utilities - Parse/Generate YAML frontmatter
#
# Functions:
#   yaml_parse_frontmatter <file_path>  → returns YAML as JSON
#   yaml_extract_field <key> <yaml>     → returns value
#   yaml_generate <key1> <val1> ...     → generates YAML block
#
###############################################################################

set -e

# Parse YAML frontmatter from file (between --- markers)
yaml_parse_frontmatter() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo '{}' && return 0
  fi

  local in_frontmatter=0
  local yaml_block=""

  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      if (( in_frontmatter == 0 )); then
        in_frontmatter=1
        continue
      else
        break
      fi
    fi

    if (( in_frontmatter == 1 )); then
      yaml_block+="$line"$'\n'
    fi
  done < "$file"

  # Parse YAML to JSON using jq (assumes valid YAML structure)
  if [[ -z "$yaml_block" ]]; then
    echo '{}'
  else
    # Convert YAML to JSON manually (simple key: value parsing)
    echo "$yaml_block" | yaml_to_json
  fi
}

# Convert YAML array syntax to JSON array
yaml_array_to_json() {
  local yaml_array="$1"
  local json_array="["
  local first=1

  # Remove outer brackets
  yaml_array="${yaml_array#[}"
  yaml_array="${yaml_array%]}"

  # Split on comma and process each item
  while IFS=',' read -r item; do
    item="${item#[[:space:]]}"  # Trim leading whitespace
    item="${item%[[:space:]]}"  # Trim trailing whitespace

    if [[ -n "$item" ]]; then
      if (( first == 0 )); then
        json_array+=","
      fi
      first=0

      # Quote item (it's always a string in YAML flow syntax)
      item="${item//\"/\\\"}"
      json_array+="\"$item\""
    fi
  done <<< "$yaml_array"

  json_array+="]"
  echo "$json_array"
}

# Convert simple YAML to JSON
yaml_to_json() {
  local json='{'
  local first=1

  while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" || "$line" =~ ^[[:space:]]*$ ]] && continue

    # Parse key: value
    if [[ "$line" =~ ^([^:]+):[[:space:]]*(.*)$ ]]; then
      local key="${BASH_REMATCH[1]}"
      local value="${BASH_REMATCH[2]}"

      # Add comma if not first
      if (( first == 0 )); then
        json+=','
      fi
      first=0

      # Quote key
      json+="\"$key\":"

      # Quote value (unless it's an array or null)
      if [[ "$value" =~ ^[0-9]+$ ]]; then
        json+="$value"
      elif [[ "$value" == "true" || "$value" == "false" || "$value" == "null" ]]; then
        json+="$value"
      elif [[ "$value" =~ ^\[.*\]$ ]]; then
        # Check if it's already valid JSON by trying to parse with jq
        if echo "$value" | jq . >/dev/null 2>&1; then
          # Already valid JSON, pass through
          json+="$value"
        else
          # Convert YAML flow syntax to JSON array
          json+=$(yaml_array_to_json "$value")
        fi
      else
        # Escape quotes in string
        value="${value//\"/\\\"}"
        json+="\"$value\""
      fi
    fi
  done

  json+='}'
  echo "$json"
}

# Extract field from YAML JSON
yaml_extract_field() {
  local key="$1"
  local yaml_json="$2"

  echo "$yaml_json" | jq -r ".\"$key\" // empty" 2>/dev/null || echo ""
}

# Generate YAML frontmatter block
yaml_generate() {
  echo "---"
  while (( $# > 0 )); do
    local key="$1"
    local value="$2"
    shift 2

    # Quote value if it contains special chars
    if [[ "$value" =~ [[:space:]:\[\]] ]]; then
      echo "$key: \"$value\""
    else
      echo "$key: $value"
    fi
  done
  echo "---"
}

# Extract content (everything after frontmatter)
yaml_extract_content() {
  local file="$1"

  local in_frontmatter=0
  local found_end=0

  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      if (( in_frontmatter == 0 )); then
        in_frontmatter=1
        continue
      else
        found_end=1
        continue
      fi
    fi

    if (( found_end == 1 )); then
      echo "$line"
    fi
  done < "$file"
}

# Export functions
export -f yaml_parse_frontmatter yaml_extract_field yaml_generate yaml_extract_content yaml_to_json yaml_array_to_json
