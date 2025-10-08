#!/usr/bin/env bash
set -e

# Set up a trap to catch SIGINT (Ctrl+C) and execute the cleanup function
trap cleanup SIGINT

cleanup() {
  if [[ -n "${TEMP_DIR}" ]] && [[ -d "${TEMP_DIR}" ]]; then
    rm -rf "${TEMP_DIR:?TEMP_DIR not set}"
  fi
}

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

validate_for_uncommitted_work() {
  debug "validate_for_uncommitted_work() called"
  if [ "$(git status --porcelain 2>/dev/null | wc -l)" -ne 0 ]; then
    
    echo -e "There are uncommitted changes or untracked files." \
      "\nCommit them before running this script."
    exit 1
  fi
}

main() {
  IS_DEBUG=false
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
  TEMP_DIR=

  setup_echo_colours

  local pack_name="${1?pack_name argument must be supplied, e.g. "stroom-101"}"; shift
  local version="${1?version argument must be supplied, e.g. "v2.0"}"; shift
  local notes="${1?notes argument must be supplied, e.g. "Adds feature X"}"; shift
  local tag="${pack_name}-${version}"
  local dist_sub_dir="build/distributions"
  local zip_filename="${pack_name}.zip"
  local zip_all_filename="${pack_name}-all.zip"
  local source_zip_file="${dist_sub_dir}/${zip_filename}"
  local source_zip_all_file="${dist_sub_dir}/${zip_all_filename}"

  validate_for_uncommitted_work

  if ! command -v "gh" 1>/dev/null; then
    echo "GitHub CLI 'gh' is not installed. Install it." >&2
    exit 1
  fi

  pushd "${SCRIPT_DIR}" >/dev/null

  ./gradlew clean build

  if [[ ! -f "${source_zip_file}" ]]; then
    echo "Can't find content pack zip ${source_zip_file}" >&2
    exit 1
  fi

  if [[ ! -f "${source_zip_all_file}" ]]; then
    echo "Can't find content pack zip ${source_zip_all_file}" >&2
    exit 1
  fi
  TEMP_DIR=$( mktemp -d )

  local temp_zip_file="${TEMP_DIR}/${pack_name}-${version}.zip"
  cp "${source_zip_file}" "${temp_zip_file}"

  local extra_args=()
  extra_args+=( "${temp_zip_file}" )

  # No point including the -all file if it is the same
  if cmp -s "${source_zip_file}" "${source_zip_all_file}"; then
    echo -e "${GREEN}Skipping identical asset ${BLUE}${zip_all_filename}${NC}"
  else
    local temp_zip_all_file="${TEMP_DIR}/${pack_name}-all-${version}.zip"
    cp "${source_zip_all_file}" "${temp_zip_all_file}"
    extra_args+=( "${temp_zip_all_file}" )
  fi

  echo -e "${GREEN}Creating release for pack ${BLUE}${pack_name}${GREEN}" \
    "with tag ${BLUE}${tag}${GREEN} and assets:${NC}"

  for file in "${extra_args[@]}"; do
    # Stip the path bit off to leave just filename
    echo -e "  ${BLUE}${file##*/}${NC}"
  done

  echo
  read -rsp $'Press "y" to continue, any other key to cancel.\n' -n1 keyPressed

  if [ "$keyPressed" != 'y' ] && [ "$keyPressed" != 'Y' ]; then
    echo
    echo -e "${GREEN}Exiting without creating a release.${NC}"
    echo
    cleanup
    exit 0
  fi
  
  gh release create \
    "${tag}" \
    --title "${tag}" \
    --notes "${notes}" \
    "${extra_args[@]}"
  
  popd >/dev/null
  cleanup
  echo -e "${GREEN}Done${NC}"
}

main "$@"

