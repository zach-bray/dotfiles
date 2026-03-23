# Enable prompt variable expansion
setopt PROMPT_SUBST

prompt_precmd() {
    # 1. Colors (Zsh doesn't need the \[ \] wrappers)
    local RED="%F{red}"
    local GREEN="%F{green}"
    local YELLOW="%F{yellow}"
    local BLUE="%F{blue}"
    local PURPLE="%F{magenta}"
    local CYAN="%F{cyan}"
    local RESET="%f"

    local BRANCH=""
    local BRANCH_COLOR=$GREEN
    local COMMITS_DIFF=""

    # 2. Git Logic
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local B_NAME=$(git symbolic-ref --short HEAD 2>/dev/null || echo "NO-BRANCH")
        
        # Get ahead/behind counts
        local STATS=$(git rev-list --left-right --count "origin/$B_NAME...$B_NAME" 2>/dev/null)
        
        if [[ -z $STATS ]]; then
            COMMITS_DIFF=" ?"
            BRANCH_COLOR=$YELLOW
        else
            local BEHIND=$(echo $STATS | awk '{print $1}')
            local AHEAD=$(echo $STATS | awk '{print $2}')

            [[ "$AHEAD" != "0" ]] && { COMMITS_DIFF=" +$AHEAD"; BRANCH_COLOR=$YELLOW; }
            [[ "$BEHIND" != "0" ]] && { COMMITS_DIFF+=" -$BEHIND"; BRANCH_COLOR=$RED; }
        fi

        # Check for dirty working tree
        if ! git diff-index --quiet HEAD 2>/dev/null; then
            BRANCH_COLOR=$RED
        fi

        BRANCH=" [$B_NAME$COMMITS_DIFF]"
    fi

    # 3. Host Logic
    local HOST_PART=""
    local HOST_RAW=""
    if [[ $LOCAL != 1 ]]; then
        HOST_PART="${RED}@${CYAN}%m"
        HOST_RAW="@%m" # %m is short hostname in Zsh
    fi

    # 4. Construct PS1
    # %n = username, %c = trailing component of current dir
    PS1="${CYAN}%n${HOST_PART}${RED}:${PURPLE}%c${BRANCH_COLOR}${BRANCH}${RED} > ${RESET}"

    # 5. Construct PS2 (Matching length of first line)
    # Zsh allows us to strip the % codes to get real character length
    local PROMPT_PLAIN="${USER}${HOST_RAW}:${(%):-%c}${BRANCH}"
    local SPACES=""
    for (( i=1; i<=${#PROMPT_PLAIN}+3; i++ )); do SPACES+=" "; done
    
    PS2="${SPACES}${RED}>${RESET} "
}

# Use the Zsh hook system instead of PROMPT_COMMAND
autoload -Uz add-zsh-hook
add-zsh-hook precmd prompt_precmd