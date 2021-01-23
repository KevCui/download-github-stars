#!/usr/bin/env bash
#
# Download a Github user's stars information
#
#/ Usage:
#/   ./downloadStars.sh -u <github_username> [-f md|json] [-p <num>]
#/
#/ Options:
#/   -u <username>           github username
#/   -f md|json              output format: md, json
#/                           default format: json
#/   -p <num>                start from page num
#/   -h | --help             display this help message

set -e
set -u

usage() {
    printf "%b\n" "$(grep '^#/' "$0" | cut -c4-)" && exit 1
}

set_var() {
    # Set global variables
    [[ -z "${_USER:-}" ]] && echo "[ERROR] Missing -u <username>" && usage
    _OUTPUT_DIR="./stars"
    _API="https://api.github.com"
    _TMP_FILE="./.tmp"
    true > "$_TMP_FILE"
    if [[ "$_FORMAT" == "json" ]]; then
        _OUTPUT_FILE="$_OUTPUT_DIR/$_USER.json"
    else
        _OUTPUT_FILE="$_OUTPUT_DIR/$_USER.md"
    fi

    _CURL="$(command -v curl)"
    _JQ="$(command -v jq)" || (echo "[ERRORl] 'jq' command not found!" && exit 1)

    mkdir -p "$_OUTPUT_DIR"
}

set_args() {
    expr "$*" : ".*--help" > /dev/null && usage
    _FORMAT="json"
    while getopts ":hu:p:f:" opt; do
        case $opt in
            u)
                _USER="$OPTARG"
                ;;
            p)
                _PAGE="$OPTARG"
                ;;
            f)
                _FORMAT="$OPTARG"
                ;;
            h)
                usage
                ;;
            \?)
                print_error "Invalid option: -$OPTARG"
                ;;
        esac
    done
}

get_page_max_num() {
    # Return max. page number
    "$_CURL" -sSI "${_API}/users/$_USER/starred" | grep -v "WARNING" | grep "ink:" | sed -E 's/.*page=//;s/>;.*//'
}

get_user_id() {
    # Return user id
    "$_CURL" -sSI "${_API}/users/$_USER/starred" | grep -v "WARNING" | grep "ink:" | sed -E 's/.*\/user\///;s/\/.*//'
}

print_rate_limit() {
    echo "[ERROR] Download failed! It may reach the max. request limit. Try it later." >&2
    exit 1
}

save_tmp() {
    local t
    t="$(date +%s)"
    if [[ "${_FORMAT:-}" == "json" ]]; then
        local out
        out="$(cat $_TMP_FILE)"
        echo "[${out::-1}]" | "$_JQ" . > "${_OUTPUT_FILE}.${t}.part"
        rm -f "$_TMP_FILE"
    else
        sed -E '/^\s*$/d' "$_TMP_FILE" > "$_OUTPUT_FILE.${t}.part"
    fi
}

download_page() {
    # Download stars on page $2 of user $1, return it
    # $1: user id
    # $2: page number
    local o
    echo "Downloading page $2..." >&2
    o=$("$_CURL" -sS "${_API}/user/$1/starred?page=$2" | grep -v "WARNING")

    [[ "$o" == *"API rate limit exceeded for"* ]] && save_tmp && print_rate_limit

    if [[ "${_FORMAT:-}" == "json" ]]; then
        "$_JQ" -r '.[] | "\(.),"' <<< "$o" | tee -a "$_TMP_FILE"
    else
        "$_JQ" -r '.[] | "\n---\n[" + .full_name + "](" + .html_url + ")\nLanguage: " + .language + "\nDescription: " + .description' <<< "$o" | tee -a "$_TMP_FILE"
    fi
}

main() {
    set_args "$@"
    set_var

    local num id output="" page=1

    num=$(get_page_max_num)
    [[ -z "${num:-}" ]] \
        && echo "[ERROR] Cannot fetch total page number. Check your network and request rate limit." \
        && exit 1

    id=$(get_user_id)
    [[ -z "${id:-}" ]] \
        && echo "[ERROR] Cannot fetch user id. Check your network and request rate limit." \
        && exit 1

    [[ -n "${_PAGE:-}" ]] && page="$_PAGE"
    [[ "$page" -gt "$num" ]] \
        && echo "[ERROR] Page num exceeds max. num ${num:-}" \
        && exit 1

    for (( i = page; i <= num; i++ )); do
        output="$output$(download_page "$id" "$i")"
    done

    if [[ -n "$output" ]]; then
        if [[ "${_FORMAT:-}" == "json" ]]; then
            echo "[${output::-1}]" | "$_JQ" . > "$_OUTPUT_FILE"
        else
            echo "$output" | sed -E '/^\s*$/d' > "$_OUTPUT_FILE"
        fi
    else
        print_rate_limit
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
