# win-bootstrap

基于 PowerShell 和 winget 的 Windows 工作环境一键初始化工具。

## 使用条件

- Windows 10 或 Windows 11
- 已安装或更新 Microsoft App Installer（系统中可以使用 `winget`）
- 当前用户拥有管理员权限

启动入口和 PowerShell 脚本会将控制台、原生命令输入输出统一为 UTF-8，避免 winget 的中文进度信息出现乱码。

## 使用方法

1. 按需修改 `config/apps.psd1` 中的软件清单。
2. 双击 `install.cmd`，并在系统提示时允许管理员权限。
3. 安装日志会写入 `logs` 目录。

脚本可以重复执行。已经安装的软件会先验证安装位置，符合配置才会跳过；位置不符时会报告失败，并提示先卸载后重新执行。单个软件安装或验证失败不会中断后续软件，脚本会在最后统一返回失败状态。

支持自定义目录的软件会安装到 `config/apps.psd1` 中 `InstallRoot` 指定的根目录，当前为 `D:\Program Files`。脚本会校验路径不能逃逸出该根目录，并在安装后检查关键文件和根目录污染。Google Chrome、Bing Wallpaper、Focus 10 和 Fences 6 使用各自安装器或 Microsoft Store 的默认位置。

自定义路径不会自动迁移已经安装的软件，也不会自动删除位置错误或散落在根目录中的文件。

Node.js 由 NVM for Windows 安装并启用 LTS 版本，随后会根据 `NpmPackages` 配置安装全局 npm 包。NVM、活动 Node.js 目录和 npm 全局包目录分别位于 `D:\Program Files\nvm`、`D:\Program Files\nodejs` 和 `D:\Program Files\npm-global`。默认全局包包括：

- `pnpm`
- `@openai/codex`

这些目录会加入当前用户的 `PATH`。由于它们位于 `Program Files` 下，后续通过 NVM 安装 Node.js 或更新 npm 全局包时可能需要管理员权限。

如果电脑已经通过其他方式安装了 Node.js，建议先卸载独立版本，避免其安装目录与 NVM 的符号链接发生冲突。

`Node`、`NpmPackages` 和 `Git` 都是可选配置。临时注释某一整段时，脚本会跳过对应步骤；保留 `NpmPackages` 时必须同时保留 `Node`。

## 查找软件 ID

```powershell
winget search <软件名称>
winget show --id <软件ID> --exact
```

确认软件 ID 后，在 `config/apps.psd1` 的 `Packages` 数组中添加：

```powershell
@{
    Id           = 'Publisher.Package'
    Name         = 'Display Name'
    LocationMode = 'Default'
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

## 安装目录策略

每个 winget 软件都必须声明 `LocationMode`：

- `Exact`：向安装器传递最终软件目录，例如 `D:\Program Files\Git`。
- `Root`：只传递 `D:\Program Files`，由安装器自行追加软件目录。
- `Default`：不传递安装目录，由安装器或 Microsoft Store 管理。

当前清单中 7-Zip、Snipaste、Typora、Git、Visual Studio Code、Notepad++、FFmpeg、CC Switch、Clash Verge Rev、NVM 和 Python 使用 `Exact`；Google Chrome、Bing Wallpaper、Fences 6 和 Focus 10 使用 `Default`。Bing Wallpaper 使用 Microsoft Store 当前官方包 `XPFP7F8RL7MB1W`；安装时仍需能够访问微软提供的下载地址。当前没有需要 `Root` 的软件。

`Exact` 和 `Root` 模式必须配置软件目录以及至少一个安装后验证文件：

```powershell
@{
    Id               = 'Git.Git'
    Name             = 'Git'
    LocationMode     = 'Exact'
    InstallDirectory = 'Git'
    ExpectedPaths    = @('cmd\git.exe')
}
```

`InstallDirectory` 表示软件最终所在的子目录。无论向安装器传递根目录还是最终目录，验证位置始终为 `InstallRoot + InstallDirectory`。`ExpectedPaths` 是相对于该目录的候选文件，找到任意一个即通过；允许使用通配符处理带版本号的目录：

```powershell
@{
    Id               = 'Gyan.FFmpeg'
    Name             = 'FFmpeg'
    LocationMode     = 'Exact'
    InstallDirectory = 'FFmpeg'
    ExpectedPaths    = @('ffmpeg-*-full_build\bin\ffmpeg.exe')
}
```

默认目录模式不允许配置 `InstallDirectory` 或 `ExpectedPaths`：

```powershell
@{
    Id           = 'Google.Chrome'
    Name         = 'Google Chrome'
    LocationMode = 'Default'
}
```

安装受以下限制：

- 绝对子目录、`..` 路径和越出 `InstallRoot` 的配置会在安装前被拒绝。
- 非 `Default` 软件安装前后会比较 `D:\Program Files` 根目录中的文件；新增文件直接散落在根目录时验证失败。
- winget 返回成功后仍必须命中一个 `ExpectedPaths`，否则验证失败。
- 已安装软件也执行相同验证，位置错误时不会静默跳过。
- 驱动、系统服务、共享组件和用户配置仍可能按 Windows 规则写入系统目录或用户目录。

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
        Name     = 'pnpm'
        Version  = 'latest'
        Commands = @('pnpm.cmd')
    }
    @{
        Name     = '@openai/codex'
        Version  = 'latest'
        Commands = @('codex.cmd')
    }
)
```

`Version` 可以设置为 `latest` 或明确的版本号，`Commands` 用于确认命令确实写入 `D:\Program Files\npm-global`。npm 全局包会在 NVM 安装并启用 Node.js 后处理。

## 网络错误

winget 返回 `0x80072EFD` 或 `InternetOpenUrl() failed` 表示无法连接安装包地址。应检查系统代理、代理软件节点和目标域名连通性后重试。Bing Wallpaper 还可以在 Microsoft Store 中搜索并手动安装；商店产品 ID 为 `XPFP7F8RL7MB1W`。

## 安全提示

不要把密码、访问令牌或 SSH 私钥直接放进项目。需要敏感信息时，应在执行过程中交互输入，或者从系统凭据管理器读取。
