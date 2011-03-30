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

# sets the parent branch reference. this is useful if developing off of master
# branch for a typical development cycle. Optional parameter will be used if provided,
# otherwise, uses current branch
function __set_branch_parent {
    if [ -z "$1" ]; then
        export GIT_BRANCH_PARENT="$(__git_ps1 '%s')" # use current branch as parent ref
    else
        export $GIT_BRANCH_PARENT="$1" || ""
    fi
}

# returns current / parent branch name as $BRANCH
# optional parameter of 'parent' will provide parent
function __git_branch_name {
    BRANCH="$(__git_ps1 '%s')" # get current branch name (default)
    if [ -z "$BRANCH" ]; then return; fi

    # return parent branch name
    if [ "$1" = "parent" ]; then
        if [ -n "$GIT_BRANCH_PARENT" ]; then
            BRANCH=$GIT_BRANCH_PARENT
        else
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
    fi

    if [ -n "$BRANCH" ]; then
        return 0
    fi
}

# gets number of commits that are on the master but not on non-master branch
function __git_trunk_unmerged_count {
    __git_branch_name
    if [ "$?" -ne 0 -o "$BRANCH" = "master" ]; then
        GIT_UM_COUNT=0
        return 0
    fi

    # print formatted commit count
    __git_branch_name 'parent'
    GIT_UM_COUNT=$(git log HEAD..$BRANCH --format=oneline 2> /dev/null | wc -l | sed -e 's/     //g') || 0
}

# gets number of commits that are on the branch but not on master (origin if on master branch)
function __git_new_on_branch_count {
    __git_branch_name 'parent'
    if [ "$?" -ne 0 ]; then
        GIT_CM_COUNT=0
        return 0
    fi

    # get commit count
    GIT_CM_COUNT=$(git log $BRANCH..HEAD --format=oneline 2> /dev/null | wc -l | sed -e 's/     //g') || 0
}

# build combined (+/-) counts for related commits
function __git_counts {
    local red="\[\033[01;31m\]"
    local green="\[\033[01;32m\]"
    local reset="\[\033[0m\]"

    GIT_COUNT_STR=""
    # get our counts
    __git_new_on_branch_count
    __git_trunk_unmerged_count

    if [ "$GIT_CM_COUNT" -ne 0 ]; then
        GIT_COUNT_STR="$green+$GIT_CM_COUNT"
    fi

    if [ "$GIT_UM_COUNT" -ne 0 ]; then
        if [ -n "$GIT_COUNT_STR" ]; then
            GIT_COUNT_STR="$GIT_COUNT_STR$reset/"
        fi
        GIT_COUNT_STR="$GIT_COUNT_STR$red-$GIT_UM_COUNT"
    fi

    if [ -n "$GIT_COUNT_STR" ]; then
        GIT_COUNT_STR=" ($GIT_COUNT_STR$reset)"
    fi
}

LIGHT_RED="\033[1;31m"
LIGHT_GREEN="\033[1;32m"
COLOR_NONE="\e[0m"

GREY="\[\033[0;37m\]"
CYAN="\[\033[01;36m\]"
YELLOW="\033[0;33m"
RESET="\[\033[0m\]"

function minutes_since_last_commit {
    now=`date +%s`
    last_commit=`git log --pretty=format:'%at' -1`
    seconds_since_last_commit=$((now-last_commit))
    minutes_since_last_commit=$((seconds_since_last_commit/60))
    echo $minutes_since_last_commit
}

git_prompt() {
  local g="$(__gitdir)"
  if [ -n "$g" ]; then
    local MINUTES_SINCE_LAST_COMMIT=`minutes_since_last_commit`
    if [ "$MINUTES_SINCE_LAST_COMMIT" -gt 30 ]; then
        local COLOR=${LIGHT_RED}
    elif [ "$MINUTES_SINCE_LAST_COMMIT" -gt 10 ]; then
        local COLOR=${YELLOW}
    else
        local COLOR=${LIGHT_GREEN}
    fi
    local SINCE_LAST_COMMIT="${COLOR}$(minutes_since_last_commit)m${COLOR_NONE}"
    # The __git_ps1 function inserts the current git branch where %s is
    #local GIT_PROMPT=`__git_ps1 "(%s|${SINCE_LAST_COMMIT})"`
    local GIT_PROMPT=`__git_ps1 "[${SINCE_LAST_COMMIT}]"`
    echo ${GIT_PROMPT}
  fi
}
# install git integration into PS1
function __gitify_ps1 {
    __git_counts
    PS1="[$GREY\h: $CYAN\W$RESET]$YELLOW\$(__git_ps1 '[%s]')$RESET$GIT_COUNT_STR$(git_prompt) → "
}
PROMPT_COMMAND=__gitify_ps1
