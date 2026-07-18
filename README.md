# win-bootstrap

基于 PowerShell 和 winget 的 Windows 工作环境一键初始化工具。

## 使用条件

- Windows 10 或 Windows 11
- 已安装或更新 Microsoft App Installer（系统中可以使用 `winget`）
- 当前用户拥有管理员权限

## 使用方法

1. 按需修改 `config/apps.psd1` 中的软件清单。
2. 双击 `install.cmd`，并在系统提示时允许管理员权限。
3. 安装日志会写入 `logs` 目录。

脚本可以重复执行，已经安装的软件会自动跳过。单个软件安装失败时，脚本会继续安装后续软件，并在最后返回失败状态。

支持自定义目录的软件会安装到 `config/apps.psd1` 中 `InstallRoot` 指定的根目录，当前为 `D:\Program Files`。每个软件通过 `InstallDirectory` 指定子目录。Google Chrome、Focus 10 和 Fences 6 使用各自安装器或 Microsoft Store 的默认位置。

自定义路径只影响首次安装，不会自动迁移电脑上已经安装的软件。

Node.js 由 NVM for Windows 安装并启用 LTS 版本，随后会根据 `NpmPackages` 配置安装全局 npm 包。NVM、活动 Node.js 目录和 npm 全局包目录分别位于 `D:\Program Files\nvm`、`D:\Program Files\nodejs` 和 `D:\Program Files\npm-global`。默认全局包包括：

- `pnpm`
- `@openai/codex`

这些目录会加入当前用户的 `PATH`。由于它们位于 `Program Files` 下，后续通过 NVM 安装 Node.js 或更新 npm 全局包时可能需要管理员权限。

如果电脑已经通过其他方式安装了 Node.js，建议先卸载独立版本，避免其安装目录与 NVM 的符号链接发生冲突。

## 查找软件 ID

```powershell
winget search <软件名称>
winget show --id <软件ID> --exact
```

确认软件 ID 后，在 `config/apps.psd1` 的 `Packages` 数组中添加：

```powershell
@{
    Id   = 'Publisher.Package'
    Name = 'Display Name'
}
```

如果安装包支持安装范围，还可以指定：

```powershell
@{
    Id    = 'Publisher.Package'
    Name  = 'Display Name'
    Scope = 'machine'
}
```

支持自定义安装目录的软件可以设置：

```powershell
@{
    Id               = 'Git.Git'
    Name             = 'Git'
    InstallDirectory = 'Git'
}
```

实际路径为 `InstallRoot` 与 `InstallDirectory` 的组合，例如 `D:\Program Files\Git`。

Microsoft Store 等非默认来源的软件可以指定 `Source`：

```powershell
@{
    Id     = '9NBLGGH5G2XH'
    Name   = 'Focus 10'
    Source = 'msstore'
}
```

## 配置全局 npm 包

编辑 `config/apps.psd1` 中的 `NpmPackages`：

```powershell
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
```

`Version` 可以设置为 `latest` 或明确的版本号。npm 全局包会在 NVM 安装并启用 Node.js 后处理。

## 安全提示

不要把密码、访问令牌或 SSH 私钥直接放进项目。需要敏感信息时，应在执行过程中交互输入，或者从系统凭据管理器读取。
