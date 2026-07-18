@{
    Packages = @(
        @{
            Id   = '7zip.7zip'
            Name = '7-Zip'
        }
        @{
            Id   = 'Google.Chrome'
            Name = 'Google Chrome'
        }
        @{
            Id   = 'Git.Git'
            Name = 'Git'
        }
        @{
            Id   = 'Microsoft.VisualStudioCode'
            Name = 'Visual Studio Code'
        }
        @{
            Id   = 'Microsoft.WindowsTerminal'
            Name = 'Windows Terminal'
        }
        @{
            Id   = 'Microsoft.PowerShell'
            Name = 'PowerShell 7'
        }
        @{
            Id   = 'OpenJS.NodeJS.LTS'
            Name = 'Node.js LTS'
        }
        @{
            Id   = 'Docker.DockerDesktop'
            Name = 'Docker Desktop'
        }
    )

    Git = @{
        CoreAutoCrlf  = 'true'
        DefaultBranch = 'main'
    }
}
