# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin directories
PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Colors
# When using these with echo, remember to use '-e' flag.
BLACK='\033[0;30m'
DARK_GRAY='\033[1;30m'
RED='\033[0;31m'
LIGHT_RED='\033[1;31m'
GREEN='\033[0;32m'
LIGHT_GREEN='\033[1;32m'
BROWN='\033[0;33m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHT_BLUE='\033[1;34m'
PURPLE='\033[0;35m'
LIGHT_PURPLE='\033[1;35m'
CYAN='\033[0;36m'
LIGHT_CYAN='\033[1;36m'
LIGHT_GRAY='\033[0;37m'
WHITE='\033[1;37m'
NO_COLOR='\033[0m'

COMPANY=''
test -z "$COMPANY" && echo -e "\n${YELLOW}Variable COMPANY is not set. Skipping functions that depend on it.${NO_COLOR}\n" && return

# ensure public key exists
PRIVATE_KEY="/etc/${COMPANY}.d/${USER}-id_rsa"
if [ ! -f "${PRIVATE_KEY}.pub" ]; then
    echo "Creating public key ${PRIVATE_KEY}.pub..."
    /usr/bin/ssh-keygen -y -f $PRIVATE_KEY | sudo tee -a "${PRIVATE_KEY}.pub" &>/dev/null
    sudo chown "${USER}":"${USER}" "${PRIVATE_KEY}.pub"
fi

# Add key to agent and export env variables
SSH_ENV_VARS_FILE="$HOME/.keychain/${HOSTNAME}-sh"
#/usr/bin/keychain --inherit any-once --systemd others --agents ssh --quick $PRIVATE_KEY
/usr/bin/keychain --inherit local-once --systemd others --agents ssh --quick "${PRIVATE_KEY}"
test -f "$SSH_ENV_VARS_FILE" && eval "$(cat $SSH_ENV_VARS_FILE)"

# Update chef repo
CHEF_DIR="${HOME}/src/${COMPANY}-github.com/${COMPANY}/chef-repo"
CHEF_REPO_BIN="${CHEF_DIR}/bin"
if [ -d "$CHEF_REPO_BIN" ]; then
    PATH=$PATH:"$CHEF_REPO_BIN"
fi

function git-clean-merged-branches()
{
    test -d "$CHEF_DIR" || return

    echo "Cleaning merged branches."
    pushd . &> /dev/null
    cd "$CHEF_DIR" || return
    git fetch --prune &> /dev/null
    for branch in $(git for-each-ref refs/heads/ --format="%(refname:short) %(upstream:trackshort)" | grep -vP '<|>|='); do
        git branch -D "$branch" &> /dev/null
    done
    popd &> /dev/null
}

function update-chef-repo()
{
    test -d "$CHEF_DIR" || return

    pushd . &> /dev/null
    echo -e "\nUpdating $CHEF_DIR"
    cd "$CHEF_DIR"
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    unmerged_remote_branches=$(git for-each-ref refs/heads/ --format="%(refname:short) %(upstream:trackshort)" | grep -P '<|>|=' | tr -d '<>=' | tr -s '\n' ' ')
    git fetch --prune &> /dev/null

    if [ "$current_branch" != "master" ]; then
        git checkout master &> /dev/null
    fi
    git pull &> /dev/null
    # if the branch is unmerged in upstream, switch back to it. master does not appear in unmerged branches.
    if [[ "$unmerged_remote_branches" == *"$current_branch"* ]]; then
        git checkout "$current_branch" &> /dev/null
        git pull &> /dev/null
    fi
    echo -e "Current branch: ${LIGHT_RED}$(git rev-parse --abbrev-ref HEAD)${NO_COLOR}"
    popd &> /dev/null
}

# Do git maintenance only when there are no other sessions active.
num_ssh_sessions=$(who | wc -l)
if [[ "$num_ssh_sessions" -eq 1 ]]; then
    git-clean-merged-branches
    update-chef-repo
elif [[ -d "$CHEF_DIR" ]]; then
    pushd . &> /dev/null
    cd "$CHEF_DIR"
    echo -e "Current branch: ${LIGHT_RED}$(git rev-parse --abbrev-ref HEAD)${NO_COLOR}"
    popd &> /dev/null
fi


export OKTA_USERNAME="${USER}@${COMPANY}-corp.com"
export OKTA_PASSWORD='PUT_PASSWORD_HERE'
