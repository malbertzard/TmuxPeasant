#!/usr/bin/env bash

show_help() {
    echo "Usage: $(basename "$0") [--help] [search_pattern]"
    echo
    echo "Options:"
    echo "  --help         Show this help message and exit"
    echo "  search_pattern Fuzzy search pattern to filter results"
    echo
    echo "Tipp:"
    echo "  ending the search_pattern with \$ signals grep that the pattern should end here"
}

while getopts ":h-:" opt; do
    case $opt in
        -)
            case "${OPTARG}" in
                help)
                    show_help
                    exit 0
                    ;;
                *)
                    show_help >&2
                    exit 1
                    ;;
            esac
            ;;
        h)
            show_help
            exit 0
            ;;
        *)
            show_help >&2
            exit 1
            ;;
    esac
done

shift $((OPTIND-1))

if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is not installed. Please install tmux before running this script."
    exit 1
fi

# Create completet list

complete_list=$(find ~/GitHub/ ~/personal/ -type d -name .git -exec dirname {} \; 2>/dev/null | grep -F -v -e "vendor var node_module")

last_input=""

echo "$complete_list"

while true; do
    echo
    echo -n "Enter a fuzzy search pattern: "
    read -e -r -i "$last_input" fuzzy_pattern

    filtered_list=$(echo "$complete_list" | grep --line-buffered -i "$fuzzy_pattern")

    if [ -z "$filtered_list" ]; then
        echo
        echo "No matching results found."
        continue
    fi

    if [ $(echo "$filtered_list" | wc -l) -eq 1 ]; then
        echo
        echo "Selected result: $filtered_list"
        selected=$filtered_list
        break
    fi

    echo
    echo "Matching results:"
    echo "$filtered_list"

    # Save the current input as the last input for the next iteration
    last_input="$fuzzy_pattern"
done

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s $selected_name -c $selected "~/nvim.appimage ."
    exit 0
fi

if ! tmux has-session -t=$selected_name 2> /dev/null; then
    tmux new-session -ds $selected_name -c $selected "~/nvim.appimage ."
fi

tmux switch-client -t $selected_name
