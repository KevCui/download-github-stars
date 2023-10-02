#!/usr/bin/env bash
#
# Download a Github user's stars information
#
#/ Usage:
#/   ./downloadStarsLite.sh <github_username>
#/
#/ Options:
#/   -h | --help             display this help message

set -e
set -u

usage() {
    printf "%b\n" "$(grep '^#/' "$0" | cut -c4-)" && exit 1
}

set_var() {
    expr "$*" : ".*--help" > /dev/null && usage
    expr "$*" : ".*-h" > /dev/null && usage

    [[ -z "${1:-}" ]] && usage || _USER="$1"
    mkdir -p "$_USER"

    _OUTPUT_HTML="${_USER}/.stars.html"
    _OUTPUT_FILE="${_USER}/${_USER}_$(date +%s).md"
    true > "$_OUTPUT_FILE"

    _URL="https://github.com"
}

set_command() {
    _CURL="$(command -v curl)" || print_error "Command \"curl\" not found!"
    _PUP="$(command -v pup)" || print_error "Command \"pup\" not found!"
}

print_info() {
    # $1: info message
    printf "%b\n" "\033[32m[INFO]\033[0m $1" >&2
}

print_error() {
    # $1: error message
    printf "%b\n" "\033[31m[ERROR]\033[0m $1" >&2
    exit 1
}

remove_space() {
    sed -E '/^[[:space:]]*$/d;s/^[[:space:]]+//;s/[[:space:]]+$//;'
}

download_star_page() {
    # $1: URL
    # $2: output html
    "$_CURL" -sS "$1" -o "$2"
}

write_output() {
    # $1: name
    # $2: language
    # $3: description
    {
        echo "---"
        echo "[$1](${_URL}/${1})"
        echo "Language: $2"
        echo "Description: $3"
    } >> "$_OUTPUT_FILE"
}

get_star_data() {
    # $1: output html
    local len p n l d
    len="$("$_PUP" 'div .d-block' < "$1" \
        | grep -c 'col-12 d-block width-full py-4 border-bottom')"
    len="$((len + 2))"

    for (( i = 2; i < len; i++ )); do
        p="$("$_PUP" "div[class~=\"col-12 d-block\"]:nth-child($i)" --charset UTF-8 -p < "$1")"
        n="$("$_PUP" 'h3 a attr{href}' --charset UTF-8 -p <<< "$p")"
        [[ "${n:0:1}" == "/" ]] && n="${n:1}"
        l="$("$_PUP" 'span[itemprop="programmingLanguage"] text{}' <<< "$p" \
            | remove_space)"
        d="$("$_PUP" 'p[itemprop="description"] text{}' --charset UTF-8 -p <<< "$p" \
            | remove_space \
            | tr '\n' ' ')"
        write_output "$n" "$l" "$d"
    done
}

get_next_page_url() {
    # $1: output html
    "$_PUP" '.BtnGroup'< "$1" \
        | grep 'after=' \
        | sed -E 's/.*href="//' \
        | sed -E 's/">//'
}

main() {
    set_var "$@"
    set_command

    local u="${_URL}/${_USER}?tab=stars"
    while true; do
        [[ -z "${u:-}" ]] && break
        print_info "Downloading ${u}..."
        download_star_page "$u" "$_OUTPUT_HTML"
        get_star_data "$_OUTPUT_HTML"
        u="$(get_next_page_url "$_OUTPUT_HTML")"
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
