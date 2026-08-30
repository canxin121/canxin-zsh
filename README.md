# canxin-zsh

一个跨机器的 zsh + Oh My Zsh 配置，包含 prompt、主题、插件和常用命令行工具的适配。

安装器优先考虑保留用户已有配置：它不会直接替换 `~/.zshrc`、`~/.zprofile` 或 `~/.p10k.zsh`，而是在 zsh 配置末尾维护一个可重复更新的 managed block。历史版本使用的 `zsh-dotfiles` marker 和本地备份目录会继续兼容，以免升级时重复加载配置。

## 一键安装

在 macOS、Linux、WSL、MSYS2 或 Cygwin 的 zsh/bash 环境中运行：

```bash
curl -fsSL https://raw.githubusercontent.com/canxin121/canxin-zsh/main/install.sh | bash
```

也可以先克隆后运行：

```bash
git clone https://github.com/canxin121/canxin-zsh.git
cd canxin-zsh
./install.sh
```

远程一键安装会把本仓库放到：

```text
${XDG_DATA_HOME:-~/.local/share}/canxin-zsh
```

新安装默认使用 `${XDG_DATA_HOME:-~/.local/share}/canxin-zsh`；如果检测到旧版本已经存在的 `zsh-dotfiles` checkout，安装器会继续复用它，不会重复下载或破坏已有配置。

在已经克隆的目录中运行 `./install.sh` 时，则直接使用当前目录作为配置源。

## Windows 支持

Windows 原生 PowerShell 本身不提供 zsh，因此推荐使用 WSL。也支持已经安装 zsh 的 MSYS2 或 Cygwin。

WSL Ubuntu（PowerShell 方式不要求 WSL 预先安装 `curl`）：

```bash
sudo apt update
sudo apt install -y git curl zsh
curl -fsSL https://raw.githubusercontent.com/canxin121/canxin-zsh/main/install.sh | bash
```

MSYS2：

```bash
pacman -S --needed git curl zsh
curl -fsSL https://raw.githubusercontent.com/canxin121/canxin-zsh/main/install.sh | bash
```

Cygwin 用户请在 Cygwin 安装器中选择 `git`、`curl` 和 `zsh`，然后在 Cygwin 终端运行上面的命令。Cygwin 的系统包需要通过 Cygwin 安装器维护；安装脚本不会猜测或替换 Cygwin 安装器。单独的 Git Bash 通常没有 zsh；安装器会检测到这一点并给出明确错误，不会修改配置。

如果希望从 PowerShell 启动，仓库也提供了一个小型转发脚本：

```powershell
irm https://raw.githubusercontent.com/canxin121/canxin-zsh/main/install.ps1 | iex
```

它会先用 PowerShell 下载脚本，再优先交给 WSL，其次交给 `bash.exe`，所以 WSL/MSYS2 中不必预先安装 `curl`。实际配置仍然安装在 WSL/MSYS2/Cygwin 的 zsh 环境中。

## 系统依赖自动安装

默认情况下，安装器会先检测并尝试自动安装下面这套基础工具；它们不再作为安装界面里的“一堆可选项”：

- 必需依赖：`zsh`、`git`、`curl` 和 CA 证书；
- 默认工具集：`fzf`、`ripgrep`、`fd`、`eza`、`bat`、`btop`、`lazygit`、`tldr`（可用包名 `tealdeer` 安装）。

支持的系统包管理器包括：

- macOS：已安装 Homebrew 时使用 `brew`；macOS 自带的 `zsh`、`git`、`curl` 可直接使用。没有 Homebrew 时不会静默安装整套 Homebrew，而是保留系统自带能力并明确提示默认工具集无法全部补齐；
- Debian/Ubuntu/WSL：`apt-get`；
- Fedora/RHEL 系：`dnf` 或 `yum`；
- Arch/MSYS2：`pacman`；
- Alpine：`apk`；
- openSUSE：`zypper`。

安装必需系统包时失败会停止；默认工具集会逐个平台尝试安装，某个工具在当前发行版没有对应包时只会警告并继续，不会让整个 zsh 配置失败。需要权限时使用现有的 `sudo` 或 `doas`，不会把密码写入文件。系统包安装和 Oh My Zsh/plugin checkout 都只在缺少时执行；已有 checkout 不会被另一个远程仓库覆盖。

如果希望完全手动管理依赖，可以使用：

```bash
./install.sh --skip-dependencies       # 跳过系统包、Oh My Zsh 和插件/主题
./install.sh --no-system-dependencies  # 只跳过系统包管理器，仍可安装 Oh My Zsh/plugin
./install.sh --minimal                 # 只安装 zsh/git/curl 等必需依赖，不安装默认工具集
```

## 安装器会做什么

1. 检查 `bash`、`zsh`，并识别 macOS、Linux、WSL 和 Windows POSIX shell 环境。
2. 在支持的包管理器中补齐缺少的必需依赖和默认工具集。
3. 如果缺少 Oh My Zsh，则克隆到 `$ZSH` 或默认的 `~/.oh-my-zsh`。
4. 如果缺少本仓库使用的插件和主题，则克隆到 `$ZSH_CUSTOM`。
5. 已存在的 Oh My Zsh、插件、主题目录会保留，不会被覆盖；不是本项目仓库的 Git checkout 也不会被自动更新。
6. 在 zsh 配置末尾添加或更新以下 marker 之间的内容：

   ```text
   # >>> zsh-dotfiles managed block >>>
   ...
   # <<< zsh-dotfiles managed block <<<
   ```

