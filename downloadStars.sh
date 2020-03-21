#!/usr/bin/env bash
#
# Download a Github user's stars information to local md file
#
#/ Usage:
#/   ./downloadStars.sh <github_username> [<output_path>]

set -e
set -u

usage() { grep '^#/' "$0" | cut -c4- ; exit 0 ; }
expr "$*" : ".*--help" > /dev/null && usage

set_var() {
    # Set global variables
    if [[ -z "${1:-}" ]]; then
        echo "Mising username input!"
        usage
    fi

    if [[ -z "${2:-}" ]]; then
        _OUTPUT_DIR="./stars"
    else
        _OUTPUT_DIR="$2"
    fi

    _USER="$1"
    _API="https://api.github.com/"
    _OUTPUT_FILE="$_OUTPUT_DIR/$_USER.md"

    _HTTP=$(command -v http)
    if [ ! "$_HTTP" ]; then
        echo "'http' command doesn't exist! Please install httpie."
        exit 1
    fi

    _JQ=$(command -v jq)
    if [ ! "$_JQ" ]; then
        echo "'jq' command doesn't exist! Please install jq."
        exit 1
    fi

    mkdir -p "$_OUTPUT_DIR"
}

get_page_max_num() {
    # Return max. page number
    $_HTTP -p h "${_API}users/$_USER/starred" | grep -v "WARNING" | grep "Link:" | sed -E 's/.*page=//;s/>;.*//'
}

get_user_id() {
    # Return user id
    $_HTTP -p h "${_API}users/$_USER/starred" | grep -v "WARNING" | grep "Link:" | sed -E 's/.*\/user\///;s/\/.*//'
}

download_page() {
    # Download stars on page $2 of user $1, return it
    # $1: user id
    # $2: page number
    echo "Downloading $2..." >&2
    $_HTTP "${_API}user/$1/starred?page=$2" -p b | grep -v "WARNING" | $_JQ -r '.[] | "---\n[" + .full_name + "](" + .html_url + ")\nLanguage: " + .language + "\nDescription: " + .description'
}

main() {
    local num id output
    set_var "${1:-}"
    num=$(get_page_max_num)
    id=$(get_user_id)
    output=""

    for (( i = 1; i <= num; i++ )); do
        output="$output$(download_page "$id" "$i")"
    done

    echo "$output" > "$_OUTPUT_FILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
