<#
.SYNOPSIS
Builds the examples inside WSL2. hcc only targets Linux and macOS, so on
Windows everything runs in a WSL distribution, and windows show up through
WSLg on Windows 11 or a recent Windows 10.

.EXAMPLE
.\scripts\build-windows.ps1 -InstallHcc
.\scripts\build-windows.ps1 -Only sprite-demo -Run
#>
param(
    [switch]$InstallHcc,
    [string]$Only = "",
    [switch]$Run,
    [string]$Distro = ""
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    Write-Error "WSL is not installed. Run 'wsl --install' in an admin PowerShell, reboot, then try again."
}

$wslArgs = @()
if ($Distro) { $wslArgs += @("-d", $Distro) }

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$wslRepo = (& wsl.exe @wslArgs wslpath -a ($repo -replace '\\', '/')).Trim()
if (-not $wslRepo) {
    Write-Error "Could not translate $repo to a WSL path."
}

$buildArgs = @()
if ($InstallHcc) { $buildArgs += "--install-hcc" }
if ($Only) { $buildArgs += @("--only", $Only) }

& wsl.exe @wslArgs --cd $wslRepo bash ./scripts/build-linux.sh @buildArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($Run) {
    if (-not $Only) {
        Write-Error "-Run needs -Only <example> so it knows which program to start."
    }
    $binaries = @{
        "hello-world" = "hello"; "draw-basic" = "draw"; "sprite-demo" = "sprite";
        "simple-3d" = "cube"; "sdl-demo" = "sdl_example"; "opengl-demo" = "opengl_example"
    }
    $bin = $binaries[$Only]
    if (-not $bin) { Write-Error "Unknown example: $Only" }
    & wsl.exe @wslArgs --cd "$wslRepo/examples/$Only" "../../build/bin/$bin"
    exit $LASTEXITCODE
}
