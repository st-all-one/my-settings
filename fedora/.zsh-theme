# -----------------------------------------------------------------------------
# ZSH Theme - Ultra Minimal (Fedora/Git Root Context)
# Foco: Velocidade bruta e Caminhos Relativos ao Projeto
# -----------------------------------------------------------------------------

# --- Otimizações do Motor Zsh ---
setopt PROMPT_SUBST
setopt PROMPT_SP
unsetopt PROMPT_CR

# --- Módulo Nativo do Git (vcs_info) ---
autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*' check-for-changes true
zstyle ':vcs_info:git*' stagedstr '+'
zstyle ':vcs_info:git*' unstagedstr '*'

# Formato do Git: (branch) ou (branch*)
zstyle ':vcs_info:git*' formats '(%F{3}%b%c%u%f)'
zstyle ':vcs_info:git*' actionformats '(%F{3}%b|%a%c%u%f)'

# --- Lógica de Caminho de Repositório ---
# Esta função verifica onde está a pasta .git mais próxima e corta o caminho
project_path() {
    # Tenta descobrir o topo do repositório git atual (silenciosamente)
    local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    
    if [[ -n "$git_root" ]]; then
        # Se estamos num repo Git, remove a base do caminho e adiciona a barra '/'
        local rel_path="${PWD#$git_root}"
        
        if [[ -z "$rel_path" ]]; then
            echo "~" # Estamos na exata raiz do repositório
        else
            echo "~$rel_path" # Estamos em um subdiretório do repositório
        fi
    else
        # Se não for Git, mostra o caminho tradicional encurtado (~/Documentos)
        echo "%~"
    fi
}

# --- Ciclo de Pré-Renderização ---
# Executa antes de exibir o prompt para não gerar lag ao digitar
precmd() {
    vcs_info
}

# --- Construção do Prompt ---
# ${vcs_info_msg_0_} -> Insere a tag da branch se existir, e um espaço se estiver preenchida.
# $(project_path)    -> Insere '/' se na raiz do repo, ou o caminho relativo. Caso contrário, %~.
# Resultado: (main*) [/src] > 
PROMPT='${vcs_info_msg_0_:+${vcs_info_msg_0_} }[%F{12}$(project_path)%f] > '

# Limpa o prompt direito completamente para focar na esquerda
RPROMPT=''
