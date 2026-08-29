#!/usr/bin/env bash

# shellcheck disable=SC2016
# Single-quoted strings intentionally pass literal zsh snippets to a child shell.

set -euo pipefail

TEST_ROOT="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
INSTALLER="$TEST_ROOT/install.sh"

fail() {
  printf 'test failure: %s\n' "$*" >&2
  exit 1
}

assert_file_contains() {
  local file="$1"
  local text="$2"
  grep -Fq "$text" "$file" || fail "$file does not contain: $text"
}

assert_count() {
  local file="$1"
  local text="$2"
  local expected="$3"
  local actual

  actual="$(grep -Foc "$text" "$file" || true)"
  [[ "$actual" == "$expected" ]] || fail "$file contains '$text' $actual times, expected $expected"
}

run_installer() {
  local home_dir="$1"
  shift

  env \
    -u ZSH \
    -u ZSH_CUSTOM \
    -u ZSH_THEME \
    -u FPATH \
    HOME="$home_dir" \
    ZDOTDIR="$home_dir" \
    XDG_CONFIG_HOME="$home_dir/.config" \
    ZSH_DOTFILES_SKIP_DEPENDENCIES=1 \
    "$INSTALLER" "$@"
}

run_test_zsh() {
  local home_dir="$1"
  shift

  env \
    -u ZSH \
    -u ZSH_CUSTOM \
    -u ZSH_THEME \
    -u FPATH \
    HOME="$home_dir" \
    ZDOTDIR="$home_dir" \
    zsh "$@"
}

new_home() {
  mktemp -d "${TMPDIR:-/tmp}/zsh-dotfiles-test.XXXXXX"
}

TEST_HOMES=()
cleanup() {
  local home_dir
  for home_dir in "${TEST_HOMES[@]}"; do
    rm -rf "$home_dir"
  done
}
trap cleanup EXIT

test_fresh_install() {
  local home_dir
  home_dir="$(new_home)"
  TEST_HOMES+=("$home_dir")

  printf 'typeset -g TEST_ZSHRC_LOCAL=loaded\n' > "$home_dir/.zshrc.local"
  printf 'typeset -g TEST_ZPROFILE_LOCAL=loaded\n' > "$home_dir/.zprofile.local"

  run_installer "$home_dir"

  [[ -f "$home_dir/.zshrc" ]] || fail "fresh install did not create .zshrc"
  [[ -f "$home_dir/.zprofile" ]] || fail "fresh install did not create .zprofile"
  assert_count "$home_dir/.zshrc" '# >>> zsh-dotfiles managed block >>>' 1
  assert_count "$home_dir/.zprofile" '# >>> zsh-dotfiles managed block >>>' 1
  assert_file_contains "$home_dir/.zshrc" 'load-local=true'
  assert_file_contains "$home_dir/.zprofile" 'load-local=true'

  run_test_zsh "$home_dir" -d -i -c '
    [[ "$TEST_ZSHRC_LOCAL" == loaded ]]
    [[ "$TEST_ZPROFILE_LOCAL" != loaded ]]
  '

  run_test_zsh "$home_dir" -d -c '
    source "$ZDOTDIR/.zprofile"
    [[ "$TEST_ZPROFILE_LOCAL" == loaded ]]
  '

  run_installer "$home_dir"
  assert_count "$home_dir/.zshrc" '# >>> zsh-dotfiles managed block >>>' 1
  assert_count "$home_dir/.zprofile" '# >>> zsh-dotfiles managed block >>>' 1
}

test_existing_config_is_preserved() {
  local home_dir
  local original_line
  home_dir="$(new_home)"
  TEST_HOMES+=("$home_dir")

  printf '%s\n' \
    '# user configuration' \
    'typeset -g TEST_USER_CONFIG=preserved' \
    "alias grep='command grep'" > "$home_dir/.zshrc"
  printf '%s\n' \
    '# user login configuration' \
    'typeset -g TEST_USER_PROFILE=preserved' > "$home_dir/.zprofile"
  original_line="$(grep -F 'TEST_USER_CONFIG' "$home_dir/.zshrc")"

  run_installer "$home_dir"

  assert_file_contains "$home_dir/.zshrc" "$original_line"
  assert_file_contains "$home_dir/.zprofile" 'TEST_USER_PROFILE=preserved'
  assert_file_contains "$home_dir/.zshrc" 'load-local=false'
  assert_file_contains "$home_dir/.zshrc" 'mode=integrate'
  assert_count "$home_dir/.zshrc" '# >>> zsh-dotfiles managed block >>>' 1

  run_test_zsh "$home_dir" -d -i -c '
    [[ "$TEST_USER_CONFIG" == preserved ]]
    [[ "${aliases[grep]}" == "command grep" ]]
    [[ -z "${TEST_ZSHRC_LOCAL:-}" ]]
  '

  run_installer "$home_dir"
  assert_count "$home_dir/.zshrc" '# >>> zsh-dotfiles managed block >>>' 1
  assert_file_contains "$home_dir/.zshrc" "$original_line"
}

