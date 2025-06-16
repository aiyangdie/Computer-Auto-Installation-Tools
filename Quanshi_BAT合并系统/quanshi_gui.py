#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Quanshi GUI - BAT文件合并工具的图形界面版本
"""

import os
import sys
import shutil
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from datetime import datetime

class QuanshiGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Quanshi - BAT文件合并工具")
        self.root.geometry("800x600")
        self.root.minsize(700, 500)
        
        # 设置样式
        self.style = ttk.Style()
        self.style.configure("TButton", padding=6, relief="flat", background="#ccc")
        
        # 创建主框架
        self.main_frame = ttk.Frame(root, padding="10")
        self.main_frame.pack(fill=tk.BOTH, expand=True)
        
        # 创建输入输出框架
        self.io_frame = ttk.Frame(self.main_frame)
        self.io_frame.pack(fill=tk.X, pady=10)
        
        # 输入目录
        ttk.Label(self.io_frame, text="输入目录:").grid(row=0, column=0, sticky=tk.W, padx=5, pady=5)
        self.input_dir_var = tk.StringVar(value=os.getcwd())
        self.input_dir_entry = ttk.Entry(self.io_frame, textvariable=self.input_dir_var, width=50)
        self.input_dir_entry.grid(row=0, column=1, sticky=tk.EW, padx=5, pady=5)
        ttk.Button(self.io_frame, text="浏览...", command=self.browse_input_dir).grid(row=0, column=2, padx=5, pady=5)
        
        # 输出文件
        ttk.Label(self.io_frame, text="输出文件:").grid(row=1, column=0, sticky=tk.W, padx=5, pady=5)
        self.output_file_var = tk.StringVar(value=os.path.join(os.getcwd(), "merged.bat"))
        self.output_file_entry = ttk.Entry(self.io_frame, textvariable=self.output_file_var, width=50)
        self.output_file_entry.grid(row=1, column=1, sticky=tk.EW, padx=5, pady=5)
        ttk.Button(self.io_frame, text="浏览...", command=self.browse_output_file).grid(row=1, column=2, padx=5, pady=5)
        
        # 选项框架
        self.options_frame = ttk.LabelFrame(self.main_frame, text="选项")
        self.options_frame.pack(fill=tk.X, pady=10)
        
        # 添加分隔标记选项
        self.add_headers_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(self.options_frame, text="添加文件分隔标记", variable=self.add_headers_var).grid(row=0, column=0, sticky=tk.W, padx=10, pady=5)
        
        # 创建备份选项
        self.create_backup_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(self.options_frame, text="创建输出文件备份", variable=self.create_backup_var).grid(row=0, column=1, sticky=tk.W, padx=10, pady=5)
        
        # 文件列表框架
        self.files_frame = ttk.LabelFrame(self.main_frame, text="BAT文件列表")
        self.files_frame.pack(fill=tk.BOTH, expand=True, pady=10)
        
        # 文件列表
        self.file_listbox_frame = ttk.Frame(self.files_frame)
        self.file_listbox_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        self.file_listbox = tk.Listbox(self.file_listbox_frame, selectmode=tk.MULTIPLE, bg="white")
        self.file_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        # 添加滚动条
        scrollbar = ttk.Scrollbar(self.file_listbox_frame, orient=tk.VERTICAL, command=self.file_listbox.yview)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.file_listbox.config(yscrollcommand=scrollbar.set)
        
        # 按钮框架
        self.buttons_frame = ttk.Frame(self.files_frame)
        self.buttons_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Button(self.buttons_frame, text="刷新列表", command=self.refresh_file_list).pack(side=tk.LEFT, padx=5)
        ttk.Button(self.buttons_frame, text="全选", command=self.select_all).pack(side=tk.LEFT, padx=5)
        ttk.Button(self.buttons_frame, text="取消全选", command=self.deselect_all).pack(side=tk.LEFT, padx=5)
        ttk.Button(self.buttons_frame, text="选择以winget_开头的文件", command=self.select_winget).pack(side=tk.LEFT, padx=5)
        
        # 操作按钮框架
        self.action_frame = ttk.Frame(self.main_frame)
        self.action_frame.pack(fill=tk.X, pady=10)
        
        ttk.Button(self.action_frame, text="合并文件", command=self.merge_files).pack(side=tk.RIGHT, padx=5)
        
        # 状态栏
        self.status_var = tk.StringVar()
        self.status_bar = ttk.Label(root, textvariable=self.status_var, relief=tk.SUNKEN, anchor=tk.W)
        self.status_bar.pack(side=tk.BOTTOM, fill=tk.X)
        
        # 初始化文件列表
        self.refresh_file_list()
        
    def browse_input_dir(self):
        directory = filedialog.askdirectory(initialdir=self.input_dir_var.get())
        if directory:
            self.input_dir_var.set(directory)
            self.refresh_file_list()
    
    def browse_output_file(self):
        filename = filedialog.asksaveasfilename(
            initialdir=os.path.dirname(self.output_file_var.get()),
            initialfile=os.path.basename(self.output_file_var.get()),
            defaultextension=".bat",
            filetypes=[("BAT Files", "*.bat"), ("All Files", "*.*")]
        )
        if filename:
            self.output_file_var.set(filename)
    
    def refresh_file_list(self):
        self.file_listbox.delete(0, tk.END)
        try:
            directory = self.input_dir_var.get()
            bat_files = [f for f in os.listdir(directory) if f.lower().endswith('.bat')]
            bat_files.sort()
            for file in bat_files:
                self.file_listbox.insert(tk.END, file)
            self.status_var.set(f"找到 {len(bat_files)} 个BAT文件")
        except Exception as e:
            self.status_var.set(f"错误: {str(e)}")
            messagebox.showerror("错误", f"无法读取目录: {str(e)}")
    
    def select_all(self):
        self.file_listbox.select_set(0, tk.END)
    
    def deselect_all(self):
        self.file_listbox.selection_clear(0, tk.END)
    
    def select_winget(self):
        self.file_listbox.selection_clear(0, tk.END)
        for i in range(self.file_listbox.size()):
            if self.file_listbox.get(i).lower().startswith('winget_'):
                self.file_listbox.selection_set(i)
    
    def merge_files(self):
        selected_indices = self.file_listbox.curselection()
        if not selected_indices:
            messagebox.showwarning("警告", "请至少选择一个BAT文件")
            return
        
        selected_files = [self.file_listbox.get(i) for i in selected_indices]
        output_file = self.output_file_var.get()
        
        # 检查输出文件是否存在，如果需要则创建备份
        if os.path.exists(output_file) and self.create_backup_var.get():
            backup_path = f"{output_file}.bak.{datetime.now().strftime('%Y%m%d%H%M%S')}"
            try:
                shutil.copy2(output_file, backup_path)
                self.status_var.set(f"创建备份: {backup_path}")
            except Exception as e:
                messagebox.showwarning("警告", f"无法创建备份: {str(e)}")
        
        try:
            # 合并文件
            self.status_var.set("正在合并文件...")
            self.root.update_idletasks()
            
            input_dir = self.input_dir_var.get()
            bat_files = [os.path.join(input_dir, f) for f in selected_files]
            
            self.merge_bat_files(output_file, bat_files, self.add_headers_var.get())
            
            self.status_var.set(f"成功合并 {len(selected_files)} 个文件到 {output_file}")
            messagebox.showinfo("成功", f"成功合并 {len(selected_files)} 个文件到 {output_file}")
        except Exception as e:
            self.status_var.set(f"错误: {str(e)}")
            messagebox.showerror("错误", f"合并过程中出现错误: {str(e)}")
    
    def merge_bat_files(self, output_file, bat_files, add_headers=True):
        """合并多个.bat文件到一个文件"""
        with open(output_file, 'w', encoding='utf-8') as outfile:
            # 写入头部
            outfile.write('@echo off\n')
            outfile.write(':: Merged BAT file created by Quanshi GUI\n')
            outfile.write(f':: Created on {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
            outfile.write(':: Contains the following files:\n')
            
            for bat_file in bat_files:
                outfile.write(f'::   - {os.path.basename(bat_file)}\n')
            
            outfile.write('\n')
            
            # 合并文件
            for bat_file in bat_files:
                if not os.path.exists(bat_file):
                    print(f"Warning: File {bat_file} not found, skipping.")
                    continue
                    
                if add_headers:
                    outfile.write('\n')
                    outfile.write(':' + '='*78 + '\n')
                    outfile.write(f':: START OF {os.path.basename(bat_file)}\n')
                    outfile.write(':' + '='*78 + '\n\n')
                
                try:
                    with open(bat_file, 'r', encoding='utf-8') as infile:
                        # 跳过@echo off行（如果存在）
                        first_line = infile.readline()
                        if not first_line.lower().strip() == '@echo off':
                            outfile.write(first_line)
                        
                        # 复制剩余内容
                        for line in infile:
                            outfile.write(line)
                except UnicodeDecodeError:
                    # 如果UTF-8失败，尝试使用GBK编码
                    with open(bat_file, 'r', encoding='gbk') as infile:
                        first_line = infile.readline()
                        if not first_line.lower().strip() == '@echo off':
                            outfile.write(first_line)
                        for line in infile:
                            outfile.write(line)
                
                if add_headers:
                    outfile.write('\n')
                    outfile.write(':' + '='*78 + '\n')
                    outfile.write(f':: END OF {os.path.basename(bat_file)}\n')
                    outfile.write(':' + '='*78 + '\n')

def main():
    root = tk.Tk()
    app = QuanshiGUI(root)
    root.mainloop()

if __name__ == '__main__':
    main() 