#!/bin/bash

#
# Beam-it: Bulk clone GitHub Repositories
# This bash script will bulk clone GitHub repositories for a specific user/organisation or team
#
# The script will automatically configure itself by asking the user to enter some required information
# in order to be able to communicate with the GitHub API
# When running the script for the first time, the user will be prompted to enter his GitHub username and API personal access token
# For more information on API personal access tokens: https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/
#
# Note: After first setup, you might need to source your .bash_profile, .bashrc or .zshrc in order for the variables export to take effect and not to be prompted again
#
# Usage: git beam-it <options>
#
# Options:
# -h             help            show help
# -i             interactive     interactive clone mode. The user will be prompted before cloning each repo
# -d             directory       specify a directory to clone all the repositories into
# -p             public          clone only public repositories (note that this does not work for teams)
# -v             private         clone only private repositories (note that this does not work for teams)
# -r             regex           filter repositories based on this regex
# -s             ssh             clone GitHub repos over ssh and not https (this will use the SSH keys if uploaded to GitHub and will prevent the password prompt)
# -t <teamId>    team            clone only repositories belonging to this specific team id
# -o <orgName>   organisation    clone only repositories belonging to this specific organisation name
#
# If the parameteres -t and -o have been left empty, then the script will fetch the list of organisations and teams for that specific user
# The user will then be prompted to enter the organisation name or team id or just skip to fetch all repositories
#
# Examples:
#
# Clone interactively all the private repositories for the user
# git beam-it -v -i
#
# Clone interactively all the public repos that match the regex .*SeedJobs.* (any repo that contain SeedJobs)
# git beam-it -i -r .*SeedJobs.*
#
# Clone all the public repositories for organisation SeedJobs
# git beam-it -p -o SeedJobs
#

# Colors and visual Configurations
MAGENTA='\033[35m'
RED='\033[31m'
YELLOW='\033[33m'
NC='\033[0m'

die () {
    echo "ERROR: $*. Aborting." >&2
    exit 1
}

# Check if gawk is installed which is not by default in mac systems
if ! type gawk &> /dev/null ; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        printf "The required package ${YELLOW}gawk${NC} was not found .. installing now\n"
        brew install gawk
    fi
fi

check_jq() {
    if ! type jq &> /dev/null ; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew 2>/dev/null && /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi
        printf "The required package ${YELLOW}jq${NC} was not found .. installing now\n"
        [[ "$OSTYPE" == "linux-gnu" ]] && sudo apt-get install jq || brew install jq
    fi
}

# Set the global environment variables
set_environment_variable() {

    # Setting $BASH to maintain backwards compatibility
    # Getting the user's OS type in order to load the correct installation and configuration scripts
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        printf "\nexport ${1}=${2}" >> "${HOME}/.bashrc"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        printf "\nexport ${1}=${2}" >> "${HOME}/.bash_profile"
    fi

    # Check if we have a .zshrc regardless of the os .. and copy that to the zsh source file
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "export ${1}=${2}" "${HOME}/.zshrc" ; then
          printf "Noticed that you have Zsh installed .. adding ${1} variable in there ..\n"
          printf "\nexport ${1}=${2}" >> "${HOME}/.zshrc"
        fi
    fi
}

# Set the BEAMERY_HOME global environment variable
if [ -z "$GITHUB_USERNAME" ];
then
    printf "We noticed you do not have your ${RED}Github username${NC} variable set ...\n"
    # Prompt user to select the location for beamery folder
    read -p "Can you please enter your Github username ? " -e GITHUB_USERNAME
    set_environment_variable GITHUB_USERNAME $GITHUB_USERNAME
fi

# Set the BEAMERY_HOME global environment variable
if [ -z "$GITRIEVAL_TOKEN" ];
then
    printf "We noticed you do not have the ${RED}Github Personal Token${NC} variable set ...\nFor more information: ${MAGENTA}https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/${NC}\n"
    # Prompt user to select the location for beamery folder
    read -p "Can you please enter your Github personal token so that we can access the Github API ? " -e GITRIEVAL_TOKEN
    set_environment_variable GITRIEVAL_TOKEN $GITRIEVAL_TOKEN
