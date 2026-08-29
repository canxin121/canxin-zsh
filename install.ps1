$ErrorActionPreference = 'Stop'

$installerUrl = 'https://raw.githubusercontent.com/canxin121/zsh-dotfiles/main/install.sh'

function Invoke-BashInstaller {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BashPath,

        [Parameter(Mandatory = $true)]
        [string]$Command,

        [switch]$UseWsl
    )

    if ($UseWsl) {
        & $BashPath -- bash -lc $Command
    } else {
        & $BashPath -lc $Command
    }
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
if ($null -ne $wsl) {
    Invoke-BashInstaller -BashPath $wsl.Source -Command "curl -fsSL '$installerUrl' | bash" -UseWsl
    exit 0
}

$bash = Get-Command bash.exe -ErrorAction SilentlyContinue
if ($null -ne $bash) {
    Invoke-BashInstaller -BashPath $bash.Source -Command "curl -fsSL '$installerUrl' | bash"
    exit 0
}

Write-Error @'
No WSL or POSIX bash environment was found.
Install WSL, MSYS2, or Cygwin with zsh and git, then run install.sh inside that environment.
Native PowerShell does not provide zsh by itself.
'@
exit 1
