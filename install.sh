#!/usr/bin/env bash

# shellcheck disable=SC2016
# Generated zsh snippets intentionally keep $HOME literal for later expansion.

set -euo pipefail

PROJECT_NAME="canxin-zsh"
PROJECT_URL_DEFAULT="https://github.com/canxin121/canxin-zsh.git"
LEGACY_PROJECT_URL_DEFAULT="https://github.com/canxin121/zsh-dotfiles.git"
PROJECT_REF_DEFAULT="main"

OH_MY_ZSH_REPO="https://github.com/ohmyzsh/ohmyzsh.git"

PLUGIN_RELS=(
  "plugins/fzf-tab"
  "plugins/zsh-autosuggestions"
  "plugins/zsh-completions"
  "plugins/zsh-history-substring-search"
  "plugins/zsh-syntax-highlighting"
  "themes/powerlevel10k"
)

PLUGIN_URLS=(
  "https://github.com/Aloxaf/fzf-tab.git"
  "https://github.com/zsh-users/zsh-autosuggestions.git"
  "https://github.com/zsh-users/zsh-completions.git"
  "https://github.com/zsh-users/zsh-history-substring-search.git"
  "https://github.com/zsh-users/zsh-syntax-highlighting.git"
  "https://github.com/romkatv/powerlevel10k.git"
)

REPO_URL="${ZSH_DOTFILES_REPO_URL:-$PROJECT_URL_DEFAULT}"
PROJECT_REF="${ZSH_DOTFILES_REF:-$PROJECT_REF_DEFAULT}"
SOURCE_INSTALL_DIR_DEFAULT="${XDG_DATA_HOME:-$HOME/.local/share}/$PROJECT_NAME"
LEGACY_SOURCE_INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh-dotfiles"
if [[ -n "${ZSH_DOTFILES_INSTALL_DIR:-}" ]]; then
  SOURCE_INSTALL_DIR="$ZSH_DOTFILES_INSTALL_DIR"
  SOURCE_INSTALL_DIR_EXPLICIT=1
else
  SOURCE_INSTALL_DIR="$SOURCE_INSTALL_DIR_DEFAULT"
  SOURCE_INSTALL_DIR_EXPLICIT=0
fi

REPO_ROOT=""
SOURCE_BOOTSTRAPPED=0
UPDATE_EXISTING=0
UPDATE_SOURCE=0
SKIP_DEPENDENCIES="${ZSH_DOTFILES_SKIP_DEPENDENCIES:-0}"
SKIP_SYSTEM_DEPENDENCIES="${ZSH_DOTFILES_SKIP_SYSTEM_DEPENDENCIES:-0}"
AUTO_INSTALL_SYSTEM="${ZSH_DOTFILES_AUTO_INSTALL:-1}"
INSTALL_OPTIONAL_TOOLS="${ZSH_DOTFILES_INSTALL_OPTIONAL_TOOLS:-1}"
DRY_RUN="${ZSH_DOTFILES_DRY_RUN:-0}"
ZDOTDIR_ROOT="${ZDOTDIR:-$HOME}"
BACKUP_DIR=""

BEGIN_MARKER="# >>> zsh-dotfiles managed block >>>"
END_MARKER="# <<< zsh-dotfiles managed block <<<"

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Install or integrate the canxin-zsh configuration without replacing an
existing ~/.zshrc or ~/.zprofile.

Options:
  --update                  Update existing Oh My Zsh/plugin/theme checkouts.
  --update-source           Update a bootstrapped canxin-zsh checkout.
  --skip-dependencies       Do not install system, Oh My Zsh, or custom dependencies.
  --no-system-dependencies  Do not use a system package manager.
  --no-optional-tools       Do not install optional CLI tools.
  --install-dir DIR         Checkout location for curl|bash installation.
  --repo-url URL            Repository URL used by curl|bash installation.
  --ref REF                 Branch or tag used by curl|bash installation.
  --dry-run                 Show planned changes without writing files.
  -h, --help                Show this help text.

Environment:
  ZSH_DOTFILES_INSTALL_DIR  Same as --install-dir.
  ZSH_DOTFILES_REPO_URL     Same as --repo-url.
  ZSH_DOTFILES_REF          Same as --ref.
  ZSH_DOTFILES_SKIP_DEPENDENCIES=1
  ZSH_DOTFILES_SKIP_SYSTEM_DEPENDENCIES=1
  ZSH_DOTFILES_AUTO_INSTALL=0
  ZSH_DOTFILES_INSTALL_OPTIONAL_TOOLS=0
  ZSH_DOTFILES_DRY_RUN=1

Examples:
  ./install.sh
  ./install.sh --update
  curl -fsSL https://raw.githubusercontent.com/canxin121/canxin-zsh/main/install.sh | bash
EOF
}

log() {
  printf '[%s] %s\n' "$PROJECT_NAME" "$*"
}

warn() {
  printf '[%s] warning: %s\n' "$PROJECT_NAME" "$*" >&2
}

