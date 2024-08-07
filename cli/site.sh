#!/usr/bin/env bash
set -euo pipefail

CMD_PATTERN="${TEXT_BOLD}wld site example.local -- wp ...${TEXT_STYLE_RESET}"

# Main function
main() {
    local domain_name="$1"
    local site_exists="$(site_exists $domain_name)"
    if [[ $site_exists -eq 0 ]]; then
        echo "\"${domain_name}\" not found! Run: 'wld scaffold'"
        return
    fi
    if [[ "$2" != "--" ]]; then
        printf "ERROR: 2nd argument must be '--' e.g. 'wld site example.local ${TEXT_BOLD}--${TEXT_STYLE_RESET} wp'\n"
        return
    fi
    if [[ "$3" != "wp" ]]; then
        printf "ERROR: 3rd argumnet must be 'wp' e.g. 'wld site example.local -- ${TEXT_BOLD}wp${TEXT_STYLE_RESET}'\n"
        return
    fi
    shift
    shift
    shift

    docker compose exec php wp "$@" --path="/var/www/html/${domain_name}" --allow-root
}

# Execute main function
main "$@"

exit 0
