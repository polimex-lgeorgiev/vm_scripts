#!/bin/bash

# Function to display help
function display_help() {
    echo "Usage: $0 [repository_url] [branch_name]"
    echo
    echo "repository_url: URL of the Git repository to clone."
    echo "branch_name: Name of the branch to clone."
    echo
    echo "Example:"
    echo "$0 https://github.com/OCA/hr-holidays.git 15.0"
}

# If help is requested or two parameters are provided, script behaves as before
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    display_help
    exit 0
elif [[ $# -eq 2 ]]; then
    git clone $1 --depth 1 --branch $2 --single-branch --no-tags
    exit 0
fi

# Predefined arrays for branches and repositories
declare -a branches=("14.0" "15.0" "16.0")
declare -a repos=(
    "https://github.com/polimex/polimex-rfid.git"
    "https://github.com/OCA/OCB.git"
    "https://github.com/OCA/web.git"
    "https://github.com/OCA/hr.git"
    "https://github.com/OCA/hr-attendance.git"
    "https://github.com/OCA/hr-holidays.git"
    "https://github.com/OCA/server-brand.git"
    "https://github.com/OCA/server-tools.git"
    "https://github.com/OCA/server-ux.git"
    "https://github.com/OCA/social.git"
    "https://github.com/OCA/data-protection.git"
    "https://github.com/OCA/multi-company.git"
    "https://github.com/OCA/calendar.git"
)

# Menu for selecting a branch
echo "Please select a branch:"
select branch in "${branches[@]}"; do
    if [[ -n $branch ]]; then
        echo "You selected branch $branch"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# Menu for selecting one or more repositories
echo "Please select one or more repositories (enter the numbers separated by space):"
select repo in "${repos[@]}"; do
    if [[ -n $repo ]]; then
        selected_repos=("$repo")
        while true; do
            echo "You selected repositories: ${selected_repos[*]}."
            echo "Select another repository or type 'c' to continue with these selections."
            select repo in "${repos[@]}"; do
                if [[ -n $repo ]]; then
                    selected_repos+=("$repo")
                    break
                elif [[ $REPLY == "c" ]]; then
                    break 2
                else
                    echo "Invalid selection. Please try again."
                fi
            done
        done
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# Cloning selected repositories with selected branch
for repo in "${selected_repos[@]}"; do
    echo "Cloning repository $repo with branch $branch"
    git clone $repo --depth 1 --branch $branch --single-branch --no-tags
done
