<div align="center">

# 💻 Computer-Auto-Installation-Tools

**Windows 软件自动安装工具包 — 四合一自动化部署解决方案**

<img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python"/>
<img src="https://img.shields.io/badge/Batch-4D274F?style=for-the-badge&logo=windows&logoColor=white" alt="Batch"/>
<img src="https://img.shields.io/badge/WinGet-0078D4?style=for-the-badge&logo=microsoft&logoColor=white" alt="WinGet"/>
<img src="https://img.shields.io/badge/Tkinter-FF6F00?style=for-the-badge&logo=qt&logoColor=white" alt="Tkinter"/>
<img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License"/>

</div>

---

## 📌 项目简介

Computer-Auto-Installation-Tools 是一套面向 Windows 系统的软件自动化安装与管理工具集合，包含四个功能互补的子项目。无论是新电脑初始化、系统重装恢复，还是 IT 部门批量部署，都能找到合适的工具，实现从「手动逐个安装」到「一键自动部署」的飞跃。

## ✨ 核心特性

### 🔧 子项目一：Quanshi BAT 合并系统
- 📦 将多个 BAT 批处理文件智能合并为单一文件
- 🏷️ 自动添加分隔标记与文件头注释
- 🔤 双编码支持（UTF-8 / GBK 自动回退）
- 🖥️ CLI + GUI 双模式操作

### 📦 子项目二：WinGet 自动安装脚本
- 🚀 基于 Windows Package Manager 的批量安装脚本集
- 📂 按分类安装（开发工具 / 办公软件 / 浏览器等）
- 🔄 软件更新、搜索、导出导入一站式管理
- ⏰ 创建定时更新计划任务
- 🗑️ 卸载管理与源配置

### ⚡ 子项目三：高级自动安装程序
- 🧠 智能静默安装 — 自动尝试 10+ 种常见 Silent Install 参数
- 🎯 针对常见软件（Chrome / Python / Git / VS Code 等）预设专属参数
- 🔍 文件名正则过滤 + 文件大小范围筛选
- 📋 详细安装日志记录
- 🖼️ Tkinter GUI + CLI 双模式

### 🌐 子项目四：软件下载与安装管理器
- 🌍 自动从官网抓取最新版下载链接（Chrome / Python / VS Code / Notepad++）
- ⚡ 多线程并发下载（ThreadPoolExecutor）
- 🖥️ 跨平台支持（Windows / macOS / Linux）
- 📝 JSON 配置文件驱动，灵活定制软件列表

## 🛠️ 技术栈

| 类别 | 技术 |
|------|------|
| 语言 | Python 3 / Windows Batch |
| GUI | Tkinter / PyQt5 |
| 包管理 | WinGet (Windows Package Manager) |
| 网络爬虫 | Requests / BeautifulSoup |
| 下载管理 | concurrent.futures / tqdm |
| 打包 | PyInstaller |

## 🚀 快速开始

### 前置条件

- Windows 10/11 操作系统
- Python 3.6+
- WinGet（Windows 10 1709+ 自带）

### 安装步骤

```bash
git clone https://github.com/yourusername/Computer-Auto-Installation-Tools.git
cd Computer-Auto-Installation-Tools
pip install -r requirements.txt
```

### 运行命令

```bash
# BAT 合并工具（启动器选择 CLI / GUI）
python Quanshi_BAT合并系统/quanshi_launcher.py

# BAT 合并工具（直接启动 GUI）
python Quanshi_BAT合并系统/quanshi_gui.py

# BAT 合并工具（命令行模式）
python Quanshi_BAT合并系统/quanshi.py -d ./bat目录 -o merged.bat

# WinGet 软件管理中心
WinGet自动安装脚本\winget_master.bat

# 高级自动安装程序（GUI 模式）
python 高级自动安装程序/advanced_auto_install.py

# 高级自动安装程序（CLI 模式）
python 高级自动安装程序/advanced_auto_install.py -d ./exe目录 -s

# 软件下载与安装管理器
python 软件下载与安装管理器/auto_software_installer.py -c config.json
```

## 📂 项目结构

```
Computer-Auto-Installation-Tools/
├── Quanshi_BAT合并系统/
│   ├── quanshi.py                  # CLI 版 BAT 合并工具
│   ├── quanshi_gui.py              # GUI 版 BAT 合并工具
│   ├── quanshi_launcher.py         # 启动器（选择 CLI / GUI）
│   ├── merge_winget_bats.py        # WinGet BAT 自动合并示例
│   └── start_quanshi.bat           # 快速启动批处理
├── WinGet自动安装脚本/
│   ├── winget_master.bat           # 主控脚本（11 功能菜单）
│   ├── winget_install.bat          # 预设列表安装
│   ├── winget_custom_install.bat   # 自定义列表安装
│   ├── winget_categories.bat       # 分类安装
│   ├── winget_update.bat           # 批量更新
│   ├── winget_search.bat           # 搜索软件
│   ├── winget_export_import.bat    # 导出导入配置
│   ├── winget_scheduled_tasks.bat  # 定时任务
│   ├── winget_report.bat           # 安装报告
│   ├── winget_repair.bat           # 修复工具
│   └── winget_diff.bat             # 差异对比
├── 高级自动安装程序/
│   ├── advanced_auto_install.py    # 高级安装程序（GUI + CLI）
│   ├── auto_install.py             # 简化版安装程序
│   ├── exe/                        # 安装包存放目录
│   │   ├── Images/
│   │   └── Profiles/               # 安装配置文件
│   └── install_logs/               # 安装日志
├── 软件下载与安装管理器/
│   ├── auto_software_installer.py  # 下载安装管理器主程序
│   ├── default_config.json         # 默认配置
│   ├── config_example.json         # 配置示例
│   └── wxdump_work/
│       └── conf_auto.json
├── requirements.txt
├── LICENSE                         # MIT 许可证
└── README.md
```

## 🤝 贡献与许可证

欢迎提交 Issue 和 Pull Request 参与贡献！对于重大更改，请先开 Issue 讨论您想要更改的内容。

本项目基于 **MIT License** 开源，详见 [LICENSE](LICENSE) 文件。
