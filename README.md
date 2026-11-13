<p align="center"><img src="assets/covers/44-Computer-Auto-Installation-Tools.jpg" alt="批量装机 项目封面" width="100%"></p>

<h1 align="center">Windows 软件批量安装工具包</h1>

<p align="center">四个互补的子项目，把「逐个手动装」变成「一次部署完」</p>

<p align="center">
  <a href="LICENSE">MIT 许可</a>
</p>

## 简介

新机初始化、重装系统恢复、IT 批量部署——三种场景各有一套工具：合并批处理、WinGet 清单安装、静默安装器、官网直下。四个子项目都在同一仓库，按需要取用。

## 功能

**一、BAT 合并系统**

- 把多个 BAT 合并为单一文件，自动加分隔标记与文件头注释
- UTF-8 / GBK 双编码自动回退
- CLI 与 GUI 双模式

**二、WinGet 自动安装脚本**

- 按分类批量安装（开发工具 / 办公 / 浏览器等）
- 批量更新、搜索、导出导入配置
- 定时更新计划任务、卸载管理、安装报告

**三、高级自动安装程序**

- 自动尝试 10+ 种常见静默安装参数
- Chrome / Python / Git / VS Code 等预设专属参数
- 文件名正则过滤 + 文件大小范围筛选，详细安装日志
- Tkinter GUI 与 CLI 双模式

**四、软件下载与安装管理器**

- 从官网抓取最新版下载链接（Chrome / Python / VS Code / Notepad++）
- 多线程并发下载（ThreadPoolExecutor）
- JSON 配置驱动，可跨平台运行

## 技术栈

Python 3 · Windows Batch · Tkinter / PyQt5 ｜ WinGet ｜ Requests / BeautifulSoup ｜ `concurrent.futures` / tqdm ｜ PyInstaller

## 快速开始

```bash
git clone https://github.com/aiyangdie/Computer-Auto-Installation-Tools.git
cd Computer-Auto-Installation-Tools
pip install -r requirements.txt
```

```bash
# BAT 合并：启动器 / GUI / CLI
python Quanshi_BAT合并系统/quanshi_launcher.py
python Quanshi_BAT合并系统/quanshi_gui.py
python Quanshi_BAT合并系统/quanshi.py -d ./bat目录 -o merged.bat

# WinGet 主控菜单
WinGet自动安装脚本\winget_master.bat

# 高级静默安装（GUI / CLI）
python 高级自动安装程序/advanced_auto_install.py
python 高级自动安装程序/advanced_auto_install.py -d ./exe目录 -s

# 官网直下安装管理器
python 软件下载与安装管理器/auto_software_installer.py -c config.json
```

## 项目结构

```
Quanshi_BAT合并系统/        BAT 合并（CLI / GUI / 启动器）
WinGet自动安装脚本/         11 个功能菜单脚本（安装、更新、搜索、报告、修复…）
高级自动安装程序/            静默安装器 + exe 目录 + install_logs
软件下载与安装管理器/         官网抓取 + 多线程下载 + JSON 配置
requirements.txt / LICENSE
```

## 说明

批量安装会改动系统已装软件，建议先在测试机验证参数；静默安装并非所有安装包都支持。

## 许可证

[MIT](LICENSE)
