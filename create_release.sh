#!/usr/bin/env bash

set -e

setup_echo_colours() {
  # Exit the script on any error
  set -e

  # shellcheck disable=SC2034
  if [ "${MONOCHROME}" = true ]; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BLUE2=''
    DGREY=''
    NC='' # No Colour
  else 
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    BLUE2='\033[1;34m'
    DGREY='\e[90m'
    NC='\033[0m' # No Colour
  fi
}

debug_value() {
  local name="$1"; shift
  local value="$1"; shift
  
  if [ "${IS_DEBUG}" = true ]; then
    echo -e "${DGREY}DEBUG ${name}: ${value}${NC}"
  fi
}

debug() {
  local str="$1"; shift
  
  if [ "${IS_DEBUG}" = true ]; then
    echo -e "${DGREY}DEBUG ${str}${NC}"
  fi
}

main() {
  IS_DEBUG=false

  setup_echo_colours

  local pack_name="${1?pack_name argument must be supplied, e.g. "stroom-101"}"; shift
  local version="${1?version argument must be supplied, e.g. "v2.0"}"; shift
  local notes="${1?notes argument must be supplied, e.g. "Adds feature X"}"; shift

  if ! command -v "gh" 1>/dev/null; then
    echo "GitHub CLI 'gh' is not installed. Install it." >&2
    exit 1
  fi

  local tag="${pack_name}-${version}"
  echo -e "${GREEN}Creating release for pack ${BLUE}${pack_name}${GREEN}" \
    "with tag ${BLUE}${tag}${NC}"
  
  gh release create \
    "${tag}" \
    --title "${tag}" \
    --notes "${notes}"
  
  echo -e "${GREEN}Done${NC}"
}

main "$@"