die() {
  printf '[%s] error: %s\n' "$PROJECT_NAME" "$*" >&2
  exit 1
}

is_true() {
  case "${1:-0}" in
    1|true|yes|on) return 0 ;;
    *) return 1 ;;
  esac
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

is_symlink() {
  [[ -L "$1" ]] && return 0
  command -v readlink >/dev/null 2>&1 || return 1
  [[ -n "$(readlink "$1" 2>/dev/null || true)" ]]
}

symlink_points_to() {
  local link="$1"
  local target="$2"
  local link_target

  [[ "$link" -ef "$target" ]] && return 0
  command -v readlink >/dev/null 2>&1 || return 1
  link_target="$(readlink "$link" 2>/dev/null || true)"
  [[ -n "$link_target" ]] || return 1
  [[ "$link_target" == "$target" ]] && return 0

  if [[ "$link_target" != /* ]]; then
    link_target="$(dirname "$link")/$link_target"
  fi
  [[ "$link_target" == "$target" ]]
}

path_exists() {
  [[ -e "$1" ]] || is_symlink "$1"
}

detect_platform() {
  local system
  system="$(uname -s 2>/dev/null || printf 'unknown')"

  case "$system" in
    Darwin) printf 'macOS' ;;
    Linux)
      if [[ -r /proc/version ]] && grep -qi microsoft /proc/version; then
        printf 'Linux (WSL)'
      else
        printf 'Linux'
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*) printf 'Windows POSIX shell (%s)' "$system" ;;
    *) printf '%s' "$system" ;;
  esac
}

has_any_command() {
  local command_name

  for command_name in "$@"; do
    if command -v "$command_name" >/dev/null 2>&1; then
      return 0
    fi
  done
  return 1
}

run_privileged() {
  local uid

  uid="${EUID:-}"
  if [[ -z "$uid" ]]; then
    uid="$(id -u)"
  fi

  if [[ "$uid" == "0" ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  elif command -v doas >/dev/null 2>&1; then
    doas "$@"
  else
    die "Installing system packages requires root, sudo, or doas: $*"
  fi
}

is_msys2_environment() {
  local system
  system="$(uname -s 2>/dev/null || printf 'unknown')"
  [[ -n "${MSYSTEM:-}" ]] || [[ "$system" == MSYS* ]] || [[ "$system" == MINGW* ]]
}

detect_package_manager() {
  local system
  system="$(uname -s 2>/dev/null || printf 'unknown')"

  if [[ "$system" == Darwin* ]] && command -v brew >/dev/null 2>&1; then
    printf 'brew'
    return 0
  fi

  if is_msys2_environment && command -v pacman >/dev/null 2>&1; then
    printf 'pacman'
    return 0
  fi

  if command -v apt-get >/dev/null 2>&1; then
    printf 'apt-get'
  elif command -v dnf >/dev/null 2>&1; then
    printf 'dnf'
  elif command -v yum >/dev/null 2>&1; then
    printf 'yum'
  elif command -v pacman >/dev/null 2>&1; then
    printf 'pacman'
  elif command -v apk >/dev/null 2>&1; then
    printf 'apk'
  elif command -v zypper >/dev/null 2>&1; then
    printf 'zypper'
  elif command -v brew >/dev/null 2>&1; then
    printf 'brew'
  else
    return 1
  fi
}

MISSING_REQUIRED_COMMANDS=()
SYSTEM_REQUIRED_PACKAGES=()
SYSTEM_OPTIONAL_PACKAGES=()
APT_UPDATE_DONE=0

collect_missing_required_commands() {
  local command_name

  MISSING_REQUIRED_COMMANDS=()

  for command_name in zsh git curl; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      MISSING_REQUIRED_COMMANDS+=("$command_name")
    fi
  done
}

build_package_lists() {
  local manager="$1"

  SYSTEM_REQUIRED_PACKAGES=()
  SYSTEM_OPTIONAL_PACKAGES=()

  case "$manager" in
    brew)
      if ! command -v zsh >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(zsh)
      fi
      if ! command -v git >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(git)
      fi
      if ! command -v curl >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(curl)
      fi

      if ! command -v fzf >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(fzf)
      fi
      if ! command -v rg >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(ripgrep)
      fi
      if ! has_any_command fd fdfind; then
        SYSTEM_OPTIONAL_PACKAGES+=(fd)
      fi
      if ! has_any_command eza exa; then
        SYSTEM_OPTIONAL_PACKAGES+=(eza)
      fi
      if ! has_any_command bat batcat; then
        SYSTEM_OPTIONAL_PACKAGES+=(bat)
      fi
      if ! command -v btop >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(btop)
      fi
      if ! command -v lazygit >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(lazygit)
      fi
      if ! command -v tldr >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(tealdeer)
      fi
      ;;
    apt-get)
      SYSTEM_REQUIRED_PACKAGES+=(ca-certificates)
      if ! command -v zsh >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(zsh)
      fi
      if ! command -v git >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(git)
      fi
      if ! command -v curl >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(curl)
      fi

      if ! command -v fzf >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(fzf)
      fi
      if ! command -v rg >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(ripgrep)
      fi
      if ! has_any_command fd fdfind; then
        SYSTEM_OPTIONAL_PACKAGES+=(fd-find)
      fi
      if ! has_any_command eza exa; then
        SYSTEM_OPTIONAL_PACKAGES+=(eza)
      fi
      if ! has_any_command bat batcat; then
        SYSTEM_OPTIONAL_PACKAGES+=(bat)
      fi
      if ! command -v btop >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(btop)
      fi
      if ! command -v lazygit >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(lazygit)
      fi
      if ! command -v tldr >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(tealdeer)
      fi
      ;;
    dnf|yum)
      SYSTEM_REQUIRED_PACKAGES+=(ca-certificates)
      if ! command -v zsh >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(zsh)
      fi
      if ! command -v git >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(git)
      fi
      if ! command -v curl >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(curl)
      fi

      if ! command -v fzf >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(fzf)
      fi
      if ! command -v rg >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(ripgrep)
      fi
      if ! has_any_command fd fdfind; then
        SYSTEM_OPTIONAL_PACKAGES+=(fd-find)
      fi
      if ! has_any_command eza exa; then
        SYSTEM_OPTIONAL_PACKAGES+=(eza)
      fi
      if ! has_any_command bat batcat; then
        SYSTEM_OPTIONAL_PACKAGES+=(bat)
      fi
      if ! command -v btop >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(btop)
      fi
      if ! command -v lazygit >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(lazygit)
      fi
      if ! command -v tldr >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(tealdeer)
      fi
      ;;
    pacman)
      SYSTEM_REQUIRED_PACKAGES+=(ca-certificates)
      if ! command -v zsh >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(zsh)
      fi
      if ! command -v git >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(git)
      fi
      if ! command -v curl >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(curl)
      fi

      if ! command -v fzf >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(fzf)
      fi
      if ! command -v rg >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(ripgrep)
      fi
      if ! has_any_command fd fdfind; then
        SYSTEM_OPTIONAL_PACKAGES+=(fd)
      fi
      if ! has_any_command eza exa; then
        SYSTEM_OPTIONAL_PACKAGES+=(eza)
      fi
      if ! has_any_command bat batcat; then
        SYSTEM_OPTIONAL_PACKAGES+=(bat)
      fi
      if ! command -v btop >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(btop)
      fi
      if ! command -v lazygit >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(lazygit)
      fi
      if ! command -v tldr >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(tealdeer)
      fi
      ;;
    apk)
      SYSTEM_REQUIRED_PACKAGES+=(ca-certificates)
      if ! command -v zsh >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(zsh)
      fi
      if ! command -v git >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(git)
      fi
      if ! command -v curl >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(curl)
      fi

      if ! command -v fzf >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(fzf)
      fi
      if ! command -v rg >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(ripgrep)
      fi
      if ! has_any_command fd fdfind; then
        SYSTEM_OPTIONAL_PACKAGES+=(fd)
      fi
      if ! has_any_command eza exa; then
        SYSTEM_OPTIONAL_PACKAGES+=(eza)
      fi
      if ! has_any_command bat batcat; then
        SYSTEM_OPTIONAL_PACKAGES+=(bat)
      fi
      if ! command -v btop >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(btop)
      fi
      if ! command -v lazygit >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(lazygit)
      fi
      if ! command -v tldr >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(tealdeer)
      fi
      ;;
    zypper)
      SYSTEM_REQUIRED_PACKAGES+=(ca-certificates)
      if ! command -v zsh >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(zsh)
      fi
      if ! command -v git >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(git)
      fi
      if ! command -v curl >/dev/null 2>&1; then
        SYSTEM_REQUIRED_PACKAGES+=(curl)
      fi

      if ! command -v fzf >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(fzf)
      fi
      if ! command -v rg >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(ripgrep)
      fi
      if ! has_any_command fd fdfind; then
        SYSTEM_OPTIONAL_PACKAGES+=(fd)
      fi
      if ! has_any_command eza exa; then
        SYSTEM_OPTIONAL_PACKAGES+=(eza)
      fi
      if ! has_any_command bat batcat; then
        SYSTEM_OPTIONAL_PACKAGES+=(bat)
      fi
      if ! command -v btop >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(btop)
      fi
      if ! command -v lazygit >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(lazygit)
      fi
      if ! command -v tldr >/dev/null 2>&1; then
        SYSTEM_OPTIONAL_PACKAGES+=(tealdeer)
      fi
      ;;
    *)
      die "Unsupported package manager: $manager"
      ;;
  esac

  if ! is_true "$INSTALL_OPTIONAL_TOOLS"; then
    SYSTEM_OPTIONAL_PACKAGES=()
  fi
}

apt_refresh() {
  if (( APT_UPDATE_DONE == 0 )); then
    run_privileged apt-get update || die "apt-get update failed"
    APT_UPDATE_DONE=1
  fi
}

install_apt_packages() {
  local required="$1"
  shift

  local package_name
  local -a available_packages=()

  (($#)) || return 0
  apt_refresh

  for package_name in "$@"; do
    if command -v apt-cache >/dev/null 2>&1 && ! apt-cache show "$package_name" >/dev/null 2>&1; then
      warn "apt package is not available on this distribution: $package_name"
      continue
    fi
    available_packages+=("$package_name")
  done

  if ((${#available_packages[@]} == 0)); then
    if is_true "$required"; then
      die "None of the required apt packages are available"
    fi
    return 0
  fi

  if is_true "$required"; then
    run_privileged apt-get install -y "${available_packages[@]}" ||
      die "Unable to install required packages: ${available_packages[*]}"
  elif ! run_privileged apt-get install -y "${available_packages[@]}"; then
    warn "Some optional apt packages could not be installed; continuing"
  fi
}

rpm_package_available() {
  local manager="$1"
  local package_name="$2"

  "$manager" info "$package_name" >/dev/null 2>&1
}

install_rpm_packages() {
  local manager="$1"
  local required="$2"
  shift 2

  local package_name
  local -a available_packages=()

  (($#)) || return 0
  for package_name in "$@"; do
    if rpm_package_available "$manager" "$package_name"; then
      available_packages+=("$package_name")
    elif is_true "$required"; then
      available_packages+=("$package_name")
    else
      warn "$manager package is not available on this distribution: $package_name"
    fi
  done

  ((${#available_packages[@]})) || return 0
  if is_true "$required"; then
    run_privileged "$manager" install -y "${available_packages[@]}" ||
      die "Unable to install required packages: ${available_packages[*]}"
  elif ! run_privileged "$manager" install -y "${available_packages[@]}"; then
    warn "Some optional $manager packages could not be installed; continuing"
  fi
}

pacman_package_available() {
  pacman -Si "$1" >/dev/null 2>&1
}

run_pacman() {
  if is_msys2_environment; then
    pacman "$@"
  else
    run_privileged pacman "$@"
  fi
}

install_pacman_packages() {
  local required="$1"
  shift

  local package_name
  local -a available_packages=()

  (($#)) || return 0
  for package_name in "$@"; do
    if pacman_package_available "$package_name"; then
      available_packages+=("$package_name")
    elif is_true "$required"; then
      available_packages+=("$package_name")
    else
      warn "pacman package is not available: $package_name"
    fi
  done

  ((${#available_packages[@]})) || return 0
  if is_true "$required"; then
    run_pacman -S --needed --noconfirm "${available_packages[@]}" ||
      die "Unable to install required packages: ${available_packages[*]}"
  elif ! run_pacman -S --needed --noconfirm "${available_packages[@]}"; then
    warn "Some optional pacman packages could not be installed; continuing"
  fi
}

apk_package_available() {
  apk search -e "$1" >/dev/null 2>&1
}

install_apk_packages() {
  local required="$1"
  shift

  local package_name
  local -a available_packages=()

  (($#)) || return 0
  for package_name in "$@"; do
    if apk_package_available "$package_name"; then
      available_packages+=("$package_name")
    elif is_true "$required"; then
      available_packages+=("$package_name")
    else
      warn "apk package is not available: $package_name"
    fi
  done

  ((${#available_packages[@]})) || return 0
  if is_true "$required"; then
    run_privileged apk add --no-cache "${available_packages[@]}" ||
      die "Unable to install required packages: ${available_packages[*]}"
  elif ! run_privileged apk add --no-cache "${available_packages[@]}"; then
    warn "Some optional apk packages could not be installed; continuing"
  fi
}

zypper_package_available() {
  zypper --non-interactive search --match-exact "$1" >/dev/null 2>&1
}

install_zypper_packages() {
  local required="$1"
  shift

  local package_name
  local -a available_packages=()

  (($#)) || return 0
  for package_name in "$@"; do
    if zypper_package_available "$package_name"; then
      available_packages+=("$package_name")
    elif is_true "$required"; then
      available_packages+=("$package_name")
    else
      warn "zypper package is not available: $package_name"
    fi
  done

  ((${#available_packages[@]})) || return 0
  if is_true "$required"; then
    run_privileged zypper --non-interactive install --no-recommends "${available_packages[@]}" ||
      die "Unable to install required packages: ${available_packages[*]}"
  elif ! run_privileged zypper --non-interactive install --no-recommends "${available_packages[@]}"; then
    warn "Some optional zypper packages could not be installed; continuing"
  fi
}

install_brew_packages() {
  local required="$1"
  shift

  (($#)) || return 0
  if is_true "$required"; then
    brew install "$@" || die "Unable to install required Homebrew packages: $*"
  elif ! brew install "$@"; then
    warn "Some optional Homebrew packages could not be installed; continuing"
  fi
}

install_system_packages() {
  local manager="$1"

  build_package_lists "$manager"
  if is_true "$DRY_RUN"; then
    if ((${#SYSTEM_REQUIRED_PACKAGES[@]})); then
      log "Would install required system packages with $manager: ${SYSTEM_REQUIRED_PACKAGES[*]}"
    fi
    if ((${#SYSTEM_OPTIONAL_PACKAGES[@]})); then
      log "Would install optional CLI tools with $manager: ${SYSTEM_OPTIONAL_PACKAGES[*]}"
    fi
    return
  fi

  case "$manager" in
    brew)
      install_brew_packages true "${SYSTEM_REQUIRED_PACKAGES[@]}"
      install_brew_packages false "${SYSTEM_OPTIONAL_PACKAGES[@]}"
      ;;
    apt-get)
      install_apt_packages true "${SYSTEM_REQUIRED_PACKAGES[@]}"
      install_apt_packages false "${SYSTEM_OPTIONAL_PACKAGES[@]}"
      ;;
    dnf|yum)
      install_rpm_packages "$manager" true "${SYSTEM_REQUIRED_PACKAGES[@]}"
      install_rpm_packages "$manager" false "${SYSTEM_OPTIONAL_PACKAGES[@]}"
      ;;
    pacman)
      install_pacman_packages true "${SYSTEM_REQUIRED_PACKAGES[@]}"
      install_pacman_packages false "${SYSTEM_OPTIONAL_PACKAGES[@]}"
      ;;
    apk)
      install_apk_packages true "${SYSTEM_REQUIRED_PACKAGES[@]}"
      install_apk_packages false "${SYSTEM_OPTIONAL_PACKAGES[@]}"
      ;;
    zypper)
      install_zypper_packages true "${SYSTEM_REQUIRED_PACKAGES[@]}"
      install_zypper_packages false "${SYSTEM_OPTIONAL_PACKAGES[@]}"
      ;;
    *)
      die "Unsupported package manager: $manager"
      ;;
  esac
}

ensure_system_dependencies() {
  local manager

  collect_missing_required_commands

  if is_true "$SKIP_DEPENDENCIES" ||
     is_true "$SKIP_SYSTEM_DEPENDENCIES" ||
     ! is_true "$AUTO_INSTALL_SYSTEM"; then
    if ((${#MISSING_REQUIRED_COMMANDS[@]})); then
      die "Missing required commands: ${MISSING_REQUIRED_COMMANDS[*]}; rerun without dependency-skip options"
    fi
    log "Skipping automatic system dependency installation"
    return
  fi

  manager="$(detect_package_manager 2>/dev/null || true)"
  if [[ -z "$manager" ]]; then
    if ((${#MISSING_REQUIRED_COMMANDS[@]})); then
      die "Missing required commands (${MISSING_REQUIRED_COMMANDS[*]}) and no supported package manager was found"
    fi
    warn "No supported package manager found; optional CLI tools will not be installed"
    return
  fi

  log "Checking system dependencies with $manager"
  install_system_packages "$manager"
  hash -r 2>/dev/null || true

  collect_missing_required_commands
  if ((${#MISSING_REQUIRED_COMMANDS[@]})); then
    die "Required commands are still missing after package installation: ${MISSING_REQUIRED_COMMANDS[*]}"
  fi
}

shell_quote() {
  local value="$1"
  value=${value//\'/\'\\\'\'}
  printf "'%s'" "$value"
}

normalize_url() {
  local url="$1"
  url="${url%.git}"
  url="${url%/}"
  printf '%s' "$url"
}

project_url_matches() {
  local actual="$1"
  local expected="$2"

  [[ "$(normalize_url "$actual")" == "$(normalize_url "$expected")" ]] && return 0
  [[ "$(normalize_url "$expected")" == "$(normalize_url "$PROJECT_URL_DEFAULT")" ]] &&
    [[ "$(normalize_url "$actual")" == "$(normalize_url "$LEGACY_PROJECT_URL_DEFAULT")" ]]
}

repo_remote_matches() {
  local target="$1"
  local expected="$2"
  local actual

  actual="$(git -C "$target" config --get remote.origin.url 2>/dev/null || true)"
  [[ -n "$actual" ]] || return 1
  [[ "$(normalize_url "$actual")" == "$(normalize_url "$expected")" ]]
}

detect_local_repo() {
  local script_path="${BASH_SOURCE[0]:-}"
  local script_dir

  case "$script_path" in
    ""|bash|sh|/dev/fd/*|/proc/self/fd/*) return 1 ;;
  esac

  script_dir="$(cd -P "$(dirname "$script_path")" 2>/dev/null && pwd -P)" || return 1
  if [[ -r "$script_dir/home/.zshrc" && -r "$script_dir/home/.zprofile" ]]; then
    printf '%s\n' "$script_dir"
  fi
}

clone_repo_safely() {
  local url="$1"
  local target="$2"
  shift 2

  local parent
  local staging

  parent="$(dirname "$target")"
  mkdir -p "$parent"
  staging="$(mktemp -d "$parent/.zsh-dotfiles-clone.XXXXXX")"

  if git clone "$@" "$url" "$staging/repo"; then
    mv "$staging/repo" "$target"
    rmdir "$staging" 2>/dev/null || true
  else
    rm -rf "$staging"
    return 1
  fi
}

bootstrap_source_checkout() {
  local existing_remote

  require_command git

  if (( ! SOURCE_INSTALL_DIR_EXPLICIT )) &&
     ! path_exists "$SOURCE_INSTALL_DIR" &&
     path_exists "$LEGACY_SOURCE_INSTALL_DIR"; then
    SOURCE_INSTALL_DIR="$LEGACY_SOURCE_INSTALL_DIR"
    log "Using existing legacy source checkout: $SOURCE_INSTALL_DIR"
  fi

  if path_exists "$SOURCE_INSTALL_DIR"; then
    [[ -d "$SOURCE_INSTALL_DIR/.git" && -r "$SOURCE_INSTALL_DIR/home/.zshrc" ]] || die \
      "Install directory exists but is not a canxin-zsh checkout: $SOURCE_INSTALL_DIR"

    existing_remote="$(git -C "$SOURCE_INSTALL_DIR" config --get remote.origin.url 2>/dev/null || true)"
    project_url_matches "$existing_remote" "$REPO_URL" || die \
      "Install directory belongs to a different repository: $SOURCE_INSTALL_DIR"

    REPO_ROOT="$(cd -P "$SOURCE_INSTALL_DIR" && pwd -P)"
    SOURCE_BOOTSTRAPPED=1

    if (( UPDATE_SOURCE )); then
      log "Updating canxin-zsh checkout: $REPO_ROOT"
      git -C "$REPO_ROOT" pull --ff-only
    fi
    return
  fi

  if is_true "$DRY_RUN"; then
    die "--dry-run from a remote installer requires a local checkout; run it from the repository"
  fi

  log "Cloning canxin-zsh into $SOURCE_INSTALL_DIR"
  clone_repo_safely "$REPO_URL" "$SOURCE_INSTALL_DIR" --depth=1 --branch "$PROJECT_REF"
  REPO_ROOT="$(cd -P "$SOURCE_INSTALL_DIR" && pwd -P)"
  SOURCE_BOOTSTRAPPED=1
}

ensure_backup_dir() {
  if [[ -n "$BACKUP_DIR" ]]; then
    return
  fi

  BACKUP_DIR="$HOME/.config/zsh-dotfiles/backups/$(date +%Y%m%d-%H%M%S)"
  if is_true "$DRY_RUN"; then
    log "Would create backup directory: $BACKUP_DIR"
  else
    umask 077
    mkdir -p "$BACKUP_DIR"
  fi
}

backup_file() {
  local file="$1"
  local backup_file_path

  path_exists "$file" || return 0
  ensure_backup_dir
  backup_file_path="$BACKUP_DIR/$(basename "$file")"
  if [[ -e "$backup_file_path" ]]; then
    backup_file_path="$BACKUP_DIR/$(basename "$file").$(date +%s)"
  fi

  if is_true "$DRY_RUN"; then
    log "Would back up $file -> $backup_file_path"
  else
    cp -p "$file" "$backup_file_path"
  fi
}

strip_managed_block() {
  local file="$1"

  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
    $0 == begin { inside = 1; next }
    $0 == end { inside = 0; next }
    !inside { print }
  ' "$file"
}

file_has_user_content() {
  local file="$1"
  local content_file

  path_exists "$file" || return 1
  [[ -r "$file" ]] || die "Cannot read existing zsh config: $file"
  [[ -d "$file" ]] && die "Expected a file but found a directory: $file"

  content_file="$(mktemp "${TMPDIR:-/tmp}/zsh-dotfiles-content.XXXXXX")"
  strip_managed_block "$file" > "$content_file"
  if grep -q '[^[:space:]]' "$content_file"; then
    rm -f "$content_file"
    return 0
  fi

  rm -f "$content_file"
  return 1
}

config_has_omz_source() {
  local file="$1"
  grep -Eiq 'oh-my-zsh[.]sh' "$file"
}

config_has_other_framework() {
  local file="$1"
  grep -Eiq '(^|[^[:alnum:]_])(zinit|zplug|zgen|antigen|zimfw|sheldon|prezto|zcomet)([^[:alnum:]_]|$)' "$file" && return 0
  grep -Eiq '^[[:space:]]*(ZSH_THEME|plugins)[[:space:]]*=' "$file"
}

file_mode() {
  local file="$1"
  local mode

  if mode="$(stat -c '%a' "$file" 2>/dev/null)"; then
    printf '%s' "$mode"
  elif mode="$(stat -f '%Lp' "$file" 2>/dev/null)"; then
    printf '%s' "$mode"
  fi
}

render_managed_block() {
  local kind="$1"
  local source_file="$2"
  local mode="$3"
  local load_local="$4"
  local bootstrap_omz="$5"
  local quoted_source

  quoted_source="$(shell_quote "$source_file")"

  printf '%s\n' "$BEGIN_MARKER"
  printf '# zsh-dotfiles: mode=%s\n' "$mode"
  printf '# zsh-dotfiles: load-local=%s\n' "$load_local"
  printf '# zsh-dotfiles: bootstrap-omz=%s\n' "$bootstrap_omz"
  printf 'typeset -g ZSH_DOTFILES_MODE=%s\n' "$mode"
  printf 'typeset -g ZSH_DOTFILES_BOOTSTRAP_OMZ=%s\n' "$bootstrap_omz"
  printf 'if [[ -r %s ]]; then\n' "$quoted_source"
  printf '  source %s\n' "$quoted_source"
  printf 'fi\n'

  if [[ "$kind" == "zshrc" && "$load_local" == "true" ]]; then
    printf 'if [[ -r "$HOME/.zshrc.local" ]]; then\n'
    printf '  source "$HOME/.zshrc.local"\n'
    printf 'fi\n'
  elif [[ "$kind" == "zprofile" && "$load_local" == "true" ]]; then
    printf 'if [[ -r "$HOME/.zprofile.local" ]]; then\n'
    printf '  source "$HOME/.zprofile.local"\n'
    printf 'fi\n'
  fi

  printf '%s\n' "$END_MARKER"
}

install_managed_block() {
  local file="$1"
  local source_file="$2"
  local kind="$3"
  local mode="$4"
  local load_local="$5"
  local bootstrap_omz="$6"
  local content_file
  local mode_before
  local source_is_destination=0

  if is_true "$DRY_RUN"; then
    log "Would maintain managed block in $file"
    return
  fi

  [[ -r "$source_file" ]] || die "Missing tracked source file: $source_file"
  [[ ! -d "$file" ]] || die "Expected a file but found a directory: $file"

  content_file="$(mktemp "${file}.zsh-dotfiles.XXXXXX")"
  if is_symlink "$file" && symlink_points_to "$file" "$source_file"; then
    source_is_destination=1
    # The old installer could make ~/.zshrc or ~/.zprofile point directly at
    # the tracked source file. Detach that special case so the managed block
    # cannot source the file that is currently sourcing it.
    : > "$content_file"
  elif path_exists "$file"; then
    strip_managed_block "$file" > "$content_file"
  else
    : > "$content_file"
  fi

  if [[ -s "$content_file" ]]; then
    printf '\n' >> "$content_file"
  fi
  render_managed_block "$kind" "$source_file" "$mode" "$load_local" "$bootstrap_omz" >> "$content_file"

  if path_exists "$file" && cmp -s "$content_file" "$file"; then
    rm -f "$content_file"
    log "Already up to date: $file"
    return
  fi

  backup_file "$file"
  mode_before=""
  if [[ -f "$file" ]] && ! is_symlink "$file"; then
    mode_before="$(file_mode "$file")"
  fi

  if is_symlink "$file"; then
    if (( source_is_destination )); then
      warn "$file points to the tracked source; replacing only this self-link with a managed file"
      mv "$content_file" "$file"
    else
      warn "$file is a symlink; updating its target in place"
      cat "$content_file" > "$file"
      rm -f "$content_file"
    fi
  else
    mv "$content_file" "$file"
    if [[ -n "$mode_before" ]]; then
      chmod "$mode_before" "$file"
    fi
  fi

  log "Updated managed block: $file"
}

choose_zshrc_settings() {
  local file="$1"

  ZSHRC_MODE="integrate"
  ZSHRC_LOAD_LOCAL="false"
  ZSHRC_BOOTSTRAP_OMZ="true"

  if ! file_has_user_content "$file"; then
    ZSHRC_MODE="bootstrap"
    ZSHRC_LOAD_LOCAL="true"
    return
  fi

  if path_exists "$file" && grep -Eq '^# zsh-dotfiles: load-local=true$' "$file"; then
    ZSHRC_LOAD_LOCAL="true"
  fi

  if config_has_other_framework "$file" && ! config_has_omz_source "$file"; then
    ZSHRC_BOOTSTRAP_OMZ="false"
  fi
}

choose_zprofile_settings() {
  local file="$1"

  ZPROFILE_MODE="integrate"
  ZPROFILE_LOAD_LOCAL="false"

  if ! file_has_user_content "$file"; then
    ZPROFILE_MODE="bootstrap"
    ZPROFILE_LOAD_LOCAL="true"
    return
  fi

  if path_exists "$file" && grep -Eq '^# zsh-dotfiles: load-local=true$' "$file"; then
    ZPROFILE_LOAD_LOCAL="true"
  fi
}

configure_shell_files() {
  local zshrc_file="$ZDOTDIR_ROOT/.zshrc"
  local zprofile_file="$ZDOTDIR_ROOT/.zprofile"

  if is_true "$DRY_RUN"; then
    log "Would ensure zsh config directory exists: $ZDOTDIR_ROOT"
  else
    mkdir -p "$ZDOTDIR_ROOT"
  fi

  choose_zshrc_settings "$zshrc_file"
  choose_zprofile_settings "$zprofile_file"

  install_managed_block \
    "$zshrc_file" \
    "$REPO_ROOT/home/.zshrc" \
    "zshrc" \
    "$ZSHRC_MODE" \
    "$ZSHRC_LOAD_LOCAL" \
    "$ZSHRC_BOOTSTRAP_OMZ"

  install_managed_block \
    "$zprofile_file" \
    "$REPO_ROOT/home/.zprofile" \
    "zprofile" \
    "$ZPROFILE_MODE" \
    "$ZPROFILE_LOAD_LOCAL" \
    "false"
}

install_git_repo() {
  local label="$1"
  local target="$2"
  local url="$3"
  local kind="$4"

  if is_true "$DRY_RUN"; then
    if path_exists "$target"; then
      log "Would inspect existing $label: $target"
    else
      log "Would clone $label -> $target"
    fi
    return
  fi

  if [[ -d "$target/.git" ]]; then
    if repo_remote_matches "$target" "$url"; then
      if (( UPDATE_EXISTING )); then
        log "Updating $label: $target"
        git -C "$target" pull --ff-only
      else
        log "Keeping existing checkout: $target"
      fi
    else
      warn "Keeping existing checkout with a different remote: $target"
    fi
    return
  fi

  if path_exists "$target"; then
    if [[ "$kind" == "oh-my-zsh" && -r "$target/oh-my-zsh.sh" ]]; then
      log "Keeping existing Oh My Zsh installation: $target"
      return
    fi
    if [[ "$kind" == "plugin" && -d "$target" ]]; then
      log "Keeping existing plugin/theme directory: $target"
      return
    fi
    die "Refusing to replace an existing path: $target"
  fi

  log "Cloning $label -> $target"
  clone_repo_safely "$url" "$target" --depth=1
}

install_dependencies() {
  local oh_my_zsh_dir
  local zsh_custom_dir
  local index
  local rel
  local url
  local target

  if is_true "$SKIP_DEPENDENCIES"; then
    log "Skipping Oh My Zsh/plugin installation"
    return
  fi

  require_command git
  oh_my_zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
  zsh_custom_dir="${ZSH_CUSTOM:-$oh_my_zsh_dir/custom}"

  install_git_repo "Oh My Zsh" "$oh_my_zsh_dir" "$OH_MY_ZSH_REPO" "oh-my-zsh"
  if is_true "$DRY_RUN"; then
    log "Would ensure custom plugin directory exists: $zsh_custom_dir"
  else
    mkdir -p "$zsh_custom_dir"
  fi

  for index in "${!PLUGIN_RELS[@]}"; do
    rel="${PLUGIN_RELS[$index]}"
    url="${PLUGIN_URLS[$index]}"
    target="$zsh_custom_dir/$rel"
    install_git_repo "$rel" "$target" "$url" "plugin"
  done
}

parse_args() {
  while (($#)); do
    case "$1" in
      --update)
        UPDATE_EXISTING=1
        ;;
      --update-source)
        UPDATE_SOURCE=1
        ;;
      --skip-dependencies|--no-dependencies)
        SKIP_DEPENDENCIES=1
        ;;
      --no-system-dependencies)
        SKIP_SYSTEM_DEPENDENCIES=1
        ;;
      --no-optional-tools)
        INSTALL_OPTIONAL_TOOLS=0
        ;;
      --install-dir)
        shift
        (($#)) || die "--install-dir requires a value"
        SOURCE_INSTALL_DIR="$1"
        SOURCE_INSTALL_DIR_EXPLICIT=1
        ;;
      --repo-url)
        shift
        (($#)) || die "--repo-url requires a value"
        REPO_URL="$1"
        ;;
      --ref)
        shift
        (($#)) || die "--ref requires a value"
        PROJECT_REF="$1"
        ;;
      --dry-run)
        DRY_RUN=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        usage >&2
        die "Unknown argument: $1"
        ;;
    esac
    shift
  done
}

main() {
  local local_root

  parse_args "$@"
  require_command bash
  ensure_system_dependencies
  require_command zsh
  require_command git

  local_root="$(detect_local_repo || true)"
  if [[ -n "$local_root" ]]; then
    REPO_ROOT="$local_root"
  else
    bootstrap_source_checkout
  fi

  log "Platform: $(detect_platform)"
  log "Source root: $REPO_ROOT"
  log "Config directory: $ZDOTDIR_ROOT"

  install_dependencies
  configure_shell_files

  if [[ "$SOURCE_BOOTSTRAPPED" == "1" && "$UPDATE_SOURCE" == "0" ]]; then
    log "Source checkout is managed at $REPO_ROOT; use --update-source to update it"
  fi
  log "Install complete. Start a new shell or run: exec zsh"
}

main "$@"
