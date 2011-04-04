Developer's Bash-GIT PS1 Integration
----------

### Description
    Provides simple information about git repository for the bash terminal

    Erik Johnson (xtrementl)
    Created: 07-29-2009
    Updated: 03-31-2011

    Special thanks to:
    reborg

    The PS1 will be formatted as follows:
    Non-Git repo:
        [{host}: {dir}] -->
        $

    Git repo:
        [{host}: {dir}] {branch}({diff upstream counts}){working dir syms} [{time last commit}] -->
        $

### Notes
    The marker ($) will be colored red/green depending on the result of last command's exit code
    For Git repos, the working dir symbols are:
        + - staged changes
        * - unstaged changes
        ^ - stashed changes
        % - untracked files

### Installation
    Add the following line to your .bashrc:
        source ~/.bash_git_ps1.sh
