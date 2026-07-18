[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$utf8Encoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = $utf8Encoding
[Console]::InputEncoding = $utf8Encoding
[Console]::OutputEncoding = $utf8Encoding

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

function Resolve-ManagedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $Directory,

        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    if ([IO.Path]::IsPathRooted($Directory)) {
        throw "$Name install directory must be relative: $Directory"
    }

    if ('..' -in ($Directory -split '[\\/]') -or $Directory -match '[*?]') {
        throw "$Name install directory contains a forbidden segment: $Directory"
    }

    $rootPath = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\')
    $managedPath = [IO.Path]::GetFullPath((Join-Path $rootPath $Directory))
    if (-not $managedPath.StartsWith("$rootPath\", [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Name install directory escapes the install root: $Directory"
    }

    return $managedPath
}

function Test-PackageConfiguration {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $Package,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    if ($Package.LocationMode -notin @('Exact', 'Root', 'Default')) {
        Write-Warning "$($Package.Name) has an invalid LocationMode: $($Package.LocationMode)"
        return $false
    }

    if ($Package.LocationMode -eq 'Default') {
        if ($Package.InstallDirectory -or $Package.ExpectedPaths) {
            Write-Warning "$($Package.Name) cannot define managed paths in Default mode."
            return $false
        }

        return $true
    }

    if (-not $Package.InstallDirectory -or -not $Package.ExpectedPaths) {
        Write-Warning "$($Package.Name) requires InstallDirectory and ExpectedPaths."
        return $false
    }

    try {
        $null = Resolve-ManagedPath `
            -InstallRoot $InstallRoot `
            -Directory $Package.InstallDirectory `
            -Name $Package.Name
    }
    catch {
        Write-Warning $_.Exception.Message
        return $false
    }

    foreach ($expectedPath in $Package.ExpectedPaths) {
        if ([IO.Path]::IsPathRooted($expectedPath) -or '..' -in ($expectedPath -split '[\\/]')) {
            Write-Warning "$($Package.Name) has an invalid ExpectedPath: $expectedPath"
            return $false
        }
    }

    return $true
}

function Test-PackageInstallLocation {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $Package,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    if ($Package.LocationMode -eq 'Default') {
        return $true
    }

    $expectedDirectory = Resolve-ManagedPath `
        -InstallRoot $InstallRoot `
        -Directory $Package.InstallDirectory `
        -Name $Package.Name

    foreach ($expectedPath in $Package.ExpectedPaths) {
        $candidate = Join-Path $expectedDirectory $expectedPath
        $matchedFile = Get-Item -Path $candidate -ErrorAction SilentlyContinue |
            Where-Object { -not $_.PSIsContainer } |
            Select-Object -First 1
        if ($matchedFile) {
            Write-Host "Verified location: $($matchedFile.FullName)" -ForegroundColor Green
            return $true
        }
    }

    Write-Warning (
        "{0} is installed, but no expected file was found under {1}. Expected one of: {2}" -f `
            $Package.Name,
            $expectedDirectory,
            ($Package.ExpectedPaths -join ', ')
    )
    return $false
}

function Get-InstallRootFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    return @(
        Get-ChildItem -LiteralPath $InstallRoot -File -Force -ErrorAction SilentlyContinue |
            ForEach-Object { $_.FullName }
    )
}

function Test-InstallRootUnchanged {
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [string[]] $Before = @()
    )

    $newFiles = @(
        Get-InstallRootFiles -InstallRoot $InstallRoot |
            Where-Object { $_ -notin $Before }
    )

    if ($newFiles.Count -eq 0) {
        return $true
    }

    Write-Warning (
        "New files were written directly to ${InstallRoot}: {0}" -f ($newFiles -join ', ')
    )
    return $false
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
        if (Test-PackageInstallLocation -Package $Package -InstallRoot $InstallRoot) {
            Write-Host "$($Package.Name) is already installed and valid. Skipped." -ForegroundColor DarkGray
            return $true
        }

        Write-Warning "$($Package.Name) must be uninstalled before reinstalling it in the managed location."
        return $false
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

    if ($Package.LocationMode -eq 'Exact') {
        $installLocation = Resolve-ManagedPath `
            -InstallRoot $InstallRoot `
            -Directory $Package.InstallDirectory `
            -Name $Package.Name
        $arguments += @('--location', $installLocation)
        Write-Host "Install location: $installLocation" -ForegroundColor DarkGray
    }
    elseif ($Package.LocationMode -eq 'Root') {
        $arguments += @('--location', $InstallRoot)
        Write-Host "Install root: $InstallRoot" -ForegroundColor DarkGray
    }

    $rootFilesBefore = @()
    if ($Package.LocationMode -ne 'Default') {
        $rootFilesBefore = Get-InstallRootFiles -InstallRoot $InstallRoot
    }

    Write-Host "Installing $($Package.Name)..." -ForegroundColor Yellow
    & winget @arguments | Out-Host
    $wingetExitCode = $LASTEXITCODE

    if ($wingetExitCode -ne 0) {
        if ($wingetExitCode -eq -2147012867) {
            Write-Warning (
                'Network connection failed (0x80072EFD). Check the system proxy and access to the installer host.'
            )
        }

        Write-Warning "$($Package.Name) failed with winget exit code $wingetExitCode."
        return $false
    }

    $locationIsValid = Test-PackageInstallLocation `
        -Package $Package `
        -InstallRoot $InstallRoot
    $rootIsUnchanged = $true
    if ($Package.LocationMode -ne 'Default') {
        $rootIsUnchanged = Test-InstallRootUnchanged `
            -InstallRoot $InstallRoot `
            -Before $rootFilesBefore
    }

    if (-not $locationIsValid -or -not $rootIsUnchanged) {
        Write-Warning "$($Package.Name) installed, but its location validation failed."
        return $false
    }

    Write-Host "$($Package.Name) installed successfully and its location was verified." -ForegroundColor Green
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

    $nvmExecutable = Join-Path $NvmHome 'nvm.exe'
    $nodeExecutable = Join-Path $NvmSymlink 'node.exe'
    if (-not (Test-Path -LiteralPath $nvmExecutable -PathType Leaf) -or
        -not (Test-Path -LiteralPath $nodeExecutable -PathType Leaf)) {
        Write-Warning 'NVM or Node.js was not found in the configured D drive location.'
        return $false
    }

    $npmPrefixOutput = @(& npm.cmd config get prefix 2>$null)
    $npmExitCode = $LASTEXITCODE
    $npmPrefix = $npmPrefixOutput | Select-Object -Last 1
    if ($npmExitCode -ne 0 -or -not $npmPrefix -or
        [IO.Path]::GetFullPath($npmPrefix.Trim()) -ne [IO.Path]::GetFullPath($NpmGlobalDirectory)) {
        Write-Warning "npm global prefix is not configured as $NpmGlobalDirectory."
        return $false
    }

    Write-Host "Node.js $Version is active and its managed paths were verified." -ForegroundColor Green
    return $true
}

function Install-NpmPackage {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $Package,

        [Parameter(Mandatory = $true)]
        [string] $NpmGlobalDirectory
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

    $commandFound = $Package.Commands | Where-Object {
        Test-Path -LiteralPath (Join-Path $NpmGlobalDirectory $_) -PathType Leaf
    }
    if (-not $commandFound) {
        Write-Warning "$specification installed, but its command was not found in $NpmGlobalDirectory."
        return $false
    }

    Write-Host "$specification installed successfully and its location was verified." -ForegroundColor Green
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
$invalidPackages = New-Object System.Collections.Generic.List[string]
foreach ($package in $config.Packages) {
    if (-not (Test-PackageConfiguration -Package $package -InstallRoot $config.InstallRoot)) {
        $invalidPackages.Add($package.Name) | Out-Null
    }
}

if ($invalidPackages.Count -gt 0) {
    Write-Error ("Invalid package configuration: {0}" -f ($invalidPackages -join ', '))
    exit 1
}

$nvmHome = $null
$nvmSymlink = $null
$npmGlobalDirectory = $null
if ($config.Node) {
    try {
        $nvmHome = Resolve-ManagedPath `
            -InstallRoot $config.InstallRoot `
            -Directory $config.Node.NvmDirectory `
            -Name 'NVM_HOME'
        $nvmSymlink = Resolve-ManagedPath `
            -InstallRoot $config.InstallRoot `
            -Directory $config.Node.SymlinkDirectory `
            -Name 'NVM_SYMLINK'
        $npmGlobalDirectory = Resolve-ManagedPath `
            -InstallRoot $config.InstallRoot `
            -Directory $config.Node.NpmGlobalDirectory `
            -Name 'NPM_CONFIG_PREFIX'
    }
    catch {
        Write-Error $_.Exception.Message
        exit 1
    }

    $nvmPackage = $config.Packages | Where-Object Id -eq 'CoreyButler.NVMforWindows'
    if (-not $nvmPackage -or $nvmPackage.InstallDirectory -ne $config.Node.NvmDirectory) {
        Write-Error 'The NVM package and Node.NvmDirectory configurations must match.'
        exit 1
    }
}
elseif ($config.NpmPackages) {
    Write-Error 'NpmPackages requires the Node configuration.'
    exit 1
}

if ($config.NpmPackages) {
    foreach ($npmPackage in $config.NpmPackages) {
        if (-not $npmPackage.Name -or -not $npmPackage.Commands) {
            Write-Error 'Each npm package requires Name and Commands.'
            exit 1
        }
    }
}

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

    if ($config.Node) {
        if (-not (Install-NodeVersion `
            -Version $config.Node.Version `
            -NvmHome $nvmHome `
            -NvmSymlink $nvmSymlink `
            -NpmGlobalDirectory $npmGlobalDirectory)) {
            $failedPackages.Add("Node.js $($config.Node.Version)") | Out-Null
        }
    }

    if ($config.NpmPackages) {
        foreach ($package in $config.NpmPackages) {
            if (-not (Install-NpmPackage `
                -Package $package `
                -NpmGlobalDirectory $npmGlobalDirectory)) {
                $failedPackages.Add("npm:$($package.Name)") | Out-Null
            }
        }
    }

    if ($config.Git -and (Get-Command git -ErrorAction SilentlyContinue)) {
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
