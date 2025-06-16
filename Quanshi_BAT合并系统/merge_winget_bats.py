#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
这是一个使用quanshi.py合并所有winget相关bat文件的示例脚本
"""

import os
import subprocess
import sys

def main():
    # 获取脚本所在目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 检查quanshi.py是否存在
    quanshi_path = os.path.join(script_dir, 'quanshi.py')
    if not os.path.exists(quanshi_path):
        print(f"错误: 未找到quanshi.py文件，请确保它与此脚本在同一目录下\n路径: {quanshi_path}")
        sys.exit(1)
    
    # 找出所有winget相关的bat文件
    winget_dir = os.path.join(os.path.dirname(script_dir), 'WinGet自动安装脚本')
    if not os.path.exists(winget_dir):
        print(f"错误: 未找到WinGet自动安装脚本目录\n路径: {winget_dir}")
        winget_dir = script_dir  # 如果找不到，就在当前目录查找
    
    winget_bats = [f for f in os.listdir(winget_dir) if f.lower().startswith('winget_') and f.lower().endswith('.bat')]
    winget_bat_paths = [os.path.join(winget_dir, f) for f in winget_bats]
    
    if not winget_bats:
        print(f"未找到任何winget相关的bat文件，搜索目录: {winget_dir}")
        sys.exit(1)
    
    print(f"找到 {len(winget_bats)} 个winget相关的bat文件:")
    for i, bat in enumerate(winget_bats, 1):
        print(f"{i}. {bat}")
    
    # 输出文件路径
    output_file = os.path.join(winget_dir, 'merged.bat')
    
    # 使用quanshi.py合并这些文件
    cmd = [
        sys.executable,  # 当前Python解释器
        quanshi_path,
        '-o', output_file,  # 输出文件名
        '-f'
    ] + winget_bat_paths + ['--backup']  # 添加文件列表和备份选项
    
    print("\n执行命令:")
    print(" ".join(cmd))
    
    try:
        result = subprocess.run(cmd, check=True)
        print(f"\n合并完成! 输出文件: {output_file}")
    except subprocess.CalledProcessError as e:
        print(f"\n错误: 合并过程中出现问题 (错误代码: {e.returncode})")
        sys.exit(1)

if __name__ == '__main__':
    main() 