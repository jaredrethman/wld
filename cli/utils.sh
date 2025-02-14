#!/usr/bin/env bash

# Variables
## Docker
DOCKER_COMPOSE_CMD="${DOCKER_COMPOSE_CMD:-docker compose}"
## Directories
CLI_DIR="${WLD_DIR}/cli"
SITES_DIR="${WLD_DIR}/sites"
CONFIG_DIR="${WLD_DIR}/config"
CERTS_CONFIG_DIR="${WLD_DIR}/config/certs"
NGINX_CONFIG_DIR="${WLD_DIR}/config/nginx"
## Text
TEXT_BOLD="\e[1m"
### Colors
TEXT_COLOR_GRAY="\e[30m"
TEXT_COLOR_RED="\e[31m"
TEXT_COLOR_RED_BOLD="\e[31;1m"
TEXT_COLOR_GREEN="\e[32m"
TEXT_COLOR_YELLOW="\e[33m"
TEXT_COLOR_BLUE="\e[34m"
TEXT_COLOR_BLUE_BOLD="\e[34;1m"
TEXT_STYLE_RESET="\e[0m"

## Nginx
NGINX_TEMPLATE_FILE="./config/nginx/nginx-site.conf.template"

CLEAR_PREV_LINE="\033[1A\033[K"

SITES=$(find "$SITES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs)

site_exists() {
  if [[ " ${SITES[@]} " =~ " $1 " ]]; then
    echo 1
    return
  fi
  echo 0
}

are_all_services_running() {
  local services_status=$(docker compose ps --services --filter "status=running")
  local all_services=$(docker compose config --services)

  for service in $all_services; do
    if ! echo "$services_status" | grep -q "$service"; then
      return 1
    fi
  done
  return 0
}

get_wp_latest_version() {
  wp_latest_version=$(curl -s https://api.wordpress.org/core/version-check/1.7/ | grep -o '"version":"[^"]*' | head -1 | awk -F '"' '{print $4}')
  echo $wp_latest_version
}

# Functions

reset_loading_animation() {
  local pid="$1"
  local reset_txt="${2:-''}"
  kill $pid
  wait $pid 2>/dev/null
  printf "${CLEAR_PREV_LINE}"
  printf "\r\033[K${reset_txt}\n"
}

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
      export $(grep -v '^#' "${WLD_DIR}/.env" | xargs)
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
      unset $(grep -v '^#' "${WLD_DIR}/.env" | sed -E 's/(.*)=.*/\1/' | xargs)
      unset DOMAIN_NAME
    fi
  done
}

# Prompt domain
prompt_domain_name() {
  local input
  while true; do
    printf "Domain name (e.g. \"example.local\"): " >&2
    read input

    # Input empty?
    if [[ -z "$input" ]]; then
      continue
    fi

    # Domain already exist?
    if [[ " ${SITES[@]} " =~ " $input " ]]; then
      printf "The domain '$input' already exists. Please enter a different domain.\n" >&2
      continue
    fi

    # Check for spaces in the input
    if [[ "$input" =~ [[:space:]] ]]; then
      printf "Spaces are not allowed. Please enter a valid domain.\n" >&2
      continue
    fi

    # Does the input resemble a domain?
    if [[ ! "$input" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]]; then
      printf "Please enter a valid domain e.g. 'example.local'\n" >&2
      continue
    fi

    break
  done

  echo $input
}

# Prompt inline input
prompt_inline_input() {
  local input
  local prompt="$1"
  local default_value="${2-0}"
  while true; do
    printf "${prompt}: " >&2
    read input

    # Input empty?
    if [[ -z "$input" ]]; then
      if [[ -n "$default_value" && "$default_value" != '0' ]]; then
        printf "${CLEAR_PREV_LINE}""${prompt}: ${default_value}\n" >&2
        input="$default_value"
        break
      fi
      continue
    fi

    break
  done

  echo $input
}

# Prompt y/n
prompt_inline_yn() {
  local prompt_message="$1"
  local default_value="${2-n}"
  local response

  read -p "$prompt_message [y/N]: " response

  response=${response:-$default_value}

  response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

  if [[ "$response" == "y" ]]; then
    echo "y"
  else
    echo "n"
  fi
}
