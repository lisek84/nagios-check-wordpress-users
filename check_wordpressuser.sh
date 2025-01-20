#!/bin/bash
# This script will iterate through your directory with websites and if wordpress will be detected it will store it's users list and compare it in every run. If new user will be added, alarm will be triggered.

# Path to the directory containing WordPress installations
BASE_DIR="/var/www"

# Allow root flag for wp-cli commands
ALLOW_ROOT="--allow-root"

# Nagios status codes
NAGIOS_OK=0
NAGIOS_WARNING=1
NAGIOS_CRITICAL=2
NAGIOS_UNKNOWN=3

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Check for new WordPress users and notify in Nagios style."
    echo
    echo "Options:"
    echo "  --help           Display this help message."
    echo "  --validate       Validate new users and update the stored user list."
}

# Function to check if wp-cli is installed
check_wp_cli() {
    if ! command -v wp &> /dev/null; then
        echo "wp-cli is not installed. Exiting."
        exit $NAGIOS_UNKNOWN
    fi
}

# Function to secure a file
secure_file() {
    local file=$1
    if [ -f "$file" ]; then
        chown root:root "$file"
        chmod 600 "$file"
    fi
}

# Function to validate and update the user list
validate_users() {
    local dir=$1
    local user_file="$dir/user_list.json"
    local temp_file="$dir/user_list_new.json"

    if [ -f "$temp_file" ]; then
        mv "$temp_file" "$user_file"
        secure_file "$user_file"
        echo "OK: User list in $dir has been validated and updated."
        exit $NAGIOS_OK
    else
        echo "WARNING: No pending user list changes found in $dir."
        exit $NAGIOS_WARNING
    fi
}

# Function to check if a directory contains WordPress
is_wordpress_installed() {
    local dir=$1
    wp core is-installed $ALLOW_ROOT --path="$dir" &> /dev/null
    return $?
}

# Function to compare user lists and detect new users
check_new_users() {
    local dir=$1
    local user_file="$dir/user_list.json"
    local temp_file="$dir/user_list_new.json"
    local current_users
    local stored_users

    # Retrieve current user list
    current_users=$(wp user list --format=json $ALLOW_ROOT --path="$dir" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "CRITICAL: Failed to retrieve user list for $dir"
        exit $NAGIOS_CRITICAL
    fi

    # Check if stored user list exists
    if [ -f "$user_file" ]; then
        secure_file "$user_file"

        # Read stored user list
        stored_users=$(cat "$user_file")

        # Compare current and stored user lists
        if [ "$current_users" != "$stored_users" ]; then
            echo "$current_users" > "$temp_file"
            secure_file "$temp_file"

            # Extract new users and format output
            local new_users
            new_users=$(jq -n --argjson current "$current_users" --argjson stored "$stored_users" '
                $current - $stored | map(.user_login) | join(", ")
            ')

            if [ -n "$new_users" ] && [ "$new_users" != "[]" ]; then
                echo "CRITICAL: New users detected in $dir: $new_users"
                exit $NAGIOS_CRITICAL
            fi
        fi
    else
        # Store the current user list for the first time
        echo "$current_users" > "$user_file"
        secure_file "$user_file"
    fi
}

# Main logic
main() {
    local validate=false

    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                exit 0
                ;;
            --validate)
                validate=true
                shift
                ;;
            *)
                echo "Unknown option $1"
                show_help
                exit $NAGIOS_UNKNOWN
                ;;
        esac
    done

    # Check if wp-cli is installed
    check_wp_cli

    # Iterate through WordPress directories
    for dir in "$BASE_DIR"/*; do
        if [ -d "$dir" ]; then
            if is_wordpress_installed "$dir"; then
                if [ "$validate" = true ]; then
                    validate_users "$dir"
                else
                    check_new_users "$dir"
                fi
            fi
        fi
    done

    # If no issues are found
    echo "OK: No new users detected in any WordPress installation."
    exit $NAGIOS_OK
}

# Run the main function
main "$@"
