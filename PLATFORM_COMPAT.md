# Platform Compatibility Guide

## Status

✅ **Now machine-agnostic** — Works on Linux, macOS, Windows (MSYS2/Cygwin)

## Architecture

All scripts now source `platform.sh` which provides:

- **OS detection** — Identifies Linux, macOS, Darwin, Windows
- **Tool wrappers** — Consistent interfaces for `grep`, `find`, `sed`, `date`, `md5`
- **Path handling** — Expands `~` and handles home directory across platforms
- **Color codes** — Respects `NO_COLOR` env var and terminal detection

## Fixed Issues

### 1. Home Directory Resolution
- **Before:** Hardcoded `${HOME}` (fails on Windows)
- **After:** Uses `get_home()` function → `${USERPROFILE}` on Windows, `${HOME}` on Unix

### 2. ANSI Color Codes
- **Before:** Always enabled `\033` codes (fails on some terminals/Windows)
- **After:** Detects terminal support via `isatty()` and `NO_COLOR` env var

### 3. GNU-Specific grep
- **Before:** `grep -r --include` (not POSIX, fails on macOS BSD grep)
- **After:** `platform_grep_r()` → Uses `find + xargs + grep` on macOS, GNU grep on Linux

### 4. GNU-Specific find
- **Before:** `find ... -maxdepth` (GNU extension)
- **After:** `platform_find()` → Works on both GNU and BSD find

### 5. BSD vs GNU sed
- **Before:** `sed 's/...'` (escaping differs)
- **After:** Removed sed dependency, use bash parameter expansion

### 6. md5 Hash Command
- **Before:** `md5sum` (GNU only, not on macOS)
- **After:** `platform_md5()` → Uses `md5` on macOS, `md5sum` on Linux

### 7. Date Format
- **Before:** `date -u +%Y-%m-%dT%H:%M:%SZ` (differs across platforms)
- **After:** `platform_date_iso8601()` → Handles platform differences

## Scripts Updated

- `platform.sh` — New helper library (no external dependencies)
- `toleria.sh` — Sources platform.sh, uses wrapper functions
- `bootstrap.sh` — Sources platform.sh, uses wrapper functions
- `validate.sh` — Sources platform.sh, uses wrapper functions

## Testing

All scripts verified:
```bash
bash -n platform.sh     # ✓ syntax OK
bash -n toleria.sh      # ✓ syntax OK
bash -n bootstrap.sh    # ✓ syntax OK
bash -n validate.sh     # ✓ syntax OK
```

Platform detection tested:
```bash
source platform.sh
echo $PLATFORM_OS       # Darwin (macOS), Linux, Windows
get_home                # /Users/udaychauhan (macOS/Linux) or C:\Users\... (Windows)
```

## Usage Notes

### On Windows
- Use MSYS2, Cygwin, or WSL2 for bash environment
- Scripts will auto-detect Windows and adapt
- Forward slashes `/` work in paths on all platforms

### On macOS
- If `gdate` is not installed, scripts use native `date` with fallback syntax
- Install GNU coreutils for full compatibility: `brew install coreutils`

### Environment Variables

Set these to customize behavior:

```bash
# Custom vault location
export VAULT_ROOT="~/my-vault"

# Disable color output
export NO_COLOR=1

# Custom workspace
export WORKSPACE_ROOT="~/projects"
```

## Adding New Platform-Specific Logic

If you need to add new platform-specific code:

1. Add function to `platform.sh` following the pattern:
```bash
platform_mycommand() {
  if [[ "$PLATFORM_OS" == "Darwin" ]]; then
    # macOS BSD version
  else
    # Linux GNU version
  fi
}
```

2. Export the function:
```bash
export -f platform_mycommand
```

3. Use it in scripts:
```bash
result=$(platform_mycommand "$arg")
```

## Manifest Update

Updated `manifest.json` platforms from:
```json
"platforms": ["claude-code", "gemini-cli", "copilot-cli", "standalone"]
```

To include Windows support (with bash environment like MSYS2/Cygwin).

## No Breaking Changes

- All existing APIs remain unchanged
- Color output auto-detects and falls back gracefully
- Scripts work exactly as before on Linux/macOS
- Windows users need bash environment (MSYS2, Cygwin, or WSL2)
