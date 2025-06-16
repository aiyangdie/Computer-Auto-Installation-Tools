# WinGet 自动安装脚本使用说明

这个项目提供了两个基于Windows Package Manager (WinGet) 的自动安装脚本，用于快速批量安装Windows软件。

## 什么是WinGet？

WinGet是微软官方推出的命令行软件包管理工具，支持在Windows 10 1709及以上版本使用。它允许用户通过命令行快速地搜索、下载、安装、升级和卸载软件包，无需手动下载安装程序或访问各个软件的官方网站。

## 脚本说明

本项目包含两个脚本：

1. **winget_install.bat** - 预设软件列表安装脚本
   - 包含预先定义的常用软件列表
   - 可以一键安装所有预设软件
   - 适合快速部署标准环境

2. **winget_custom_install.bat** - 自定义软件列表安装脚本
   - 从`software_list.txt`文件读取要安装的软件
   - 首次运行会创建示例软件列表文件
   - 用户可以根据需要修改软件列表
   - 适合个性化安装需求

## 系统要求

- Windows 10 1709 或更高版本
- WinGet 已安装（Windows 10/11较新版本已预装）
- 推荐以管理员权限运行

## 使用方法

### 基本安装脚本 (winget_install.bat)

1. 右键点击`winget_install.bat`，选择"以管理员身份运行"
2. 脚本会显示将要安装的软件列表
3. 输入"Y"确认安装，或"N"取消
4. 安装过程会自动进行，并生成日志文件

### 自定义安装脚本 (winget_custom_install.bat)

1. 首次运行时，脚本会创建`software_list.txt`示例文件
2. 编辑`software_list.txt`，根据需要添加或删除软件
   - 每行一个软件ID
   - 使用#开头的行为注释
   - 格式: `[软件ID] # [可选说明]`
3. 再次运行脚本进行安装
4. 输入"Y"确认安装，或"N"取消

## 查找软件ID

要查找软件的ID，可以：

1. 使用命令：`winget search [软件名称]`
2. 访问网站：[winget.run](https://winget.run/) 或 [winstall.app](https://winstall.app/)
3. 参考 [Microsoft 应用程序目录](https://learn.microsoft.com/zh-cn/windows/package-manager/package/)

## 常用WinGet命令

```
winget search [关键词]    # 搜索软件
winget install [ID]      # 安装软件
winget uninstall [ID]    # 卸载软件
winget upgrade           # 检查可更新的软件
winget upgrade --all     # 更新所有软件
winget list              # 列出已安装的软件
winget show [ID]         # 显示软件详情
```

## 常见问题

1. **未找到WinGet命令**
   - 确保你的Windows版本支持WinGet
   - 尝试运行：`Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe`

2. **安装失败**
   - 检查是否以管理员身份运行
   - 查看日志文件了解详细错误信息
   - 确认网络连接正常

3. **软件ID错误**
   - 使用`winget search`命令确认正确的软件ID
   - 软件ID区分大小写，请确保输入准确

## 优势与局限性

### 优势
- 免费：随Windows系统提供
- 简单高效：一键批量安装软件
- 安全可靠：软件来源于官方或可信渠道
- 无需手动下载：自动处理下载和安装过程

### 局限性
- 软件源有限：某些小众软件可能不在WinGet仓库中
- 命令行操作：对不熟悉命令行的用户有一定门槛
- 更新速度：新发布的软件可能不会立即出现在WinGet仓库

## 自定义开发

如果你想修改脚本，可以：
- 在`winget_install.bat`中修改预设软件列表
- 调整安装参数以适应特定需求
- 添加额外的错误处理或功能

## 相关资源

- [WinGet 官方文档](https://learn.microsoft.com/zh-cn/windows/package-manager/)
- [WinGet GitHub 仓库](https://github.com/microsoft/winget-cli)
- [Winget.run - 在线软件包搜索](https://winget.run/)
- [Winstall - 图形化WinGet前端](https://winstall.app/) 