import os
import subprocess
import logging
import time
import argparse
from datetime import datetime
import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import threading
import sys
import re

# 配置日志
def setup_logging(log_dir="install_logs"):
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
    
    log_file = os.path.join(log_dir, f"install_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt")
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
    return log_file

# 查找exe文件
def find_exe_files(root_dir, include_subfolders=False, name_filter=None, size_min=None, size_max=None):
    """查找指定目录中的所有exe文件，可应用过滤条件"""
    exe_folder = os.path.join(root_dir, "exe")
    if not os.path.exists(exe_folder):
        logging.error(f"exe文件夹不存在: {exe_folder}")
        return []
    
    exe_files = []
    
    # 定义搜索函数，支持递归
    def search_exes(folder):
        for item in os.listdir(folder):
            full_path = os.path.join(folder, item)
            
            # 如果是文件夹且需要包含子文件夹
            if os.path.isdir(full_path) and include_subfolders:
                search_exes(full_path)
                continue
                
            # 非exe文件跳过
            if not item.lower().endswith(".exe"):
                continue
                
            # 应用名称过滤
            if name_filter and not re.search(name_filter, item, re.IGNORECASE):
                continue
                
            # 应用大小过滤
            if size_min is not None or size_max is not None:
                file_size_mb = os.path.getsize(full_path) / (1024 * 1024)  # 转换为MB
                
                if size_min is not None and file_size_mb < size_min:
                    continue
                    
                if size_max is not None and file_size_mb > size_max:
                    continue
            
            # 通过所有过滤条件，添加到列表
            exe_files.append(full_path)
    
    # 开始搜索
    search_exes(exe_folder)
    return exe_files

# 安装exe文件
def install_exe(exe_path, timeout=300, use_defaults=True):
    """尝试安装exe文件，使用常见的静默安装参数"""
    file_name = os.path.basename(exe_path)
    logging.info(f"开始安装: {file_name}")
    
    # 常见的静默安装参数列表，按顺序尝试
    silent_args = [
        "/S",                  # 许多安装程序
        "/silent",             # 一些安装程序
        "/quiet",              # 微软安装程序
        "/verysilent",         # Inno Setup
        "/passive",            # MSI安装程序
        "--silent",            # 一些安装程序
        "-s",                  # 一些安装程序
        "-q",                  # 一些安装程序
        "/q",                  # 微软安装程序
        "/AUTO"                # 一些安装程序
    ]
    
    # 对于某些特定程序的特殊处理
    if "vcredist" in file_name.lower() or "vc_redist" in file_name.lower():
        silent_args = ["/quiet", "/norestart"]
    elif "microsoft" in file_name.lower() and "edge" in file_name.lower():
        silent_args = ["/silent", "/install"]
    elif "git" in file_name.lower():
        silent_args = ["/VERYSILENT", "/NORESTART", "/NOCANCEL", "/SP-"]
    elif "python" in file_name.lower():
        silent_args = ["/quiet", "InstallAllUsers=1", "PrependPath=1", "Include_test=0"]
    elif "nvidia" in file_name.lower():
        silent_args = ["-s", "-noreboot"]
    elif "visual" in file_name.lower() and "studio" in file_name.lower():
        silent_args = ["--quiet", "--norestart"]
    elif "chrome" in file_name.lower():
        silent_args = ["/silent", "/install"]
    elif "firefox" in file_name.lower():
        silent_args = ["-ms"]
    elif "7z" in file_name.lower() or "winrar" in file_name.lower() or "bandizip" in file_name.lower():
        silent_args = ["/S"]
    elif "office" in file_name.lower():
        silent_args = ["/configure", "configuration.xml"]
    elif "jdk" in file_name.lower() or "java" in file_name.lower():
        silent_args = ["/s"]
    elif "wechat" in file_name.lower() or "qq" in file_name.lower():
        # 这些程序可能需要特殊处理，有些可能不支持静默安装
        silent_args = ["/S"]
    
    success = False
    
    # 如果需要使用默认安装（不使用静默参数）
    if not use_defaults:
        try:
            logging.info(f"以交互方式运行: {file_name}")
            subprocess.Popen([exe_path], shell=True)
            # 因为交互式安装需要用户操作，所以不等待其完成
            logging.info(f"已启动交互式安装: {file_name}，请手动完成安装")
            return True
        except Exception as e:
            logging.error(f"启动交互式安装 {file_name} 失败: {str(e)}")
            return False
    
    # 首先尝试直接运行，不加参数（有些程序不需要参数）
    try:
        logging.info(f"尝试直接运行: {file_name}")
        result = subprocess.run([exe_path], 
                               shell=True, 
                               capture_output=True, 
                               text=True, 
                               timeout=timeout)
        if result.returncode == 0:
            logging.info(f"成功安装: {file_name} (无参数)")
            return True
    except subprocess.TimeoutExpired:
        logging.warning(f"{file_name} 安装超时，尝试使用静默参数")
    except Exception as e:
        logging.warning(f"直接运行 {file_name} 失败: {str(e)}")
    
    # 尝试每种静默安装参数
    for args in silent_args:
        try:
            cmd = [exe_path]
            # 将参数拆分成列表添加
            for arg in args.split():
                cmd.append(arg)
                
            logging.info(f"尝试安装 {file_name} 使用参数: {args}")
            result = subprocess.run(cmd, 
                                   shell=True, 
                                   capture_output=True, 
                                   text=True, 
                                   timeout=timeout)
            
            if result.returncode == 0:
                logging.info(f"成功安装: {file_name} 使用参数: {args}")
                success = True
                break
            else:
                logging.warning(f"参数 {args} 安装失败: {result.stderr}")
        except subprocess.TimeoutExpired:
            logging.warning(f"{file_name} 使用参数 {args} 安装超时")
        except Exception as e:
            logging.warning(f"使用参数 {args} 安装 {file_name} 时出错: {str(e)}")
    
    if not success:
        logging.error(f"所有尝试都失败，无法安装: {file_name}")
    
    return success