7. 如果修改已有配置，会在 `~/.config/zsh-dotfiles/backups/` 下创建权限较严格的本地备份。备份不在仓库内，也不会上传到 GitHub。

重复执行安装器是安全的：已有 managed block 会被更新，不会不断追加重复内容。

## 与已有配置的关系

### 空配置或没有 zsh 框架

安装器会初始化 Oh My Zsh、Powerlevel10k 和本仓库列出的插件。

### 已有 Oh My Zsh

安装器不会重写用户的 `ZSH_THEME`、`plugins` 或 Oh My Zsh 配置，也不会再次加载已经加载的 Oh My Zsh。缺少的插件目录会安装，但不会擅自改动用户的插件列表。

### 已有其他 zsh 框架

如果检测到 zinit、zplug、zgen、antigen、zimfw、sheldon、prezto 或 zcomet 等框架，安装器不会再启动 Oh My Zsh。已有配置拥有优先权。

### 配置冲突

- 已有同名 alias 或 function 时，本仓库不会覆盖它；
- 已有用户配置中，默认不会强行重设快捷键和 completion style；
- 只有选用了 Powerlevel10k 时，才会加载仓库里的 `.p10k.zsh`；
- `~/.zshrc.local` 和 `~/.zprofile.local` 只作为本机覆盖配置使用，不应放进仓库；
- 如果已有配置文件是普通 symlink，安装器会保留 symlink，但会更新其目标文件，并在操作前备份内容；如果 symlink 直接指向本仓库的 `home/.zshrc`/`home/.zprofile`，则会安全地脱链，避免配置递归 source；
- 已有可读的 `~/.p10k.zsh` 或 `POWERLEVEL9K_CONFIG_FILE` 配置优先于仓库默认 p10k 配置。

如果需要完全关闭本仓库的默认依赖安装，可以使用 `--skip-dependencies`；此时缺少必需命令会直接报错，不会修改系统或配置。

## 常用选项

```bash
./install.sh --update             # 更新已存在的 Oh My Zsh/插件/主题 checkout
./install.sh --update-source      # 更新 curl|bash 模式管理的仓库副本
./install.sh --skip-dependencies  # 不安装系统包、Oh My Zsh/插件/主题
./install.sh --no-system-dependencies # 不调用系统包管理器
./install.sh --minimal            # 不安装默认 CLI 工具集
./install.sh --dry-run            # 只显示配置修改计划；远程脚本模式需改在本地 checkout 中运行
```

也可以使用环境变量：

```bash
ZSH_DOTFILES_INSTALL_DIR="$HOME/.local/share/canxin-zsh" ./install.sh
ZSH_DOTFILES_SKIP_DEPENDENCIES=1 ./install.sh
ZSH_DOTFILES_AUTO_INSTALL=0 ./install.sh
ZSH_DOTFILES_INSTALL_TOOLSET=0 ./install.sh
```

`ZSH_DOTFILES_INSTALL_OPTIONAL_TOOLS=0` 和 `--no-optional-tools` 仍作为旧版本兼容别名保留，但新配置建议使用 `--minimal` 或 `ZSH_DOTFILES_INSTALL_TOOLSET=0`。

## 本机覆盖配置

以下文件应该留在每台机器本地：

- `~/.zprofile.local`
- `~/.zshrc.local`

适合放在这些文件中的内容包括：

- 机器特定的 `PATH`；
- 公司代理设置；
- `JAVA_HOME`、`ANDROID_HOME` 等 SDK 变量；
- `brew shellenv` 或 Linuxbrew 初始化；
- SSH、云平台环境变量；
- 主机特定 alias。

仓库的 `.gitignore` 也会忽略 `*.local`、`.env*`、SSH/AWS 配置和常见私钥文件，降低误提交风险。

## 目录结构

```text
home/
  .p10k.zsh
  .zprofile
  .zshrc
zsh/
  rc/
    common.zsh
bin/
  zsh-doctor
tests/
  test-install.sh
install.sh
install.ps1
```

## 默认工具集

安装器会默认尝试安装这些工具，配置会自动启用其中一部分。个别发行版如果没有对应软件包，shell 仍可工作，并会在安装日志和 `bin/zsh-doctor` 中显示缺失项：

- `fzf`
- `ripgrep`
- `fd` 或 `fdfind`
- `eza` 或 `exa`
- `bat` 或 `batcat`
- `btop`
- `lazygit`
- `tldr`

安装完成后可以运行：

```bash
bin/zsh-doctor
```

## 第三方依赖与更新

安装器从上游 GitHub 仓库获取 Oh My Zsh、插件和 Powerlevel10k。当前默认使用这些仓库的默认分支；`--update` 或 `zupdate-all` 会主动拉取更新。如果要在更严格的生产环境使用，建议把这些依赖固定到审查过的 commit 或 tag。

## 开源许可

本仓库目前没有附带许可证文件。公开可见不等于自动授予他人复制、修改或再发布的权利；如果希望别人明确复用，请根据你的意图添加合适的 `LICENSE`。
