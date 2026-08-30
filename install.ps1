$ErrorActionPreference = 'Stop'

$installerUrl = 'https://raw.githubusercontent.com/canxin121/canxin-zsh/main/install.sh'
$scriptText = $null

try {
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
    $scriptText = (Invoke-WebRequest -UseBasicParsing -Uri $installerUrl).Content
} catch {
    Write-Error "Unable to download the canxin-zsh installer from $installerUrl`: $($_.Exception.Message)"
    exit 1
}

function Invoke-BashInstaller {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BashPath,

        [Parameter(Mandatory = $true)]
        [switch]$UseWsl
    )

    if ($UseWsl) {
        $scriptText | & $BashPath -- bash -s --
    } else {
        $scriptText | & $BashPath -s --
    }
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
if ($null -ne $wsl) {
    Invoke-BashInstaller -BashPath $wsl.Source -UseWsl
    exit 0
}

$bash = Get-Command bash.exe -ErrorAction SilentlyContinue
if ($null -ne $bash) {
    Invoke-BashInstaller -BashPath $bash.Source
    exit 0
}

Write-Error @'
No WSL or POSIX bash environment was found.
Install WSL (recommended), MSYS2, or Cygwin, then run this script again.
Native PowerShell does not provide zsh by itself.
'@
exit 1
