# Variables

## Directories
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_PATH=$(dirname "${SCRIPT_PATH}")
CLI_DIR="${ROOT_PATH}/cli"
SITES_DIR="${ROOT_PATH}/sites"
CONFIG_DIR="${ROOT_PATH}/config"
## Text colors
TEXT_RED="\033[31m"
TEXT_GREEN="\033[32m"
TEXT_YELLOW="\033[33m"
TEXT_COLOR_RESET="\033[0;39m"

CLEAR_PREV_LINE="\033[1A\033[K"

SITES=($(find "$SITES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))

# Functions

reset_loading_animation() {
  local pid="$1"
  local reset_txt="${2:-Done}"
  kill $pid
  wait $pid 2>/dev/null
  printf "${CLEAR_PREV_LINE}"
  printf "\r\033[K${reset_txt}\n"
}

# loading_animation &
# LOADING_PID=$!

# # # Simulate some work with sleep
# sleep 5  # Replace this with your actual work

# reset_animation $LOADING_PID "Loading complete"

loading_animation() {
  local loading_txt="${1:-Loading}"
  while true; do
    printf "${CLEAR_PREV_LINE}"
    printf "%s\n" "- ${loading_txt}."
    sleep 0.1
    printf "${CLEAR_PREV_LINE}"
    printf "%s\n" "\\ ${loading_txt}.."
    sleep 0.1
    printf "${CLEAR_PREV_LINE}"
    printf "%s\n" "| ${loading_txt}..."
    sleep 0.1
    printf "${CLEAR_PREV_LINE}"
    printf "%s\n" "/ ${loading_txt}.."
    sleep 0.1
  done
}

each_site_env() {
  local callback="$1"
  shift
  for SITE_DIR in "${SITES_DIR}"/*; do
    if [ -d "${SITE_DIR}" ]; then
      # Set default .env vars as base for environment variables
      export $(grep -v '^#' "${ROOT_PATH}/.env" | xargs)
      export DOMAIN_NAME=$(basename "${SITE_DIR}")
      env_file="${SITES_DIR}/${DOMAIN_NAME}/.env"
      if [ -f "${env_file}" ]; then
        # Export site .env
        export $(grep -v '^#' "${env_file}" | xargs)

        "$callback" "$@"

        # Unset site .env
        unset $(grep -v '^#' "${env_file}" | sed -E 's/(.*)=.*/\1/' | xargs)
      else
        echo "No .env file found for ${env_file}."
      fi
      unset $(grep -v '^#' "${ROOT_PATH}/.env" | sed -E 's/(.*)=.*/\1/' | xargs)
      unset DOMAIN_NAME
    fi
  done
}

# Function to prompt for a local domain
prompt_domain_name() {
  local input
  while true; do
    echo "Please enter a local domain:" >&2
    read input

    # Check if the input is in the SITES array
    if [[ " ${SITES[@]} " =~ " $input " ]]; then
      echo "The domain '$input' already exists. Please enter a different domain." >&2
    else
      break
    fi
  done

  # Return the valid domain
  echo $input
}