fi


get_teams() {
    check_jq
    printf "We have noticed that you have specified the team ${YELLOW}-t${NC} flag, but have not defined a team\nHere are a list of your teams and their ids in case you did not know them:\n${MAGENTA}"
    curl --silent https://api.github.com/user/teams?access_token=$GITRIEVAL_TOKEN  | jq '.[] | .id, "name:" + .name, "organisation:" + .organization.login' | sed 'N;N;s/\n/ /g'  | sed 's/\"//g'
    printf "${YELLOW}Note: you need to provide the team id and not the team name${NC}\n"
    printf "${NC}Press ${YELLOW}[ENTER]${NC} to skip the team flag and fetch all repositories for the user\n"
    read -p "Which team id you wish to fetch repositories for: ? " -e TEAM
}

get_organisations() {
    check_jq
    printf "We have noticed that you have specified the organisation ${YELLOW}-o${NC} flag, but have not defined an organisation\nHere are a list of your organisations in case you did not know them:\n${MAGENTA}"
    curl --silent https://api.github.com/user/orgs?access_token=$GITRIEVAL_TOKEN  | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | gawk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w login | cut -d "|" -f2
    printf "${NC}Press ${YELLOW}[ENTER]${NC} to skip the organisation flag and fetch all repositories for the user\n"
    read -p "Which organisation you wish to fetch repositories for: ? " -e ORGANISATION
}

# Initialize our own variables:
OPTIND=1; ORGANISATION=false; TEAM=false; REGEX=false; IS_INTERACTIVE=false; TYPE='all'; DIRECTORY="."; IS_SSH=false;
# Parse the options and arguments passed to the function
while getopts ":d:o:t:r:p:ihs" opt; do
    case "$opt" in
    h)  grep '#' "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")" | cut -c 2- | head -n +37 | tail -n +2 && exit 0
        ;;
    d)  if [[ ${OPTARG:0:1} == '-' ]]; then
            die "Invalid value $OPTARG given to -$OPTION"
        fi
        DIRECTORY=$OPTARG
        ;;
    p)  if [[ ${OPTARG:0:1} == '-' ]]; then
            die "Invalid value $OPTARG given to -$OPTION"
        fi
        TYPE=$OPTARG
        ;;
    o)  if [[ ${OPTARG:0:1} == '-' ]]; then
            die "Invalid value $OPTARG given to -$OPTION"
        fi
        ORGANISATION=$OPTARG
        ;;
    t)  if [[ ${OPTARG:0:1} == '-' ]]; then
            die "Invalid value $OPTARG given to -$OPTION"
        fi
        TEAM=$OPTARG
        ;;
    r)  if [[ ${OPTARG:0:1} == '-' ]]; then
            die "Invalid value $OPTARG given to -$OPTION"
        fi
        REGEX=$OPTARG
        ;;
    i)  IS_INTERACTIVE=true
        ;;
    s)  IS_SSH=true
        ;;
    \?) die "Invalid option passed" ;;
    :)  if [ $OPTARG == "t" ]; then
            get_teams
        elif [ $OPTARG == "o" ]; then
            get_organisations
        else
            echo "$0: -$OPTARG needs a value" >&2; exit 2
        fi
        ;;

    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

