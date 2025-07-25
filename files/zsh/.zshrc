ZSH_AUTOSUGGEST_STRATEGY=("history" "completion")

. /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
. /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
HISTSIZE="10000"
SAVEHIST="10000"
HISTFILE="$HOME/.zsh_history"

setopt SHARE_HISTORY

# Prompt
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:git*' formats "- (%b) "
precmd() {
    vcs_info
}
setopt prompt_subst
prompt='%B%F{blue}%2/%f ''${vcs_info_msg_0_}%F{green}>%f%b '

# Vi-style menu selection
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

alias cat="bat"
alias gad="git add"
alias gco="git commit"
alias gpu="git push"
alias gst="git status"
alias ollama="podman exec -it ollama ollama"
