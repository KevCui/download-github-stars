#!/usr/bin/env bash
#
# Download a Github user's stars information
#
#/ Usage:
#/   ./downloadStars.sh <github_username> [--md]

set -e
set -u

usage() { grep '^#/' "$0" | cut -c4- ; exit 0 ; }
expr "$*" : ".*--help" > /dev/null && usage
expr "$*" : ".*--md" > /dev/null && _OUTPUT_MD=true

set_var() {
    # Set global variables
    [[ -z "${1:-}" ]] && echo "[ERROR] Mising username input!" && usage

    _USER="$1"
    _OUTPUT_DIR="./stars"
    _API="https://api.github.com"
    if [[ -z "${_OUTPUT_MD:-}" ]]; then
        _OUTPUT_FILE="$_OUTPUT_DIR/$_USER.json"
    else
        _OUTPUT_FILE="$_OUTPUT_DIR/$_USER.md"
    fi

    _CURL="$(command -v curl)"
    _JQ="$(command -v jq)" || (echo "[ERRORl] 'jq' command not found!" && exit 1)

    mkdir -p "$_OUTPUT_DIR"
}

get_page_max_num() {
    # Return max. page number
    "$_CURL" -sSI "${_API}/users/$_USER/starred" | grep -v "WARNING" | grep "ink:" | sed -E 's/.*page=//;s/>;.*//'
}

get_user_id() {
    # Return user id
    "$_CURL" -sSI "${_API}/users/$_USER/starred" | grep -v "WARNING" | grep "ink:" | sed -E 's/.*\/user\///;s/\/.*//'
}

download_page() {
    # Download stars on page $2 of user $1, return it
    # $1: user id
    # $2: page number
    local o
    echo "Downloading $2..." >&2
    o=$("$_CURL" -sS "${_API}/user/$1/starred?page=$2" | grep -v "WARNING")

    if [[ -z "${_OUTPUT_MD:-}" ]]; then
        "$_JQ" -r '.[] | "\(.),"' <<< "$o"
    else
        "$_JQ" -r '.[] | "---\n[" + .full_name + "](" + .html_url + ")\nLanguage: " + .language + "\nDescription: " + .description' <<< "$o"
    fi
}

main() {
    local num id output=""
    set_var "${1:-}"
    num=$(get_page_max_num)
    id=$(get_user_id)

    for (( i = 1; i <= num; i++ )); do
        output="$output$(download_page "$id" "$i")"
    done

    if [[ -n "$output" ]]; then
        if [[ -z "${_OUTPUT_MD:-}" ]]; then
            echo "[${output::-1}]" | "$_JQ" . > "$_OUTPUT_FILE"
        else
            echo "$output" > "$_OUTPUT_FILE"
        fi
    else
        echo "[ERROR] Download failed! It may reach the max. request limit. Try it later."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
