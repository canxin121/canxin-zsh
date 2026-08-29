zsh_dotfiles_has() {
  command -v "$1" >/dev/null 2>&1
}

zsh_dotfiles_omz_loaded() {
  (( $+functions[omz] ))
}

typeset -g ZSH_DOTFILES_OMZ_ROOT="${ZSH:-$HOME/.oh-my-zsh}"
typeset -g ZSH_DOTFILES_OMZ_CUSTOM_ROOT="${ZSH_CUSTOM:-$ZSH_DOTFILES_OMZ_ROOT/custom}"

typeset -ga zsh_dotfiles_default_plugins
zsh_dotfiles_default_plugins=(
  git
  colored-man-pages
  dirhistory
  extract
  sudo
)

zsh_dotfiles_add_plugin() {
  local plugin="$1"
  if (( ${plugins[(Ie)$plugin]:-0} == 0 )); then
    plugins+=("$plugin")
  fi
}

if [[ "${ZSH_DOTFILES_MODE:-bootstrap}" != "integrate" ]]; then
  HISTSIZE="${HISTSIZE:-50000}"
  SAVEHIST="${SAVEHIST:-50000}"
  setopt extended_history
  setopt inc_append_history
  setopt share_history
  setopt hist_ignore_dups
  setopt hist_ignore_all_dups
  setopt hist_find_no_dups
  setopt hist_reduce_blanks
  setopt auto_cd
  setopt auto_pushd
  setopt pushd_ignore_dups
  setopt pushd_silent
fi

# In bootstrap mode, initialize Oh My Zsh only when it has not already been
# loaded. In integrate mode, the installer has detected another framework or
# an existing user configuration and leaves that framework in charge.
if [[ "${ZSH_DOTFILES_BOOTSTRAP_OMZ:-true}" == "true" ]] &&
   ! zsh_dotfiles_omz_loaded &&
   [[ -r "$ZSH_DOTFILES_OMZ_ROOT/oh-my-zsh.sh" ]]; then
  : "${ZSH:=$ZSH_DOTFILES_OMZ_ROOT}"
  : "${ZSH_CUSTOM:=$ZSH_DOTFILES_OMZ_CUSTOM_ROOT}"
  HYPHEN_INSENSITIVE="${HYPHEN_INSENSITIVE:-true}"
  COMPLETION_WAITING_DOTS="${COMPLETION_WAITING_DOTS:-true}"
  zstyle ':omz:update' mode auto

  if [[ -d "$ZSH_DOTFILES_OMZ_CUSTOM_ROOT/themes/powerlevel10k" ]]; then
    ZSH_THEME="${ZSH_THEME:-powerlevel10k/powerlevel10k}"
  else
    ZSH_THEME="${ZSH_THEME:-robbyrussell}"
  fi

  if (( ! $+parameters[plugins] )); then
    plugins=("${zsh_dotfiles_default_plugins[@]}")
  fi

  for plugin in \
    zsh-completions \
    fzf-tab \
    zsh-history-substring-search \
    zsh-autosuggestions \
    zsh-syntax-highlighting; do
    if [[ "$plugin" == "fzf-tab" ]] && ! zsh_dotfiles_has fzf; then
      continue
    fi
    if [[ -d "$ZSH_DOTFILES_OMZ_CUSTOM_ROOT/plugins/$plugin" ]]; then
      zsh_dotfiles_add_plugin "$plugin"
    fi
  done

  if zsh_dotfiles_has brew; then
    zsh_dotfiles_add_plugin brew
  fi
  if [[ "$(uname -s 2>/dev/null || true)" == "Darwin" ]]; then
    zsh_dotfiles_add_plugin macos
  fi
  if zsh_dotfiles_has code; then
    zsh_dotfiles_add_plugin vscode
  fi
  if zsh_dotfiles_has fzf; then
    zsh_dotfiles_add_plugin fzf
  fi

  source "$ZSH_DOTFILES_OMZ_ROOT/oh-my-zsh.sh"
fi

# Do not change existing keybindings or completion styles when this is being
# integrated into a non-empty user configuration. A fresh configuration gets
# the complete defaults below.
if [[ "${ZSH_DOTFILES_MODE:-bootstrap}" != "integrate" ]] &&
   [[ -o interactive && -o zle ]] &&
   [[ -t 0 && -t 1 ]]; then
  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=** r:|=**'
fi

typeset -g ZSH_DOTFILES_LIST_CMD="${ZSH_DOTFILES_LIST_CMD:-}"
if [[ -z "$ZSH_DOTFILES_LIST_CMD" ]]; then
  if zsh_dotfiles_has eza; then
    ZSH_DOTFILES_LIST_CMD="eza"
  elif zsh_dotfiles_has exa; then
    ZSH_DOTFILES_LIST_CMD="exa"
  fi
fi

typeset -g ZSH_DOTFILES_FIND_CMD="${ZSH_DOTFILES_FIND_CMD:-}"
if [[ -z "$ZSH_DOTFILES_FIND_CMD" ]]; then
  if zsh_dotfiles_has fd; then
    ZSH_DOTFILES_FIND_CMD="fd"
  elif zsh_dotfiles_has fdfind; then
    ZSH_DOTFILES_FIND_CMD="fdfind"
  fi
fi

typeset -g ZSH_DOTFILES_BAT_CMD="${ZSH_DOTFILES_BAT_CMD:-}"
if [[ -z "$ZSH_DOTFILES_BAT_CMD" ]]; then
  if zsh_dotfiles_has bat; then
    ZSH_DOTFILES_BAT_CMD="bat"
  elif zsh_dotfiles_has batcat; then
    ZSH_DOTFILES_BAT_CMD="batcat"
  fi
fi