test_existing_omz_is_not_reloaded() {
  local home_dir
  home_dir="$(new_home)"
  TEST_HOMES+=("$home_dir")

  mkdir -p "$home_dir/.oh-my-zsh"
  printf '%s\n' \
    'typeset -g TEST_OMZ_SOURCE_COUNT=1' \
    'omz() { :; }' > "$home_dir/.oh-my-zsh/oh-my-zsh.sh"
  printf '%s\n' \
    'ZSH="$HOME/.oh-my-zsh"' \
    'ZSH_THEME=robbyrussell' \
    'plugins=(git)' \
    'source "$ZSH/oh-my-zsh.sh"' > "$home_dir/.zshrc"

  run_installer "$home_dir"

  assert_file_contains "$home_dir/.zshrc" 'bootstrap-omz=true'
  run_test_zsh "$home_dir" -d -i -c '
    [[ "$TEST_OMZ_SOURCE_COUNT" == 1 ]]
    [[ "$ZSH_THEME" == robbyrussell ]]
    [[ -z "${POWERLEVEL9K_CONFIG_FILE:-}" ]]
  '
}

test_other_framework_is_not_bootstrapped() {
  local home_dir
  home_dir="$(new_home)"
  TEST_HOMES+=("$home_dir")

  printf '%s\n' \
    '# Existing framework' \
    '# zinit is managed by the existing user configuration' > "$home_dir/.zshrc"

  run_installer "$home_dir"

  assert_file_contains "$home_dir/.zshrc" 'bootstrap-omz=false'
  run_test_zsh "$home_dir" -d -c '
    source "$ZDOTDIR/.zshrc"
    [[ -z "${ZSH:-}" ]]
  '
}

test_symlink_target_is_preserved() {
  local home_dir
  local config_target
  home_dir="$(new_home)"
  TEST_HOMES+=("$home_dir")
  config_target="$home_dir/configs/zshrc"

  mkdir -p "$(dirname "$config_target")"
  printf '%s\n' 'typeset -g TEST_SYMLINK_CONFIG=preserved' > "$config_target"
  ln -s "$config_target" "$home_dir/.zshrc"

  run_installer "$home_dir"

  [[ -L "$home_dir/.zshrc" ]] || fail "installer replaced the existing .zshrc symlink"
  assert_file_contains "$config_target" 'TEST_SYMLINK_CONFIG=preserved'
  assert_count "$config_target" '# >>> zsh-dotfiles managed block >>>' 1
}

test_symlink_to_tracked_source_is_detached() {
  local home_dir
  local source_file
  home_dir="$(new_home)"
  TEST_HOMES+=("$home_dir")
  source_file="$TEST_ROOT/home/.zshrc"

  ln -s "$source_file" "$home_dir/.zshrc"

  run_installer "$home_dir"

  [[ ! -L "$home_dir/.zshrc" ]] || fail "installer kept a self-referential .zshrc symlink"
  assert_file_contains "$home_dir/.zshrc" "$source_file"
  assert_count "$home_dir/.zshrc" '# >>> zsh-dotfiles managed block >>>' 1
  assert_count "$source_file" '# >>> zsh-dotfiles managed block >>>' 0

  run_test_zsh "$home_dir" -d -c '
    source "$ZDOTDIR/.zshrc"
    [[ "$ZSH_DOTFILES_ROOT" == */zsh-dotfiles ]]
  '
}

test_existing_p10k_config_is_not_overridden() {
  local home_dir
  home_dir="$(new_home)"
  TEST_HOMES+=("$home_dir")

  printf '%s\n' \
    'ZSH_THEME=powerlevel10k' \
    'source "$HOME/.p10k.zsh"' > "$home_dir/.zshrc"
  printf '%s\n' \
    'typeset -g TEST_USER_P10K=loaded' \
    'typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(user)' \
    'typeset -g POWERLEVEL9K_CONFIG_FILE="$HOME/.p10k.zsh"' > "$home_dir/.p10k.zsh"

  run_installer "$home_dir"

  run_test_zsh "$home_dir" -d -c '
    source "$ZDOTDIR/.zshrc"
    [[ "$TEST_USER_P10K" == loaded ]]
    [[ "${POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[1]}" == user ]]
  '
}

