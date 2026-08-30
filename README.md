# canxin-zsh

[![Tests](https://github.com/canxin121/canxin-zsh/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/canxin121/canxin-zsh/actions/workflows/test.yml)

一套可以在 macOS、Linux、WSL、MSYS2 和 Cygwin 之间复用的 zsh 配置与安装器。

`canxin-zsh` 把常用的 shell 能力放在一起：

- Oh My Zsh、Powerlevel10k 和常用插件；
- `fzf`、`ripgrep`、`fd`、`eza`、`bat` 等命令行工具；
- 一组常用 alias、历史记录、补全和交互式快捷键；
- 一个会识别现有配置、尽量避免覆盖用户设置的跨平台安装器。

它适合想在多台机器上快速得到相近 zsh 工作环境的人。它不是完整的操作系统配置管理器，也不会强行接管已经由其他 zsh 框架管理的配置；原生 Windows PowerShell 本身也不提供 zsh，需要先使用 WSL、MSYS2 或 Cygwin。

## 快速安装

### macOS、Linux、WSL、MSYS2

在对应的终端执行：

```bash
curl -fsSL https://raw.githubusercontent.com/canxin121/canxin-zsh/main/install.sh | bash
```

脚本会自动检查并尝试补齐 `zsh`、`git`、`curl`、CA 证书和默认工具集。执行远程命令本身需要当前环境已经有 `curl` 和 `bash`；如果没有，可以先克隆仓库，或通过下方的 PowerShell 转发方式下载脚本。

也可以使用本地 checkout：

```bash
git clone https://github.com/canxin121/canxin-zsh.git
cd canxin-zsh
./install.sh
```

### Windows PowerShell

PowerShell 只负责下载并转发安装脚本，实际安装会发生在 WSL、MSYS2 或 Cygwin 中：

```powershell
irm https://raw.githubusercontent.com/canxin121/canxin-zsh/main/install.ps1 | iex
```

`install.ps1` 会优先使用 `wsl.exe`，其次使用 `bash.exe`。因此，通过 WSL 或 MSYS2 转发时不要求目标环境预先安装 `curl`；目标环境仍然需要有可用的 zsh 运行环境。这个命令不会自动安装 WSL，也不会让原生 PowerShell 变成 zsh。

安装完成后，重新打开终端，或运行：

```bash
exec zsh
```

## 安装后有什么

安装完成后，得到的不只是几个配置文件，而是一套可以直接使用的交互式 zsh 环境。普通的全量安装、且原来的 zsh 配置为空时，主要功能包括：

| 功能 | 安装后可以做什么 |
| --- | --- |
| Prompt 与主题 | 默认使用 Powerlevel10k，提示符会显示当前目录、Git 分支和工作区状态等信息。 |
| Oh My Zsh | 启用 `git`、`colored-man-pages`、`dirhistory`、`extract`、`sudo` 等常用插件。 |
| 补全与交互 | 使用 `zsh-completions`、`fzf-tab`，让 Tab 补全更丰富，并可在候选项之间交互选择。 |
| 历史记录 | 默认保留最多 50,000 条历史，支持增量写入、跨 shell 共享和去重。 |
| 历史搜索 | `zsh-history-substring-search` 可用时，按上下方向键搜索包含当前输入内容的历史命令。 |
| 命令建议与高亮 | `zsh-autosuggestions` 提供历史命令建议，`zsh-syntax-highlighting` 对输入命令进行语法高亮。 |
| fzf 工作流 | 安装 `fzf` 后，文件搜索、目录切换、补全预览和常用快捷键会自动接入；没有 `fd` 时会退回系统 `find`。 |
| 目录导航 | 支持直接输入目录名进入目录、目录栈和重复目录不入栈等常用行为。 |

此外，安装器会准备 `fzf-tab`、`zsh-autosuggestions`、`zsh-completions`、`zsh-history-substring-search` 和 `zsh-syntax-highlighting`。如果你使用的是全新配置，`Ctrl-E` 可以用编辑器打开当前命令；上下方向键会优先进行历史子串搜索。已有非空配置不会被强行改写这些快捷键。

默认会提供下面这些不容易记错的快捷命令。它们只会在同名 alias 或 function 尚未存在时定义，因此不会主动覆盖用户自己的命令：

```zsh
l / ls       # 使用 eza/exa 列目录；没有时保留系统 ls
ll           # 详细列出文件、隐藏文件和 Git 状态
la           # 列出隐藏文件
lt           # 树状列出目录
catp FILE    # 使用 bat/batcat 分页并高亮查看文件
grep TEXT    # 如果安装了 ripgrep，则使用 rg
top          # 如果安装了 btop，则使用 btop
lg            # 如果安装了 lazygit，则启动 lazygit
zreload      # 重新加载 ~/.zshrc
zupdate-all  # 更新 Oh My Zsh、插件/主题 checkout 和可用的工具
```

`eza`、`fd`、`bat` 等工具在不同系统上可能使用不同命令名，配置会自动识别 `eza/exa`、`fd/fdfind` 和 `bat/batcat`。某个增强工具不可用时，基础 shell、普通 `ls`、系统 `find` 等仍然可以工作。

如果已有非空的 `.zshrc` 或其他 zsh 框架，安装器会进入兼容集成模式：保留已有主题、插件、历史选项、补全样式和快捷键，不强行启动 Oh My Zsh；项目仍会接入能安全提供的工具检测、alias 和更新函数。具体保护规则见下方的[与已有 zsh / Oh My Zsh 配置的关系](#与已有-zsh--oh-my-zsh-配置的关系)。

## 支持的平台与边界

| 环境 | 状态 | 说明 |
| --- | --- | --- |
| macOS | 支持 | 优先使用系统已有命令；如果安装了 Homebrew，安装器也会用它补齐工具集。 |
| Debian / Ubuntu / WSL | 支持 | 使用 `apt-get`，会自动安装缺少的系统依赖和默认工具集。 |
| Fedora / RHEL | 支持 | 使用 `dnf` 或 `yum`。 |
| Arch Linux | 支持 | 使用 `pacman`。 |
| Alpine Linux | 支持 | 使用 `apk`。 |
| openSUSE | 支持 | 使用 `zypper`。 |
| MSYS2 | 支持 | 使用 MSYS2 的 `pacman`，建议从 MSYS2 终端运行。 |
| Cygwin | 支持但需要预先准备 | 请先用 Cygwin 安装器选择 `git`、`curl` 和 `zsh`；Cygwin 的系统包由其安装器维护，本项目不会替代它。 |
| 原生 Windows PowerShell | 不作为 zsh 运行环境 | 请先安装并进入 WSL、MSYS2 或 Cygwin。 |
| 单独的 Git Bash | 通常不支持 | Git Bash 一般没有 zsh；它可以作为下载工具，但不能代替 zsh 运行环境。 |

macOS 通常自带 zsh 和 curl，git 可能需要先安装 Xcode Command Line Tools。没有 Homebrew 时，安装器不会静默安装 Homebrew；默认工具集中无法通过系统包管理器补齐的项目会给出警告并继续完成 shell 配置。Cygwin 也可能需要手动安装默认工具集。

## 安装器会做什么

默认情况下，安装器按下面的顺序工作：

1. 检查当前平台、`bash`、`zsh`、`git` 和 `curl`。
2. 使用当前平台可用的包管理器安装缺少的系统依赖和默认工具集。
3. 如果缺少 Oh My Zsh，则安装到 `$ZSH`，或默认的 `~/.oh-my-zsh`。
4. 如果缺少本项目使用的插件和 Powerlevel10k，则安装到 `$ZSH_CUSTOM`，或默认的 `~/.oh-my-zsh/custom`。
5. 将仓库 source checkout 放在 `${XDG_DATA_HOME:-$HOME/.local/share}/canxin-zsh`，远程安装时从这里加载配置。
6. 在 zsh 配置文件末尾维护一个可重复更新的 managed block。

远程安装默认使用：

```text
${XDG_DATA_HOME:-$HOME/.local/share}/canxin-zsh
```

如果检测到旧版本的 `${XDG_DATA_HOME:-$HOME/.local/share}/zsh-dotfiles` checkout，安装器会继续复用它，避免重复下载。使用本地 checkout 运行 `./install.sh` 时，则直接使用当前目录作为配置源。

缺少的依赖和 checkout 才会尝试安装或 clone。已有的 Oh My Zsh、插件和主题目录不会被仓库内容直接覆盖；已有的 Git checkout 只有在远程地址匹配且显式使用 `--update` 时才会拉取更新。指向其他远程仓库的 checkout 会保留原样。

## 默认工具集

这些工具会在普通安装中自动尝试安装。它们属于安装器的默认工具集，而不是需要用户逐个选择的一长串安装选项；只有需要更轻量安装时才使用 `--minimal`。

| 命令 | 用途 | 常见软件包名 |
| --- | --- | --- |
| `fzf` | 模糊搜索和交互式选择 | `fzf` |
| `rg` | 更快的文本搜索 | `ripgrep` |
| `fd` / `fdfind` | 更方便的文件查找 | `fd` 或 `fd-find` |
| `eza` / `exa` | 增强版目录列表 | `eza` |
| `bat` / `batcat` | 带高亮和分页的文件查看 | `bat` |
| `btop` | 交互式系统监控 | `btop` |
| `lazygit` | Git 终端界面 | `lazygit` |
| `tldr` | 简短的命令示例 | `tealdeer` |

不同发行版的包名和仓库内容不完全一致。因此，某个默认工具无法找到对应包，或单个工具安装失败时，安装器只会警告并继续；zsh 配置会自动检测可用命令，并在没有 `eza`、`fd` 或 `bat` 时使用兼容命令或跳过相应增强功能。必需的 `zsh`、`git`、`curl` 如果安装后仍缺失，则安装会停止。

## 与已有 zsh / Oh My Zsh 配置的关系

安装器不会用仓库里的文件整体替换 `~/.zshrc`、`~/.zprofile` 或 `~/.p10k.zsh`。它只在 `~/.zshrc` 和 `~/.zprofile`（或者 `$ZDOTDIR` 指定的配置目录）中维护自己的区块：

```zsh
# >>> zsh-dotfiles managed block >>>
...
# <<< zsh-dotfiles managed block <<<
```

marker 仍然使用历史名称 `zsh-dotfiles` 是有意的：这样旧版本已经安装的 managed block 可以被新版本识别和更新，不会因为仓库改名而重复加载配置。

不同场景下的行为如下：

| 现有状态 | 安装器行为 |
| --- | --- |
| 没有 zsh 配置，或配置为空 | 初始化 Oh My Zsh、Powerlevel10k、项目插件和默认 shell 设置。 |
| 已有非空 `~/.zshrc` / `~/.zprofile` | 保留原文件内容，在末尾接入项目 managed block；不会把仓库文件整体覆盖过去。 |
| 已经加载 Oh My Zsh | 不重复加载 Oh My Zsh，不重设已有的 `ZSH_THEME` 和 `plugins`。缺少的插件目录可以安装，但不会擅自改用户的插件列表。 |
| 使用 zinit、zplug、zgen、antigen、zimfw、sheldon、prezto、zcomet 等框架 | 检测到其他框架且没有 Oh My Zsh source 时，不会再启动 Oh My Zsh；已有框架继续负责配置。 |
| 已有 alias 或 function | 项目提供的 alias 只在同名项目尚不存在时定义，不主动覆盖用户定义。 |
| 已有 Powerlevel10k 配置 | 保留可读的 `~/.p10k.zsh` 或 `POWERLEVEL9K_CONFIG_FILE`；不会覆盖用户的 p10k 文件。 |
| `~/.zshrc` / `~/.zprofile` 是普通 symlink | 保留 symlink，并更新它指向的目标文件。 |
| symlink 直接指向仓库的 `home/.zshrc` 或 `home/.zprofile` | 安全地解除这个自引用 symlink，改为独立的 managed 配置文件，避免递归 source。 |

修改已有配置前，安装器会在下面的位置创建权限较严格的备份：

```text
~/.config/zsh-dotfiles/backups/
```

空配置时，`~/.zshrc.local` 和 `~/.zprofile.local` 会作为本机覆盖文件自动加载。对于已有非空配置，安装器默认不额外插入 local 文件的加载语句，以免改变用户原本的加载顺序；需要时可以在自己的配置中显式 source 它们。`*.local` 不应提交到仓库。

## 常用选项

大多数用户只需要直接运行无参数安装。需要改变行为时，常用选项如下：

```bash
./install.sh --minimal                 # 安装基础依赖，但跳过默认工具集
./install.sh --update                  # 更新匹配的 Oh My Zsh、插件和主题 checkout
./install.sh --update-source           # 更新远程安装管理的 canxin-zsh source checkout
./install.sh --skip-dependencies       # 不安装系统依赖、Oh My Zsh、插件和主题
./install.sh --no-system-dependencies  # 不调用系统包管理器，但仍可安装 Oh My Zsh/插件
./install.sh --dry-run                 # 只显示计划，不写配置；需在本地 checkout 中运行
```

注意：`--skip-dependencies`、`--no-system-dependencies` 和 `--minimal` 都不会卸载已有软件。跳过基础依赖安装时，`zsh`、`git` 和 `curl` 必须已经存在，否则安装器会直接报错。

远程安装需要自定义位置或分支时，可以把参数传给管道中的安装器：

```bash
curl -fsSL https://raw.githubusercontent.com/canxin121/canxin-zsh/main/install.sh |
  bash -s -- --install-dir "$HOME/.local/share/canxin-zsh" --ref main
```

在本地 checkout 中运行时，控制依赖和工具集的环境变量包括：

```bash
ZSH_DOTFILES_SKIP_DEPENDENCIES=1 ./install.sh
ZSH_DOTFILES_AUTO_INSTALL=0 ./install.sh
ZSH_DOTFILES_INSTALL_TOOLSET=0 ./install.sh
```

旧版本的 `--no-optional-tools` 和 `ZSH_DOTFILES_INSTALL_OPTIONAL_TOOLS=0` 仍作为兼容别名保留；新配置建议使用 `--minimal` 或 `ZSH_DOTFILES_INSTALL_TOOLSET=0`。

## 安装后检查与更新

在本地 checkout 中运行诊断工具：

```bash
bin/zsh-doctor
```

远程安装则运行：

```bash
"${XDG_DATA_HOME:-$HOME/.local/share}/canxin-zsh/bin/zsh-doctor"
```

它会检查 zsh、Git、默认工具集以及可选的 `code` 命令是否可用。缺少某个增强工具不会让 shell 失效。如果安装器复用了历史的 `~/.local/share/zsh-dotfiles` 目录，请把上面命令中的 `canxin-zsh` 换成 `zsh-dotfiles`。

zsh 配置加载后可以使用：

```zsh
zupdate-all
```

它会尝试更新 Oh My Zsh 和 `$ZSH_CUSTOM` 下的 Git 插件/主题 checkout；这也可能包含用户自己放进去的 checkout。如果系统有 Homebrew，还会执行 `brew update` 和 `brew upgrade`，并在可用时更新 `tldr`。只想在安装阶段更新与本项目远程地址匹配的依赖时，使用 `./install.sh --update`；只想更新远程管理的本仓库 source checkout 时，使用 `./install.sh --update-source`。

## 本机配置与目录结构

机器特定的设置建议放在以下文件，而不是提交到仓库：

```text
~/.zprofile.local   # PATH、SDK、brew shellenv、代理等登录 shell 设置
~/.zshrc.local      # 本机 alias、函数和交互式 shell 设置
```

仓库的 `.gitignore` 已忽略 `*.local`、`.env*`、`.netrc`、`.aws/`、`.ssh/` 以及常见私钥扩展名，但 `.gitignore` 只是防误提交措施，不是秘密管理工具。

主要目录：

```text
home/
  .zprofile          # 登录 shell 使用的仓库配置
  .zshrc             # 交互式 shell 入口
  .p10k.zsh          # Powerlevel10k 默认配置
zsh/rc/common.zsh    # alias、工具检测、Oh My Zsh 接入和更新函数
bin/zsh-doctor       # 安装后环境检查
tests/test-install.sh
install.sh           # POSIX 环境安装器
install.ps1          # Windows PowerShell 转发器
```

## 第三方依赖

安装器会从上游 GitHub 获取以下项目：

- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [fzf-tab](https://github.com/Aloxaf/fzf-tab)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-completions](https://github.com/zsh-users/zsh-completions)
- [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)

默认会从这些仓库的默认分支获取内容。对生产环境或需要可复现结果的场景，建议先审查仓库和依赖，再固定到经过确认的 commit 或 tag，而不是直接执行随时变化的 `main` 分支远程脚本。

## 开发与 CI

本地可以运行与 GitHub Actions 相同的核心检查：

```bash
bash -n install.sh bin/zsh-doctor tests/test-install.sh
zsh -n home/.zprofile home/.zshrc home/.p10k.zsh zsh/rc/common.zsh
shellcheck install.sh bin/zsh-doctor tests/test-install.sh
git diff --check
bash tests/test-install.sh
```

GitHub Actions 会在 Ubuntu、macOS 和 Windows/MSYS2 上执行语法检查、ShellCheck（Ubuntu/macOS）、隔离安装测试和真实依赖安装 smoke test，并在非 Pull Request 事件中测试已发布的一键安装脚本。

## 安全与许可证

远程一键安装本质上会下载并执行仓库中的 shell 脚本；在敏感环境中使用前，请先阅读或 clone 后审查 `install.sh`。安装器在需要系统权限时只调用已有的 `sudo` 或 `doas`，不会把密码写入文件；默认工具集中的单个包安装失败也不会绕过权限检查或强行覆盖用户目录。

不要把 API token、密码、私钥、公司内部路径或代理凭据放进仓库配置。公开仓库中的脚本、配置和提交历史都应按“任何人都能读取”来处理。

当前仓库没有附带 `LICENSE` 文件。仓库设为 public 不等于自动授予他人复制、修改或再发布的权利；如果希望明确允许复用，请根据你的意图补充合适的许可证。
