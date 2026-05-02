# =============================================================================
# ZSH Configuration - Ultra Optimized (Fedora 44)
# =============================================================================

# --- 1. Otimização de Boot & Memória ---
# Desabilita logs extensivos e funções mágicas lentas (agiliza o parsing e copy/paste)
DISABLE_MAGIC_FUNCTIONS="true"
ZLE_SPACE_SUFFIX_CHARS=$' \t\n;&|'
# Acelera a inicialização ignorando arquivos de dump globais e forçando o compinit nativo
skip_global_compinit=1

# --- 2. Otimização do Autocomplete Nativo ---
# Garante que pastas de funções personalizadas (se existirem) estejam no fpath
fpath=(~/.zsh/completions $fpath)

# Inicializa o compinit com cache (essencial para o Ryzen/NVMe)
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit -d ~/.zcompdump
else
  compinit -C -d ~/.zcompdump
fi

# Configurações do Autocomplete
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'

# Otimização: Não autocompletar binários que o usuário atual não tem permissão
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

# Histórico otimizado
export HISTFILE=~/.zsh_history
export HISTSIZE=50000
export SAVEHIST=50000
setopt EXTENDED_HISTORY          # Grava timestamp e duração do comando
setopt HIST_EXPIRE_DUPS_FIRST    # Se encher, apaga as duplicatas primeiro
setopt HIST_IGNORE_DUPS          # Ignora a gravação consecutiva de comandos iguais
setopt HIST_IGNORE_SPACE         # Comandos com espaço no início não vão para o histórico
setopt HIST_FIND_NO_DUPS         # Não mostra o mesmo comando repetido na busca
setopt SHARE_HISTORY             # Compartilha o histórico entre abas ativas
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

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

# Carrega o tema
source ~/.zsh-theme

# --- 4. PATH Tuning ---
# Definido diretamente sem chamadas extras ao SO
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.config/composer/vendor/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# --- 5. Aliases ---
# Substituição moderna de ferramentas nativas
if (( $+commands[eza] )); then
    alias ls='eza --icons --group-directories-first'
    alias la='eza -a --icons --group-directories-first'
    alias ll='eza -la --icons --group-directories-first --git'
    alias tree='eza --tree --icons'
else
    alias ls='ls --color=auto'
fi

# Aliases de Segurança e Qualidade de Vida
alias cp='cp -iv'
alias mv='mv -iv'
alias df='df -h'

chpwd() {
    # Lista o conteúdo da pasta automaticamente (usando o eza se existir)
    if (( $+commands[eza] )); then
        eza --icons --group-directories-first
    else
        ls --color=auto
    fi
}

if (( $+commands[trash-put] )); then
    alias rm='trash-put'
    alias tl='trash-list'    # Lista o que está na lixeira
    alias trm='trash-restore' # Restaura um arquivo da lixeira (interativo)
    alias tclean='trash-empty' # Esvazia a lixeira
else
    alias rm='rm -I'
fi

# Aliases de Git
alias g='git'
alias gs='git status -sb'
alias gl='git log --graph --abbrev-commit --decorate --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)" --all'
alias gad='git add'
alias ga='git add -p'
alias gc='git commit -s -v'

gpush() {
    local target=$1
    local milestone=$2

    # Validação do primeiro parâmetro (Obrigatório
    if [[ -z "$target" ]]; then
        echo "❌ Erro: Branch alvo obrigatória."
        echo "Uso: gpush <branch-alvo> [milestone]"
        return 1
    fi

    # Base do comando com a branch alvo
    local cmd=(git push -o merge_request.create -o "merge_request.target=$target")

    # Tratamento do segundo parâmetro (Opcional)
    if [[ -n "$milestone" ]]; then
        cmd+=(-o "merge_request.milestone=$milestone")
        echo "🚀 Criando MR para: %F{3}$target%f | Milestone: %F{2}$milestone%f"
    else
        echo "🚀 Criando MR para: %F{3}$target%f"
    fi

    # Executa o comando construído
    "${cmd[@]}"
}

# --- 6. Integração do FZF ---
# Acelera a busca de arquivos e histórico
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
[[ -f /usr/share/fzf/shell/key-bindings.zsh ]] && source /usr/share/fzf/shell/key-bindings.zsh

# --- 7. Fast Syntax Highlighting & Autosuggestions ---
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50 # Não tenta sugerir em comandos imensos

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZSH_HIGHLIGHT_MAXLENGTH=512

typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[error]='fg=red,bold,underline'

# Carregamento nativo do Fedora (assumindo pacotes dnf instalados)
if [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi