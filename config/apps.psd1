@{
    InstallRoot = 'D:\Program Files'

    Packages = @(
        @{
            Id               = '7zip.7zip'
            Name             = '7-Zip'
            InstallDirectory = '7-Zip'
        }
        @{
            Id   = 'Google.Chrome'
            Name = 'Google Chrome'
        }
        @{
            Id               = 'liule.Snipaste'
            Name             = 'Snipaste'
            InstallDirectory = 'Snipaste'
        }
        @{
            Id               = 'appmakes.Typora'
            Name             = 'Typora'
            InstallDirectory = 'Typora'
        }
        @{
            Id   = 'StardockSystems.Fences6'
            Name = 'Fences 6'
        }
        @{
            Id               = 'Git.Git'
            Name             = 'Git'
            InstallDirectory = 'Git'
        }
        @{
            Id               = 'Microsoft.VisualStudioCode'
            Name             = 'Visual Studio Code'
            Scope            = 'machine'
            InstallDirectory = 'Microsoft VS Code'
        }
        @{
            Id               = 'Notepad++.Notepad++'
            Name             = 'Notepad++'
            InstallDirectory = 'Notepad++'
        }
        @{
            Id               = 'Gyan.FFmpeg'
            Name             = 'FFmpeg'
            InstallDirectory = 'FFmpeg'
        }
        @{
            Id     = '9NBLGGH5G2XH'
            Name   = 'Focus 10'
            Source = 'msstore'
        }
        @{
            Id               = 'farion1231.CC-Switch'
            Name             = 'CC Switch'
            InstallDirectory = 'CC Switch'
        }
        @{
            Id               = 'ClashVergeRev.ClashVergeRev'
            Name             = 'Clash Verge Rev'
            InstallDirectory = 'Clash Verge Rev'
        }
        @{
            Id               = 'CoreyButler.NVMforWindows'
            Name             = 'NVM for Windows'
            InstallDirectory = 'nvm'
        }
        @{
            Id               = 'Python.Python.3.14'
            Name             = 'Python 3.14'
            Scope            = 'machine'
            InstallDirectory = 'Python314'
        }
    )

    Node = @{
        Version            = 'lts'
        NvmDirectory       = 'nvm'
        SymlinkDirectory   = 'nodejs'
        NpmGlobalDirectory = 'npm-global'
    }

    NpmPackages = @(
        @{
            Name    = 'pnpm'
            Version = 'latest'
        }
        @{
            Name    = '@openai/codex'
            Version = 'latest'
        }
    )

    Git = @{
        CoreAutoCrlf  = 'true'
        DefaultBranch = 'master'
    }
}
