#!/bin/bash

###################################################################################
# Developer's Bash-GIT PS1 Integration
###################################################################################
# Provides simple information for the bash terminal, using git-completion script
#
# Erik Johnson (xtrementl)
# 07-29-2009
#
# -[ Requirements ]-
#   bash shell (obviously)
#   bash-completion
#   git-completion script (available from sources http://git.kernel.org/)
#
# -[ Installation ]-
#   Add line to relevant .bashrc:
#       source "/path/to/bash_git_ps1.sh"
###################################################################################

# returns current / parent branch name as $BRANCH
# optional parameter of 'parent' will provide parent
function __git_branch_name {
    BRANCH="$(__git_ps1 '%s')" # get current branch name (default)
    if [ -z "$BRANCH" ]; then return; fi

    # return parent branch name
    if [ "$1" = "parent" ]; then
        local refs="$(__git_refs)"

        if [ "$BRANCH" = "master" ]; then
            if [[ "$refs" =~ "git-svn" ]]; then # git-svn repo
                BRANCH='git-svn'
            elif [[ "$refs" =~ "origin" ]]; then # remote clone
                BRANCH='origin'
            else
                BRANCH='HEAD' # same repo
            fi
        else # on a branch
            BRANCH='master'
        fi
    fi

    if [ -n "$BRANCH" ]; then
        return 0
    fi
}

# prints number of commits that are on the master but not on non-master branch
function __git_trunk_unmerged_count {
    __git_branch_name
    if [ "$?" -ne 0 -o "$BRANCH" = "master" ]; then return; fi

    # print formatted commit count
    __git_branch_name 'parent'
    local count=`git log HEAD..$BRANCH --format=oneline 2> /dev/null | wc -l` || return
    if [ "$count" != "0" ]; then
        printf "%s-%s%s" $RED $count $RESET
    fi
}

# prints number of commits that are on the branch but not on master (origin if on master branch)
function __git_new_on_branch_count {
    __git_branch_name 'parent'
    if [ "$?" -ne 0 ]; then return; fi

    # print formatted commit count
    local count=`git log $BRANCH..HEAD --format=oneline 2> /dev/null | wc -l` || return

    if [ "$count" != "0" ]; then
        printf "%s+%s%s" $GREEN $count $RESET
    fi
}

# prints combined (+/-) counts for related commits
function __git_print_counts {
    local arr=("$(__git_new_on_branch_count)" "$(__git_trunk_unmerged_count)")
    local str=""

    # build counts
    for item in ${arr[*]}; do
        str="$str$item/" 
    done
    local len=${#str}
    ((len--))
    
    # print formatted count list
    if [ -n "$str" ]; then
        echo -en " (${str:0:$len})"
    fi
}

# setup colors
RESET="\e[00m"
RED="\e[01;31m"
GRAY="\e[0;37m"
CYAN="\e[01;36m"
BLUE="\e[01;34m"
GREEN="\e[01;32m"
YELLOW="\e[01;33m"

# integrate git awareness into bash terminal PS1
PS1="[$GRAY\h:$RESET $CYAN\W$RESET]$YELLOW\$(__git_ps1 ' %s')$RESET\$(__git_print_counts) \$ "
