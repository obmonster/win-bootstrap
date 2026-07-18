[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)

    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Test-WingetPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Id
    )

    & winget list --id $Id --exact --accept-source-agreements | Out-Null
    return $LASTEXITCODE -eq 0
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $Package
    )

    Write-Host "`nChecking $($Package.Name)..." -ForegroundColor Cyan

    if (Test-WingetPackage -Id $Package.Id) {
        Write-Host "$($Package.Name) is already installed. Skipped." -ForegroundColor DarkGray
        return $true
    }

    $arguments = @(
        'install'
        '--id', $Package.Id
        '--exact'
        '--silent'
        '--disable-interactivity'
        '--accept-package-agreements'
        '--accept-source-agreements'
    )

    if ($Package.ContainsKey('Scope') -and $Package.Scope) {
        $arguments += @('--scope', $Package.Scope)
    }

    Write-Host "Installing $($Package.Name)..." -ForegroundColor Yellow
    & winget @arguments

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "$($Package.Name) failed with winget exit code $LASTEXITCODE."
        return $false
    }

    Write-Host "$($Package.Name) installed successfully." -ForegroundColor Green
    return $true
}

if (-not (Test-Administrator)) {
    Write-Error 'Run install.cmd or start this script as administrator.'
    exit 1
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error 'winget was not found. Install or update App Installer from Microsoft Store first.'
    exit 1
}

$configPath = Join-Path $PSScriptRoot 'config\apps.psd1'
if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Error "Configuration file not found: $configPath"
    exit 1
}

$config = Import-PowerShellDataFile -LiteralPath $configPath
$logDirectory = Join-Path $PSScriptRoot 'logs'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$logFile = Join-Path $logDirectory ("setup-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$failedPackages = New-Object System.Collections.Generic.List[string]

try {
    Start-Transcript -Path $logFile | Out-Null
    Write-Host 'Starting Windows initialization...' -ForegroundColor Cyan

    foreach ($package in $config.Packages) {
        if (-not (Install-WingetPackage -Package $package)) {
            $failedPackages.Add($package.Name)
        }
    }

    if (Get-Command git -ErrorAction SilentlyContinue) {
        git config --global core.autocrlf $config.Git.CoreAutoCrlf
        git config --global init.defaultBranch $config.Git.DefaultBranch
    }

    if ($failedPackages.Count -gt 0) {
        Write-Warning ("Failed packages: {0}" -f ($failedPackages -join ', '))
        exit 1
    }

    Write-Host "`nInitialization completed. Restart Windows if required." -ForegroundColor Green
}
finally {
    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
}
