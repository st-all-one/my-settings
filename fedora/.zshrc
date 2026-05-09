# =============================================================================
# ZSH Configuration - Ultra Optimized (Fedora 44)
# =============================================================================

# --- 1. Otimização de Boot & Memória ---
DISABLE_MAGIC_FUNCTIONS="true"
ZLE_SPACE_SUFFIX_CHARS=$' \t\n;&|'
skip_global_compinit=1

# --- 2. Otimização do Autocomplete Nativo ---
fpath=(~/.zsh/completions $fpath)

autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit -d ~/.zcompdump
else
  compinit -C -d ~/.zcompdump
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'

zstyle ':completion:*:commands' rehash 1
zstyle ':completion:*:*:*:users' ignored-patterns \
        adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
        dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
        hacluster haldaemon halt hsqldb ident junkbust kdm ldap lp mail \
        mailman mailnull mldonkey mysql nagios \
        named netdump news nfsnobody nobody nscd ntp nut nx obsrun openvpn \
        operator pcap polkitd postfix postgres privoxy pulse pvm quagga radvd \
        rpc rpcuser rpm rtkit scard shutdown squid sshd statd svn sync tftp \
        usbmux uucp vcsa wwwrun xfs '_*'

# --- 3. UI, Comportamento e Histórico ---
export EDITOR='nano'
export LANG=pt_BR.UTF-8
export LC_ALL=pt_BR.UTF-8

# Usar bat para colorir páginas de manual (man pages)
if (( $+commands[bat] )); then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# Histórico otimizado
export HISTFILE=~/.zsh_history
export HISTSIZE=50000
export SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# --- Inteligência das Setas (Prefix Search) ---
# Filtra o histórico com base no comando parcialmente digitado
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Seta para Cima
bindkey "^[[B" down-line-or-beginning-search # Seta para Baixo

# GIT
export GIT_INDEX_VERSION=4
export GIT_OPTIONAL_LOCKS=0
export GIT_PAGER="delta"
export GIT_EDITOR="nano"
export GIT_TRACE_PERFORMANCE=1
export GIT_TRACE_SETUP=1

# Docker
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# --- 4. PATH Tuning ---
# :$PATH adicionado ao final para preservar binários do sistema (ex: Node/NPM)
export PATH="$HOME/.deno/bin:$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.config/composer/vendor/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# --- 5. Aliases ---
if (( $+commands[eza] )); then
    alias ls='eza --icons --group-directories-first'
    alias la='eza -a --icons --group-directories-first'
    alias ll='eza -la --icons --group-directories-first --git'
    alias tree='eza --tree --icons'
else
    alias ls='ls --color=auto'
fi

if (( $+commands[difft] )); then
    alias diff='difft --color always --background dark --display side-by-side'
else
    alias diff='diff --color=auto --unified'
fi

if (( $+commands[bat] )); then
    alias cat='bat --style=plain --paging=never'
    alias preview='bat'
fi

alias c='clear -x'
alias cp='cp -iv'
alias mv='mv -iv'
alias df='df -h'

chpwd() {
    if (( $+commands[eza] )); then
        eza --icons --group-directories-first
    else
        ls --color=auto
    fi
}

if (( $+commands[trash-put] )); then
    alias rm='trash-put'
    alias tl='trash-list'
    alias trm='trash-restore'
    alias tclean='trash-empty'
else
    alias rm='rm -I'
fi

alias g='git'
alias gs='git status -sb'
alias gl='git log --graph --abbrev-commit --decorate --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)" --all'
alias gad='git add'
alias ga='git add -p'
alias gc='git commit -s -v'

gpush() {
    local target=$1
    local milestone=$2

    if [[ -z "$target" ]]; then
        echo "❌ Erro: Branch alvo obrigatória."
        echo "Uso: gpush <branch-alvo> [milestone]"
        return 1
    fi

    local cmd=(git push -o merge_request.create -o "merge_request.target=$target")

    if [[ -n "$milestone" ]]; then
        cmd+=(-o "merge_request.milestone=$milestone")
        echo "🚀 Criando MR para: %F{3}$target%f | Milestone: %F{2}$milestone%f"
    else
        echo "🚀 Criando MR para: %F{3}$target%f"
    fi

    "${cmd[@]}"
}

# --- 6. Integração do FZF ---
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

if (( $+commands[bat] )); then
    # Usa o bat para colorir o preview nativo do FZF (ex: ao apertar Ctrl+T)
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
fi

[[ -f /usr/share/fzf/shell/key-bindings.zsh ]] && source /usr/share/fzf/shell/key-bindings.zsh

# Buscar e Abrir Arquivo Rápido (Ctrl+O)
fo() {
  local file
  file=$(fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}') && ${EDITOR:-nano} "$file"
}
bindkey -s '^o' 'fo\n'

# Busca e Navegação Rápida de Diretório (Ctrl+G)
fd() {
  local dir
  dir=$(find ${1:-.} -path '*/.*' -prune -o -type d -print 2> /dev/null | fzf) && cd "$dir"
}
bindkey -s '^g' 'fd\n'

# --- 7. Fast Syntax Highlighting & Autosuggestions ---
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZSH_HIGHLIGHT_MAXLENGTH=512

typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[error]='fg=red,bold,underline'

eval "$(zoxide init zsh --cmd cd)"
eval "$(starship init zsh)"

enable_transient_prompt() {
  function starship_zle-keymap-select() {
    zle .starship_zle-keymap-select
    _starship_transient_prompt
  }
  zle -N starship_zle-keymap-select
}

enable_transient_prompt

if [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

[[ -f "$HOME/.deno/env" ]] && . "$HOME/.deno/env"
