@{
    InstallRoot = 'D:\Program Files'

    Packages = @(
        @{
            Id               = '7zip.7zip'
            Name             = '7-Zip'
            LocationMode     = 'Exact'
            InstallDirectory = '7-Zip'
            ExpectedPaths    = @('7z.exe')
        }
        # @{
        #     Id           = 'XPFP7F8RL7MB1W'
        #     Name         = 'Bing Wallpaper'
        #     Source       = 'msstore'
        #     LocationMode = 'Default'
        # }
        # @{
        #     Id           = 'Google.Chrome'
        #     Name         = 'Google Chrome'
        #     LocationMode = 'Default'
        # }
        # @{
        #     Id               = 'liule.Snipaste'
        #     Name             = 'Snipaste'
        #     LocationMode     = 'Exact'
        #     InstallDirectory = 'Snipaste'
        #     ExpectedPaths    = @('Snipaste.exe')
        # }
        # @{
        #     Id               = 'appmakes.Typora'
        #     Name             = 'Typora'
        #     LocationMode     = 'Exact'
        #     InstallDirectory = 'Typora'
        #     ExpectedPaths    = @('Typora.exe')
        # }
        # @{
        #     Id           = 'StardockSystems.Fences6'
        #     Name         = 'Fences 6'
        #     LocationMode = 'Default'
        # }
        # @{
        #     Id               = 'Git.Git'
        #     Name             = 'Git'
        #     LocationMode     = 'Exact'
        #     InstallDirectory = 'Git'
        #     ExpectedPaths    = @('cmd\git.exe')
        # }
        # @{
        #     Id               = 'Microsoft.VisualStudioCode'
        #     Name             = 'Visual Studio Code'
        #     Scope            = 'machine'
        #     LocationMode     = 'Exact'
        #     InstallDirectory = 'Microsoft VS Code'
        #     ExpectedPaths    = @('Code.exe')
        # }
        # @{
        #     Id               = 'Notepad++.Notepad++'
        #     Name             = 'Notepad++'
        #     LocationMode     = 'Exact'
        #     InstallDirectory = 'Notepad++'
        #     ExpectedPaths    = @('notepad++.exe')
        # }
        # @{
        #     Id               = 'Gyan.FFmpeg'
        #     Name             = 'FFmpeg'
        #     LocationMode     = 'Exact'
        #     InstallDirectory = 'FFmpeg'
        #     ExpectedPaths    = @(
        #         'ffmpeg.exe'
        #         'bin\ffmpeg.exe'
        #         'ffmpeg-*-full_build\bin\ffmpeg.exe'
        #     )
        # }
        # @{
        #     Id           = '9NBLGGH5G2XH'
        #     Name         = 'Focus 10'
        #     Source       = 'msstore'
        #     LocationMode = 'Default'
        # }
        @{
            Id               = 'farion1231.CC-Switch'
            Name             = 'CC Switch'
            LocationMode     = 'Exact'
            InstallDirectory = 'CC Switch'
            ExpectedPaths    = @('CC Switch.exe', 'cc-switch.exe')
        }
        @{
            Id               = 'Ngrok.Ngrok'
            Name             = 'ngrok'
            LocationMode     = 'Exact'
            InstallDirectory = 'ngrok'
            ExpectedPaths    = @('ngrok.exe')
        }
        # @{
        #     Id               = 'Oracle.MySQL'
        #     Name             = 'MySQL'
        #     DownloadUrl      = 'https://dev.mysql.com/downloads/installer/'
        #     Scope            = 'machine'
        #     LocationMode     = 'Exact'
        #     InstallDirectory = 'MySQL'
        #     ExpectedPaths    = @('bin\mysql.exe', 'bin\mysqld.exe')
        # }
        # @{
        #     Id               = 'DBeaver.DBeaver.Community'
        #     Name             = 'DBeaver Community'
        #     DownloadUrl      = 'https://dbeaver.io/download/'
        #     Scope            = 'machine'
        #     LocationMode     = 'Exact'
        #     InstallDirectory = 'DBeaver'
        #     ExpectedPaths    = @('dbeaver.exe')
        # }
        # @{
        #     Id               = 'nginxinc.nginx'
        #     Name             = 'nginx'
        #     LocationMode     = 'Exact'
        #     InstallDirectory = 'nginx'
        #     ExpectedPaths    = @('nginx.exe', 'nginx-*\nginx.exe')
        # }
        # @{
        #     Id               = 'ClashVergeRev.ClashVergeRev'
        #     Name             = 'Clash Verge Rev'
        #     LocationMode     = 'Exact'
        #     InstallDirectory = 'Clash Verge Rev'
        #     ExpectedPaths    = @('clash-verge.exe', 'Clash Verge.exe', 'Clash Verge Rev.exe')
        # }
        # @{
        #     Id               = 'CoreyButler.NVMforWindows'
        #     Name             = 'NVM for Windows'
        #     LocationMode     = 'Exact'
        #     InstallDirectory = 'nvm'
        #     ExpectedPaths    = @('nvm.exe')
        # }
        # @{
        #     Id               = 'Python.Python.3.14'
        #     Name             = 'Python 3.14'
        #     Scope            = 'machine'
        #     LocationMode     = 'Exact'
        #     InstallDirectory = 'Python314'
        #     ExpectedPaths    = @('python.exe')
        # }
    )

    # Fonts = @(
    #     @{
    #         Name     = 'Fira Code'
    #         Version  = '6.2'
    #         Url      = 'https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip'
    #         TtfFiles = @(
    #             @{ File = 'ttf/FiraCode-Regular.ttf';    RegistryName = 'Fira Code Regular' }
    #             @{ File = 'ttf/FiraCode-Medium.ttf';     RegistryName = 'Fira Code Medium' }
    #             @{ File = 'ttf/FiraCode-SemiBold.ttf';   RegistryName = 'Fira Code SemiBold' }
    #             @{ File = 'ttf/FiraCode-Bold.ttf';       RegistryName = 'Fira Code Bold' }
    #             @{ File = 'ttf/FiraCode-Light.ttf';      RegistryName = 'Fira Code Light' }
    #             @{ File = 'ttf/FiraCode-Retina.ttf';     RegistryName = 'Fira Code Retina' }
    #             @{ File = 'variable_ttf/FiraCode-VF.ttf'; RegistryName = 'Fira Code Variable' }
    #         )
    #     }
    # )

    # Node = @{
    #     Version            = 'lts'
    #     NvmDirectory       = 'nvm'
    #     SymlinkDirectory   = 'nodejs'
    #     NpmGlobalDirectory = 'npm-global'
    # }

    # NpmPackages = @(
    #     @{
    #         Name     = 'pnpm'
    #         Version  = 'latest'
    #         Commands = @('pnpm.cmd')
    #     }
    #     @{
    #         Name     = '@openai/codex'
    #         Version  = 'latest'
    #         Commands = @('codex.cmd')
    #     }
    #     @{
    #         Name     = '@anthropic-ai/claude-code'
    #         Version  = 'latest'
    #         Commands = @('claude.cmd')
    #     }
    #     @{
    #         Name     = 'opencode-ai'
    #         Version  = 'latest'
    #         Commands = @('opencode.cmd')
    #     }
    # )

    # Git = @{
    #     CoreAutoCrlf  = 'true'
    #     DefaultBranch = 'master'
    # }
}
