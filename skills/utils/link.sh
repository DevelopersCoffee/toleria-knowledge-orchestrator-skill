#!/bin/bash

###############################################################################
# Link Utilities - Generate/parse wikilinks
#
# Functions:
#   link_create <id> <title>            → [[id|title]]
#   link_parse <wikilink>               → {id, title}
#   link_array_from_json <json_array>   → wikilinks string
#   link_array_to_json <wikilinks_str>  → JSON array
#
###############################################################################

set -e

# Create wikilink from id and optional title
link_create() {
  local id="$1"
  local title="${2:-$id}"

  if [[ "$title" == "$id" ]]; then
    echo "[[${id}]]"
  else
    echo "[[${id}|${title}]]"
  fi
}

# Parse wikilink and extract id and title
link_parse() {
  local link="$1"

  # Remove [[ and ]]
  link="${link//\[\[}"
  link="${link//\]\]}"

  # Split on |
  if [[ "$link" == *"|"* ]]; then
    local id="${link%%|*}"
    local title="${link##*|}"
    echo "{\"id\":\"$id\",\"title\":\"$title\"}"
  else
    echo "{\"id\":\"$link\",\"title\":\"$link\"}"
  fi
}

# Convert JSON array of links to wikilink strings
link_array_to_text() {
  local json_array="$1"

  echo "$json_array" | jq -r '.[] | "[[" + .id + (if .title and .title != .id then "|" + .title else "" end) + "]]"' 2>/dev/null || echo ""
}

# Convert wikilink strings to JSON array
link_text_to_array() {
  local links_text="$1"
  local json='['
  local first=1

  while IFS= read -r link; do
    [[ -z "$link" ]] && continue

    if (( first == 0 )); then
      json+=','
    fi
    first=0

    # Parse wikilink
    local parsed
    parsed=$(link_parse "$link")
    json+="$parsed"
  done <<< "$links_text"

  json+=']'
  echo "$json"
}

# Ensure link exists in array
link_ensure() {
  local link_id="$1"
  local link_title="${2:-$link_id}"
  local json_array="$3"

  # Check if link already exists
  local exists
  exists=$(echo "$json_array" | jq --arg id "$link_id" '.[] | select(.id == $id)' 2>/dev/null)

  if [[ -n "$exists" ]]; then
    echo "$json_array"
  else
    # Add new link
    echo "$json_array" | jq --arg id "$link_id" --arg title "$link_title" '. += [{"id": $id, "title": $title}]' 2>/dev/null || echo "[$( jq -n --arg id "$link_id" --arg title "$link_title" '{id: $id, title: $title}')]"
  fi
}

# Export functions
export -f link_create link_parse link_array_to_text link_text_to_array link_ensure