test_dry_run_does_not_write() {
  local home_dir
  home_dir="$(new_home)"
  TEST_HOMES+=("$home_dir")

  env \
    -u ZSH \
    -u ZSH_CUSTOM \
    -u ZSH_THEME \
    -u FPATH \
    HOME="$home_dir" \
    ZDOTDIR="$home_dir" \
    ZSH_DOTFILES_SKIP_DEPENDENCIES=0 \
    "$INSTALLER" --dry-run

  [[ ! -e "$home_dir/.zshrc" ]] || fail "dry-run created .zshrc"
  [[ ! -e "$home_dir/.zprofile" ]] || fail "dry-run created .zprofile"
  [[ ! -e "$home_dir/.oh-my-zsh" ]] || fail "dry-run created an Oh My Zsh directory"
}

test_remote_bootstrap() {
  local home_dir
  local bare_repo
  local fixture_repo
  local remote_installer
  local source_root

  home_dir="$(new_home)"
  TEST_HOMES+=("$home_dir")
  bare_repo="$home_dir/remote.git"
  fixture_repo="$home_dir/fixture"
  remote_installer="$home_dir/remote-install.sh"

  mkdir -p "$fixture_repo/home" "$fixture_repo/bin" "$fixture_repo/zsh/rc"
  cp "$TEST_ROOT/.gitignore" "$fixture_repo/.gitignore"
  cp "$TEST_ROOT/README.md" "$fixture_repo/README.md"
  cp "$TEST_ROOT/install.sh" "$fixture_repo/install.sh"
  cp "$TEST_ROOT/install.ps1" "$fixture_repo/install.ps1"
  cp "$TEST_ROOT/home/.p10k.zsh" "$fixture_repo/home/.p10k.zsh"
  cp "$TEST_ROOT/home/.zprofile" "$fixture_repo/home/.zprofile"
  cp "$TEST_ROOT/home/.zshrc" "$fixture_repo/home/.zshrc"
  cp "$TEST_ROOT/bin/zsh-doctor" "$fixture_repo/bin/zsh-doctor"
  cp "$TEST_ROOT/zsh/rc/common.zsh" "$fixture_repo/zsh/rc/common.zsh"
  git -C "$fixture_repo" init -q
  git -C "$fixture_repo" config user.name test
  git -C "$fixture_repo" config user.email test@example.invalid
  git -C "$fixture_repo" add .
  git -C "$fixture_repo" commit -qm fixture
  git -C "$fixture_repo" branch -M main
  git clone --bare "$fixture_repo" "$bare_repo" >/dev/null
  cp "$INSTALLER" "$remote_installer"
  chmod +x "$remote_installer"

  env \
    -u ZSH \
    -u ZSH_CUSTOM \
    -u ZSH_THEME \
    HOME="$home_dir" \
    ZDOTDIR="$home_dir" \
    ZSH_DOTFILES_SKIP_DEPENDENCIES=1 \
    "$remote_installer" \
      --repo-url "$bare_repo" \
      --ref main \
      --install-dir "$home_dir/source with spaces"

  [[ -r "$home_dir/source with spaces/home/.zshrc" ]] || fail "remote bootstrap did not clone the source checkout"
  [[ -f "$home_dir/.zshrc" ]] || fail "remote bootstrap did not configure .zshrc"
  source_root="$(cd -P "$home_dir/source with spaces" && pwd -P)"
  assert_file_contains "$home_dir/.zshrc" "$source_root/home/.zshrc"
  run_test_zsh "$home_dir" -d -c '
    source "$ZDOTDIR/.zshrc"
    [[ "$ZSH_DOTFILES_ROOT" == */source\ with\ spaces ]]
  '
}

bash -n "$INSTALLER"
for zsh_file in \
  "$TEST_ROOT/home/.zprofile" \
  "$TEST_ROOT/home/.zshrc" \
  "$TEST_ROOT/home/.p10k.zsh" \
  "$TEST_ROOT/zsh/rc/common.zsh"; do
  zsh -n "$zsh_file"
done

test_fresh_install
test_existing_config_is_preserved
test_existing_omz_is_not_reloaded
test_other_framework_is_not_bootstrapped
test_symlink_target_is_preserved
test_symlink_to_tracked_source_is_detached
test_existing_p10k_config_is_not_overridden
test_dry_run_does_not_write
test_remote_bootstrap

printf '%s\n' 'all installer tests passed'
