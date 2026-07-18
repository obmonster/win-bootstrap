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
        [hashtable] $Package,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
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

    if ($Package.ContainsKey('Source') -and $Package.Source) {
        $arguments += @('--source', $Package.Source)
    }

    if ($Package.ContainsKey('InstallDirectory') -and $Package.InstallDirectory) {
        $rootPath = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\')
        $installLocation = [IO.Path]::GetFullPath(
            (Join-Path $rootPath $Package.InstallDirectory)
        )

        if (-not $installLocation.StartsWith("$rootPath\", [StringComparison]::OrdinalIgnoreCase)) {
            Write-Warning "$($Package.Name) has an invalid install directory."
            return $false
        }

        $arguments += @('--location', $installLocation)
        Write-Host "Install location: $installLocation" -ForegroundColor DarkGray
    }

    Write-Host "Installing $($Package.Name)..." -ForegroundColor Yellow
    & winget @arguments | Out-Host

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "$($Package.Name) failed with winget exit code $LASTEXITCODE."
        return $false
    }

    Write-Host "$($Package.Name) installed successfully." -ForegroundColor Green
    return $true
}

function Sync-ProcessEnvironment {
    foreach ($name in @('NVM_HOME', 'NVM_SYMLINK', 'NPM_CONFIG_PREFIX')) {
        $value = [Environment]::GetEnvironmentVariable($name, 'User')
        if (-not $value) {
            $value = [Environment]::GetEnvironmentVariable($name, 'Machine')
        }

        if ($value) {
            Set-Item -Path "Env:$name" -Value $value
        }
    }

    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = [Environment]::ExpandEnvironmentVariables("$machinePath;$userPath")
}

function Add-UserPathEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($userPath -split ';' | Where-Object { $_ })
    $exists = $entries | Where-Object {
        $_.TrimEnd('\') -eq $Path.TrimEnd('\')
    }

    if (-not $exists) {
        $entries += $Path
        [Environment]::SetEnvironmentVariable('Path', ($entries -join ';'), 'User')
    }
}

function Install-NodeVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Version,

        [Parameter(Mandatory = $true)]
        [string] $NvmHome,

        [Parameter(Mandatory = $true)]
        [string] $NvmSymlink,

        [Parameter(Mandatory = $true)]
        [string] $NpmGlobalDirectory
    )

    Sync-ProcessEnvironment

    if (-not (Get-Command nvm.exe -ErrorAction SilentlyContinue)) {
        Write-Warning 'nvm is unavailable. Node.js cannot be installed.'
        return $false
    }

    New-Item -ItemType Directory -Path $NvmHome -Force | Out-Null
    New-Item -ItemType Directory -Path $NpmGlobalDirectory -Force | Out-Null
    [Environment]::SetEnvironmentVariable('NVM_HOME', $NvmHome, 'User')
    [Environment]::SetEnvironmentVariable('NVM_SYMLINK', $NvmSymlink, 'User')
    [Environment]::SetEnvironmentVariable('NPM_CONFIG_PREFIX', $NpmGlobalDirectory, 'User')
    Add-UserPathEntry -Path $NvmHome
    Add-UserPathEntry -Path $NvmSymlink
    Add-UserPathEntry -Path $NpmGlobalDirectory

    $settingsPath = Join-Path $NvmHome 'settings.txt'
    $settings = @()
    if (Test-Path -LiteralPath $settingsPath) {
        $settings = @(
            Get-Content -LiteralPath $settingsPath |
                Where-Object { $_ -notmatch '^(root|path):' }
        )
    }

    @(
        "root: $NvmHome"
        "path: $NvmSymlink"
        $settings
    ) | Set-Content -LiteralPath $settingsPath -Encoding ASCII

    Sync-ProcessEnvironment

    Write-Host "`nInstalling Node.js $Version with NVM..." -ForegroundColor Yellow
    & nvm.exe install $Version | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Node.js $Version installation failed with nvm exit code $LASTEXITCODE."
        return $false
    }

    & nvm.exe use $Version | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Node.js $Version activation failed with nvm exit code $LASTEXITCODE."
        return $false
    }

    Sync-ProcessEnvironment
    Write-Host "Node.js $Version is active." -ForegroundColor Green
    return $true
}

function Install-NpmPackage {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $Package
    )

    if (-not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) {
        Write-Warning 'npm is unavailable. Global npm packages cannot be installed.'
        return $false
    }

    $specification = $Package.Name
    if ($Package.ContainsKey('Version') -and $Package.Version) {
        $specification = "$($Package.Name)@$($Package.Version)"
    }

    Write-Host "`nInstalling global npm package $specification..." -ForegroundColor Yellow
    & npm.cmd install --global $specification | Out-Host

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "$specification failed with npm exit code $LASTEXITCODE."
        return $false
    }

    Write-Host "$specification installed successfully." -ForegroundColor Green
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
$installDrive = [IO.Path]::GetPathRoot($config.InstallRoot)
if (-not $installDrive -or -not (Test-Path -LiteralPath $installDrive)) {
    Write-Error "Install drive is unavailable: $installDrive"
    exit 1
}

New-Item -ItemType Directory -Path $config.InstallRoot -Force | Out-Null
$logDirectory = Join-Path $PSScriptRoot 'logs'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$logFile = Join-Path $logDirectory ("setup-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$failedPackages = New-Object System.Collections.Generic.List[string]

try {
    Start-Transcript -Path $logFile | Out-Null
    Write-Host 'Starting Windows initialization...' -ForegroundColor Cyan

    foreach ($package in $config.Packages) {
        if (-not (Install-WingetPackage -Package $package -InstallRoot $config.InstallRoot)) {
            $failedPackages.Add($package.Name) | Out-Null
        }
    }

    $nvmHome = Join-Path $config.InstallRoot $config.Node.NvmDirectory
    $nvmSymlink = Join-Path $config.InstallRoot $config.Node.SymlinkDirectory
    $npmGlobalDirectory = Join-Path $config.InstallRoot $config.Node.NpmGlobalDirectory
    if (-not (Install-NodeVersion `
        -Version $config.Node.Version `
        -NvmHome $nvmHome `
        -NvmSymlink $nvmSymlink `
        -NpmGlobalDirectory $npmGlobalDirectory)) {
        $failedPackages.Add("Node.js $($config.Node.Version)") | Out-Null
    }

    foreach ($package in $config.NpmPackages) {
        if (-not (Install-NpmPackage -Package $package)) {
            $failedPackages.Add("npm:$($package.Name)") | Out-Null
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
