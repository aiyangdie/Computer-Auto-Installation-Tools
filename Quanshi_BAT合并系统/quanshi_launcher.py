#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Quanshi Launcher - 启动器，用于选择命令行版本或GUI版本
"""

import os
import sys
import importlib.util
import subprocess

# 获取脚本所在目录
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

def check_module_exists(module_name):
    """检查模块是否存在"""
    return importlib.util.find_spec(module_name) is not None

def check_file_exists(file_path):
    """检查文件是否存在"""
    return os.path.isfile(file_path)

def clear_screen():
    """清除屏幕"""
    os.system('cls' if os.name == 'nt' else 'clear')

def print_header():
    """打印程序标题"""
    clear_screen()
    print("="*80)
    print("                       Quanshi - BAT文件合并工具")
    print("="*80)
    print("\n欢迎使用Quanshi BAT文件合并工具！\n")

def print_menu():
    """打印菜单"""
    print("请选择要启动的版本：\n")
    print("1. 命令行版本 (quanshi.py)")
    print("2. 图形界面版本 (quanshi_gui.py)")
    print("3. 运行示例脚本 (merge_winget_bats.py)")
    print("4. 查看帮助文档")
    print("0. 退出程序")
    print("\n")

def show_help():
    """显示帮助信息"""
    clear_screen()
    print("="*80)
    print("                       Quanshi - 帮助文档")
    print("="*80)
    print("\n选择合适的版本：\n")
    print("1. 命令行版本 (quanshi.py)")
    print("   - 适合熟悉命令行的用户")
    print("   - 支持批处理和脚本化操作")
    print("   - 可以通过参数精确控制合并行为")
    print("   - 使用方法: python quanshi.py -h 查看详细帮助\n")
    
    print("2. 图形界面版本 (quanshi_gui.py)")
    print("   - 适合不熟悉命令行的用户")
    print("   - 提供直观的文件选择和参数设置界面")
    print("   - 可视化操作，易于使用\n")
    
    print("3. 示例脚本 (merge_winget_bats.py)")
    print("   - 自动合并所有winget相关的BAT文件")
    print("   - 展示了如何在其他脚本中使用quanshi.py\n")
    
    input("\n按Enter键返回主菜单...")

def run_command_line_version():
    """运行命令行版本"""
    clear_screen()
    print("启动命令行版本...\n")
    
    quanshi_path = os.path.join(SCRIPT_DIR, "quanshi.py")
    if not check_file_exists(quanshi_path):
        print(f"错误: 找不到quanshi.py文件! 路径: {quanshi_path}")
        input("\n按Enter键返回主菜单...")
        return
    
    # 获取命令行参数
    print("请输入命令行参数 (直接按Enter使用默认参数):")
    args = input("> ")
    
    cmd = [sys.executable, quanshi_path] + args.split()
    subprocess.run(cmd)
    
    print("\n命令执行完成!")
    input("\n按Enter键返回主菜单...")

def run_gui_version():
    """运行图形界面版本"""
    quanshi_gui_path = os.path.join(SCRIPT_DIR, "quanshi_gui.py")
    if not check_file_exists(quanshi_gui_path):
        clear_screen()
        print(f"错误: 找不到quanshi_gui.py文件! 路径: {quanshi_gui_path}")
        input("\n按Enter键返回主菜单...")
        return
    
    # 检查tkinter是否可用
    if not check_module_exists("tkinter"):
        clear_screen()
        print("错误: 未找到tkinter模块，无法启动图形界面版本!")
        print("请安装tkinter后再试。在大多数Python安装中，tkinter是默认包含的。")
        input("\n按Enter键返回主菜单...")
        return
    
    # 启动GUI版本
    subprocess.run([sys.executable, quanshi_gui_path])

def run_example_script():
    """运行示例脚本"""
    clear_screen()
    print("启动示例脚本...\n")
    
    example_script_path = os.path.join(SCRIPT_DIR, "merge_winget_bats.py")
    if not check_file_exists(example_script_path):
        print(f"错误: 找不到merge_winget_bats.py文件! 路径: {example_script_path}")
        input("\n按Enter键返回主菜单...")
        return
    
    subprocess.run([sys.executable, example_script_path])
    
    print("\n脚本执行完成!")
    input("\n按Enter键返回主菜单...")

def main():
    """主函数"""
    while True:
        print_header()
        print_menu()
        
        choice = input("请输入选项 [0-4]: ").strip()
        
        if choice == '1':
            run_command_line_version()
        elif choice == '2':
            run_gui_version()
        elif choice == '3':
            run_example_script()
        elif choice == '4':
            show_help()
        elif choice == '0':
            print("\n感谢使用Quanshi BAT文件合并工具！再见！")
            sys.exit(0)
        else:
            clear_screen()
            print("错误: 无效的选项，请重试！")
            input("\n按Enter键继续...")

if __name__ == "__main__":
    main() 