# 命令行界面
def cli_mode():
    parser = argparse.ArgumentParser(description="自动安装exe文件")
    parser.add_argument("-d", "--directory", help="指定根目录，默认为脚本所在目录", default=os.path.dirname(os.path.abspath(__file__)))
    parser.add_argument("-s", "--subfolders", help="是否包含子文件夹中的exe文件", action="store_true")
    parser.add_argument("-f", "--filter", help="文件名过滤，支持正则表达式")
    parser.add_argument("--min-size", help="最小文件大小(MB)", type=float)
    parser.add_argument("--max-size", help="最大文件大小(MB)", type=float)
    parser.add_argument("-t", "--timeout", help="安装超时时间(秒)", type=int, default=300)
    parser.add_argument("-i", "--interactive", help="使用交互模式安装，而非静默安装", action="store_true")
    
    args = parser.parse_args()
    
    # 设置日志
    log_file = setup_logging()
    
    # 查找exe文件
    exe_files = find_exe_files(
        args.directory, 
        include_subfolders=args.subfolders,
        name_filter=args.filter,
        size_min=args.min_size,
        size_max=args.max_size
    )
    
    if not exe_files:
        print("未找到符合条件的exe文件")
        return
    
    print(f"找到 {len(exe_files)} 个安装程序，准备开始安装。")
    if not args.interactive:
        print("将使用静默安装模式。")
    else:
        print("将使用交互式安装模式，需要手动操作。")
    
    print("按Enter键继续...")
    input()
    
    # 安装每个exe文件
    success_count = 0
    fail_count = 0
    
    for exe_file in exe_files:
        try:
            if install_exe(exe_file, timeout=args.timeout, use_defaults=not args.interactive):
                success_count += 1
                # 安装完成后暂停一下，避免系统资源过度占用
                time.sleep(2)
            else:
                fail_count += 1
        except Exception as e:
            logging.error(f"安装 {os.path.basename(exe_file)} 时发生错误: {str(e)}")
            fail_count += 1
    
    # 总结
    logging.info(f"安装完成。成功: {success_count}, 失败: {fail_count}")
    print(f"\n安装完成。成功: {success_count}, 失败: {fail_count}")
    print(f"详细日志可在 {log_file} 中查看")