# Given a list of repos URLs .. clone or pull and update the list
get_repos() {
    echo "Beaming down all the repositories now ..."
    for repository in $@
    do
        echo $repository|sed -e 's/\\n//g'
        FILENAME=${repository##*/}
        REPOSITORY_NAME=${FILENAME%.*}
        if [[ $IS_SSH == true ]]; then
            REPOSITOY_URL="git+ssh://git@github.com:$(echo $repository | awk -F 'github.com' '{print $2}' |sed -e 's/\\n//g')"
        else
            REPOSITOY_URL="http://$(echo $repository |sed -e 's/\\n//g')"
        fi

        # Check if the URI matches a pattern if defined
        if [[ $REGEX != false ]]; then
            ! [[ $repository =~ $REGEX ]] && printf "\nSkipping ${RED}$REPOSITORY_NAME${NC} as it does not match the regex filter" && continue
        fi
        if [[ $IS_INTERACTIVE == true ]]; then
            echo ""
            printf "Do you need to clone repository: ${MAGENTA}${REPOSITORY_NAME}${NC}? [Y/N] " && read -n1;
            if [[ $REPLY =~ ^[yY]$ ]]; then
                echo ""
                [ -d "$DIRECTORY/$REPOSITORY_NAME" ] && printf "\n${RED}Repository already exists .. pulling new changes${NC}\n" && git -C "$DIRECTORY/$REPOSITORY_NAME" pull origin master || git clone $REPOSITOY_URL "$DIRECTORY/$REPOSITORY_NAME"
            fi
        else
            [ -d "$DIRECTORY/$REPOSITORY_NAME" ] && printf "\n${RED}Repository already exists .. pulling new changes${NC}\n" && git -C "$DIRECTORY/$REPOSITORY_NAME" pull origin master || git clone $REPOSITOY_URL "$DIRECTORY/$REPOSITORY_NAME"
        fi
    done
}

# Iteratively request data from an API endpoint
request_github_api() {
    GITHUB_PAGE=1;
    until [[ $IS_PAGINATED == false ]]; do
        REPOS=$(curl --silent -i -H "Authorization: token ${GITRIEVAL_TOKEN}" "https://api.github.com/${1}&per_page=100&page=${GITHUB_PAGE}" | gawk -v RS=',"' -F: '/^clone_url/ {print $3}' | sed 's/["]//g' | cut -c 3-)
        if [[ ! -n "${REPOS/[ ]*\n/}" ]]; then
            REPOS=$(curl --silent -i -H "Authorization: token ${GITRIEVAL_TOKEN}" "https://api.github.com/${1}&per_page=100&page=${GITHUB_PAGE}" | grep "\"clone_url\"" | gawk -F': "' '{print $2}' | sed -e 's/",//g' | cut -c 9-)
        fi
        if [[ -n "${REPOS/[ ]*\n/}" ]] || [[ ! $GITHUB_PAGE = 1 ]]
        then
            REPOLIST+="\n${REPOS}";
            printf "Retrieving batch: ${GITHUB_PAGE} of repositories --> ${YELLOW} `echo "$REPOLIST" | wc -l` ${NC} processed so far\n";
            if [[ -n $REPOS ]]; then
                (( GITHUB_PAGE++ ))
            else
                printf "Finished retrieving all repositories with Total: ${YELLOW} `echo "$REPOLIST" | wc -l` ${NC}\n";
                IS_PAGINATED=false;
            fi
        else
            printf "${RED}ERROR:${NC} Seems like the request to Github API failed .. make sure you have passed correct values to the command .. sometimes its just Github's fault :(\n" && exit
        fi
    done
    get_repos $REPOLIST
}

if [[ $ORGANISATION != false && -n $ORGANISATION ]]; then
    printf "Retreiving ${RED}${TYPE}${NC} repositories for organisation: ${ORGANISATION}\n"
    request_github_api "orgs/$ORGANISATION/repos?type=${TYPE}"
elif [[ $TEAM != false && -n $TEAM ]]; then
    printf "Retreiving ${RED}${TYPE}${NC} repositories for team: ${TEAM}\n"
    request_github_api "teams/$TEAM/repos?visibility=${TYPE}"
else
    printf "Since no team or organisation were defined, retreiving ${RED}${TYPE}${NC} repositories for the user\n"
    request_github_api "user/repos?type=${TYPE}"
fi