if [[ "${ZSH_DOTFILES_MODE:-bootstrap}" != "integrate" && -n "$ZSH_DOTFILES_FIND_CMD" ]]; then
  if [[ -z "${FZF_DEFAULT_COMMAND:-}" ]]; then
    export FZF_DEFAULT_COMMAND="$ZSH_DOTFILES_FIND_CMD --hidden --strip-cwd-prefix --exclude .git"
  fi
  if [[ -z "${FZF_CTRL_T_COMMAND:-}" ]]; then
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi
  if [[ -z "${FZF_ALT_C_COMMAND:-}" ]]; then
    export FZF_ALT_C_COMMAND="$ZSH_DOTFILES_FIND_CMD --type d --hidden --strip-cwd-prefix --exclude .git"
  fi
elif [[ "${ZSH_DOTFILES_MODE:-bootstrap}" != "integrate" ]]; then
  if [[ -z "${FZF_DEFAULT_COMMAND:-}" ]]; then
    export FZF_DEFAULT_COMMAND='find . -path "*/.git" -prune -o -print | sed "s#^\./##"'
  fi
  if [[ -z "${FZF_CTRL_T_COMMAND:-}" ]]; then
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi
  if [[ -z "${FZF_ALT_C_COMMAND:-}" ]]; then
    export FZF_ALT_C_COMMAND='find . -path "*/.git" -prune -o -type d -print | sed "s#^\./##"'
  fi
fi

if [[ "${ZSH_DOTFILES_MODE:-bootstrap}" != "integrate" && -z "${FZF_DEFAULT_OPTS:-}" ]]; then
  export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border --info=inline'
fi

if [[ -n "$ZSH_DOTFILES_LIST_CMD" ]]; then
  ZSH_DOTFILES_FZF_PREVIEW_CMD="$ZSH_DOTFILES_LIST_CMD -1 --icons=never --color=always \$realpath"
else
  ZSH_DOTFILES_FZF_PREVIEW_CMD='ls -1 $realpath'
fi

if [[ "${ZSH_DOTFILES_MODE:-bootstrap}" != "integrate" ]]; then
  zstyle ':fzf-tab:*' fzf-command fzf
  zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border
  zstyle ':fzf-tab:*' switch-group ',' '.'
  zstyle ':fzf-tab:complete:cd:*' fzf-preview "$ZSH_DOTFILES_FZF_PREVIEW_CMD"
  zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview "$ZSH_DOTFILES_FZF_PREVIEW_CMD"
fi

zsh_dotfiles_define_alias() {
  local name="$1"
  local value="$2"

  if alias "$name" >/dev/null 2>&1 || (( $+functions[$name] )); then
    return
  fi
  alias "$name=$value"
}

if [[ -n "$ZSH_DOTFILES_BAT_CMD" ]]; then
  zsh_dotfiles_define_alias catp "$ZSH_DOTFILES_BAT_CMD --paging=always --theme=TwoDark"
fi

if [[ -n "$ZSH_DOTFILES_LIST_CMD" ]]; then
  zsh_dotfiles_define_alias l "$ZSH_DOTFILES_LIST_CMD --icons=never --group-directories-first"
  zsh_dotfiles_define_alias ls "$ZSH_DOTFILES_LIST_CMD --icons=never --group-directories-first"
  zsh_dotfiles_define_alias ll "$ZSH_DOTFILES_LIST_CMD -lah --icons=never --group-directories-first --git"
  zsh_dotfiles_define_alias la "$ZSH_DOTFILES_LIST_CMD -la --icons=never --group-directories-first"
  zsh_dotfiles_define_alias lt "$ZSH_DOTFILES_LIST_CMD --tree --icons=never --group-directories-first"
fi

if zsh_dotfiles_has rg; then
  zsh_dotfiles_define_alias grep rg
fi

if zsh_dotfiles_has btop; then
  zsh_dotfiles_define_alias top btop
fi

if zsh_dotfiles_has lazygit; then
  zsh_dotfiles_define_alias lg lazygit
fi

zsh_dotfiles_define_alias zreload 'source ~/.zshrc'

if (( ! $+functions[zsh_dotfiles_update_all] )); then
  zsh_dotfiles_update_all() {
    if (( $+commands[omz] )); then
      omz update
    elif [[ -d "$ZSH_DOTFILES_OMZ_ROOT/.git" ]]; then
      git -C "$ZSH_DOTFILES_OMZ_ROOT" pull --ff-only
    fi

    for repo in "$ZSH_DOTFILES_OMZ_CUSTOM_ROOT"/plugins/*(N) "$ZSH_DOTFILES_OMZ_CUSTOM_ROOT"/themes/*(N); do
      [[ -d "$repo/.git" ]] && git -C "$repo" pull --ff-only
    done

    if zsh_dotfiles_has brew; then
      brew update
      brew upgrade
    fi

    command -v tldr >/dev/null 2>&1 && tldr --update
  }
fi
zsh_dotfiles_define_alias zupdate-all zsh_dotfiles_update_all

if [[ "${ZSH_DOTFILES_MODE:-bootstrap}" != "integrate" ]] &&
   [[ -o interactive && -o zle ]] &&
   [[ -t 0 && -t 1 ]]; then
  autoload -Uz edit-command-line
  zle -N edit-command-line
  bindkey '^E' edit-command-line
  bindkey -M emacs '^E' edit-command-line
  bindkey -M viins '^E' edit-command-line
  bindkey -M vicmd 'v' edit-command-line

  if (( $+widgets[history-substring-search-up] )); then
    bindkey '^[[A' history-substring-search-up
  fi

  if (( $+widgets[history-substring-search-down] )); then
    bindkey '^[[B' history-substring-search-down
  fi
fi
