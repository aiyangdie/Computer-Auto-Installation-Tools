# 电脑自动安装程序项目集合 (Computer Auto-Installation Tools)

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)
![Language](https://img.shields.io/badge/language-Python%20%7C%20Batch-yellow.svg)

这个项目集合包含四个相关的子项目，用于Windows系统软件的自动化安装和管理。
(This project collection contains four related sub-projects for automated installation and management of Windows system software.)

## 项目结构 (Project Structure)

本项目包含以下四个子项目：

### 1. Quanshi_BAT合并系统 (BAT Merger System)

BAT批处理文件合并工具，提供命令行和图形界面两种使用方式。

- 自动合并多个BAT文件为一个完整文件
- 为每个文件添加清晰的分隔标记
- 支持UTF-8和GBK编码
- 提供命令行和GUI两种操作方式

### 2. WinGet自动安装脚本 (WinGet Auto-Installation Scripts)

基于Windows Package Manager (WinGet)的批处理脚本集合，用于快速批量安装Windows软件。

- 预设软件列表安装脚本
- 自定义软件列表安装脚本
- 按分类安装软件
- 软件更新、搜索、导出导入等功能

### 3. 高级自动安装程序 (Advanced Auto-Installation Program)

功能强大的自动安装工具，支持GUI界面和命令行两种模式。

- 智能安装，自动尝试多种静默安装参数
- 自定义过滤条件（文件名、大小等）
- 针对常见软件提供特定的安装参数
- 详细记录安装日志

### 4. 软件下载与安装管理器 (Software Download & Installation Manager)

综合性的软件下载和安装管理工具，可以自动从网络下载并安装常用软件。

- 自动检测操作系统类型
- 支持并发下载多个软件
- 针对不同类型的软件提供特定的安装方法
- 支持Windows、macOS和Linux系统

## 使用场景 (Use Cases)

1. 新电脑批量软件安装
2. 系统重装后快速恢复软件环境
3. IT部门批量部署标准软件环境
4. 个人常用软件一键安装

## 系统要求 (System Requirements)

- Windows 10/11 操作系统
- Python 3.6或更高版本
- WinGet包管理器（Windows 10 1709及以上版本自带）

## 安装说明 (Installation)

```bash
# 克隆仓库
git clone https://github.com/yourusername/computer-auto-installation-tools.git

# 进入项目目录
cd computer-auto-installation-tools

# 安装依赖
pip install -r requirements.txt
```

## 文件说明 (File Description)

| 文件名 | 描述 |
|--------|------|
| quanshi.py | 命令行版本的BAT文件合并工具 |
| quanshi_gui.py | 图形界面版本的BAT文件合并工具 |
| merge_winget_bats.py | 自动合并winget相关BAT文件的示例脚本 |
| quanshi_launcher.py | 启动器，用于选择不同版本的工具 |
| quanshi_readme.md | 命令行版本的使用说明 |
| quanshi_gui_readme.md | 图形界面版本的使用说明 |
| README.md | 主要说明文档 |

## 快速开始 (Quick Start)

```bash
# 启动合并工具启动器
python quanshi_launcher.py

# 或直接启动GUI版本
python quanshi_gui.py
```

## 注意事项 (Notes)

- 如果文件无法以UTF-8编码读取，程序会尝试使用GBK编码
- 建议在合并重要文件前使用备份选项创建备份
- 合并大量文件可能会导致输出文件较大，请确保有足够的磁盘空间

## 贡献指南 (Contributing)

欢迎提交问题和合并请求。对于重大更改，请先开issue讨论您想要更改的内容。

## 许可证 (License)

本项目采用MIT许可证 - 详情请参阅 [LICENSE](LICENSE) 文件。

## 联系方式 (Contact)

如有任何问题或建议，请通过GitHub Issues联系我们。 