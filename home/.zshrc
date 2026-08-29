# This file is sourced by the managed block installed in ~/.zshrc.
# It intentionally does not replace the user's existing zsh configuration.

ZSH_DOTFILES_HOME="${${(%):-%N}:A:h}"
ZSH_DOTFILES_ROOT="${ZSH_DOTFILES_HOME:h}"

if [[ -r "$ZSH_DOTFILES_ROOT/zsh/rc/common.zsh" ]]; then
  source "$ZSH_DOTFILES_ROOT/zsh/rc/common.zsh"
fi

# Respect an existing theme and user p10k configuration. Only load the
# repository defaults when Powerlevel10k is selected and there is no readable
# user-owned p10k config to take precedence.
if [[ -r "$ZSH_DOTFILES_ROOT/home/.p10k.zsh" ]] &&
   [[ ! -r "$HOME/.p10k.zsh" ]] &&
   [[ -z "${POWERLEVEL9K_CONFIG_FILE:-}" || ! -r "$POWERLEVEL9K_CONFIG_FILE" ]] &&
   [[ -z "${ZDOTDIR:-}" || ! -r "$ZDOTDIR/.p10k.zsh" ]] && {
  [[ "${ZSH_THEME:-}" == "powerlevel10k" ]] ||
  [[ "${ZSH_THEME:-}" == "powerlevel10k/powerlevel10k" ]] ||
  (( $+functions[prompt_powerlevel10k_setup] ))
}; then
  source "$ZSH_DOTFILES_ROOT/home/.p10k.zsh"
fi
