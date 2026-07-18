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

## 安全提示

不要把密码、访问令牌或 SSH 私钥直接放进项目。需要敏感信息时，应在执行过程中交互输入，或者从系统凭据管理器读取。