# GUI界面
class InstallerGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("高级自动安装程序")
        self.root.geometry("800x600")
        
        # 设置日志
        self.log_file = setup_logging()
        
        # 默认为脚本所在目录
        self.root_dir = os.path.dirname(os.path.abspath(__file__))
        
        # 创建界面
        self.create_widgets()
        
        # 默认加载exe文件列表
        self.refresh_exe_list()
        
    def create_widgets(self):
        # 创建框架
        top_frame = ttk.Frame(self.root, padding=10)
        top_frame.pack(fill=tk.X)
        
        # 目录选择
        ttk.Label(top_frame, text="根目录:").pack(side=tk.LEFT)
        self.dir_var = tk.StringVar(value=self.root_dir)
        ttk.Entry(top_frame, textvariable=self.dir_var, width=50).pack(side=tk.LEFT, padx=5)
        ttk.Button(top_frame, text="浏览...", command=self.browse_directory).pack(side=tk.LEFT, padx=5)
        ttk.Button(top_frame, text="刷新", command=self.refresh_exe_list).pack(side=tk.LEFT, padx=5)
        
        # 过滤选项框架
        filter_frame = ttk.LabelFrame(self.root, text="过滤选项", padding=10)
        filter_frame.pack(fill=tk.X, padx=10, pady=5)
        
        # 名称过滤
        ttk.Label(filter_frame, text="名称过滤:").grid(row=0, column=0, sticky=tk.W)
        self.name_filter = tk.StringVar()
        ttk.Entry(filter_frame, textvariable=self.name_filter, width=30).grid(row=0, column=1, padx=5, pady=2)
        
        # 大小过滤
        ttk.Label(filter_frame, text="大小范围(MB):").grid(row=1, column=0, sticky=tk.W)
        size_frame = ttk.Frame(filter_frame)
        size_frame.grid(row=1, column=1, sticky=tk.W)
        
        self.min_size = tk.StringVar()
        ttk.Entry(size_frame, textvariable=self.min_size, width=10).pack(side=tk.LEFT)
        ttk.Label(size_frame, text="至").pack(side=tk.LEFT, padx=5)
        self.max_size = tk.StringVar()
        ttk.Entry(size_frame, textvariable=self.max_size, width=10).pack(side=tk.LEFT)
        
        # 子文件夹选项
        self.include_subfolders = tk.BooleanVar(value=False)
        ttk.Checkbutton(filter_frame, text="包含子文件夹", variable=self.include_subfolders).grid(row=0, column=2, padx=10)
        
        # 交互模式选项
        self.interactive_mode = tk.BooleanVar(value=False)
        ttk.Checkbutton(filter_frame, text="交互式安装(非静默)", variable=self.interactive_mode).grid(row=1, column=2, padx=10)
        
        # 超时设置
        ttk.Label(filter_frame, text="安装超时(秒):").grid(row=2, column=0, sticky=tk.W)
        self.timeout = tk.StringVar(value="300")
        ttk.Entry(filter_frame, textvariable=self.timeout, width=10).grid(row=2, column=1, sticky=tk.W)
        
        # 应用过滤按钮
        ttk.Button(filter_frame, text="应用过滤", command=self.apply_filters).grid(row=2, column=2, pady=5)
        
        # 文件列表框架
        list_frame = ttk.LabelFrame(self.root, text="可安装程序列表", padding=10)
        list_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        # 创建带滚动条的列表
        self.tree = ttk.Treeview(list_frame, columns=("size", "path"), show="headings")
        self.tree.heading("size", text="大小(MB)")
        self.tree.heading("path", text="路径")
        self.tree.column("size", width=100)
        self.tree.column("path", width=500)
        
        scrollbar = ttk.Scrollbar(list_frame, orient=tk.VERTICAL, command=self.tree.yview)
        self.tree.configure(yscrollcommand=scrollbar.set)
        
        self.tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # 全选/取消全选
        select_frame = ttk.Frame(self.root, padding=5)
        select_frame.pack(fill=tk.X, padx=10)
        
        self.select_all_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(select_frame, text="全选/取消全选", variable=self.select_all_var, 
                        command=self.toggle_select_all).pack(side=tk.LEFT)
        
        # 状态信息
        self.status_var = tk.StringVar(value="就绪")
        ttk.Label(select_frame, textvariable=self.status_var).pack(side=tk.RIGHT)
        
        # 操作按钮
        button_frame = ttk.Frame(self.root, padding=10)
        button_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Button(button_frame, text="安装选中项", command=self.install_selected).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="查看日志", command=self.view_log).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="退出", command=self.root.destroy).pack(side=tk.RIGHT, padx=5)
    
    def browse_directory(self):
        directory = filedialog.askdirectory(initialdir=self.root_dir)
        if directory:
            self.dir_var.set(directory)
            self.root_dir = directory
            self.refresh_exe_list()
    
    def refresh_exe_list(self):
        # 清空现有列表
        for item in self.tree.get_children():
            self.tree.delete(item)
        
        # 查找exe文件
        try:
            min_size = float(self.min_size.get()) if self.min_size.get() else None
            max_size = float(self.max_size.get()) if self.max_size.get() else None
        except ValueError:
            messagebox.showerror("输入错误", "请输入有效的文件大小数值")
            min_size = max_size = None
        
        exe_files = find_exe_files(
            self.root_dir,
            include_subfolders=self.include_subfolders.get(),
            name_filter=self.name_filter.get(),
            size_min=min_size,
            size_max=max_size
        )
        
        # 填充列表
        for exe_file in exe_files:
            size_mb = os.path.getsize(exe_file) / (1024 * 1024)
            size_str = f"{size_mb:.2f}"
            self.tree.insert("", tk.END, values=(size_str, exe_file), tags=("selected",))
        
        # 更新状态
        self.status_var.set(f"找到 {len(exe_files)} 个安装程序")
        
        # 设置选中样式
        self.tree.tag_configure("selected", background="#E0E0E0")
    
    def apply_filters(self):
        self.refresh_exe_list()
    
    def toggle_select_all(self):
        select_all = self.select_all_var.get()
        for item in self.tree.get_children():
            if select_all:
                self.tree.item(item, tags=("selected",))
            else:
                self.tree.item(item, tags=())
    
    def install_selected(self):
        selected_items = []
        for item in self.tree.get_children():
            if "selected" in self.tree.item(item, "tags"):
                selected_items.append(item)
        
        if not selected_items:
            messagebox.showinfo("提示", "请先选择要安装的程序")
            return
        
        # 确认安装
        if not messagebox.askyesno("确认", f"准备安装 {len(selected_items)} 个程序，是否继续？"):
            return
        
        # 禁用界面元素
        for widget in self.root.winfo_children():
            if isinstance(widget, ttk.Frame) or isinstance(widget, ttk.LabelFrame):
                for child in widget.winfo_children():
                    if isinstance(child, ttk.Button) or isinstance(child, ttk.Entry):
                        child.configure(state="disabled")
        
        # 创建安装线程
        threading.Thread(target=self.install_thread, args=(selected_items,), daemon=True).start()
    
    def install_thread(self, selected_items):
        success_count = 0
        fail_count = 0
        
        try:
            timeout = int(self.timeout.get())
        except ValueError:
            timeout = 300  # 默认值
        
        for i, item in enumerate(selected_items):
            try:
                exe_path = self.tree.item(item, "values")[1]
                self.status_var.set(f"正在安装 ({i+1}/{len(selected_items)}): {os.path.basename(exe_path)}")
                
                if install_exe(exe_path, timeout=timeout, use_defaults=not self.interactive_mode.get()):
                    success_count += 1
                    # 更新UI，标记为已安装
                    self.tree.item(item, tags=("installed",))
                    self.tree.tag_configure("installed", background="#C0FFC0")
                else:
                    fail_count += 1
                    # 更新UI，标记为失败
                    self.tree.item(item, tags=("failed",))
                    self.tree.tag_configure("failed", background="#FFC0C0")
                
                # 安装完成后暂停一下，避免系统资源过度占用
                time.sleep(2)
            except Exception as e:
                logging.error(f"安装时发生错误: {str(e)}")
                fail_count += 1
                # 更新UI，标记为失败
                self.tree.item(item, tags=("failed",))
                self.tree.tag_configure("failed", background="#FFC0C0")
        
        # 更新状态
        self.status_var.set(f"安装完成。成功: {success_count}, 失败: {fail_count}")
        
        # 启用界面元素
        for widget in self.root.winfo_children():
            if isinstance(widget, ttk.Frame) or isinstance(widget, ttk.LabelFrame):
                for child in widget.winfo_children():
                    if isinstance(child, ttk.Button) or isinstance(child, ttk.Entry):
                        child.configure(state="normal")
        
        # 显示完成消息
        messagebox.showinfo("安装完成", f"安装完成。\n成功: {success_count}\n失败: {fail_count}\n\n详细日志可在 {self.log_file} 中查看")
    
    def view_log(self):
        if os.path.exists(self.log_file):
            try:
                if sys.platform == 'win32':
                    os.startfile(self.log_file)
                elif sys.platform == 'darwin':  # macOS
                    subprocess.run(['open', self.log_file])
                else:  # Linux
                    subprocess.run(['xdg-open', self.log_file])
            except Exception as e:
                messagebox.showerror("错误", f"无法打开日志文件: {str(e)}")
        else:
            messagebox.showinfo("提示", "日志文件不存在")

# 主函数
def main():
    # 检查是否有命令行参数
    if len(sys.argv) > 1:
        # 命令行模式
        cli_mode()
    else:
        # GUI模式
        root = tk.Tk()
        app = InstallerGUI(root)
        root.mainloop()

if __name__ == "__main__":
    main()
