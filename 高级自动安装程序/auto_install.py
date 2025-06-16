import os
import subprocess
import logging
import time
from datetime import datetime

# 配置日志
log_dir = "install_logs"
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

def find_exe_files(root_dir):
    """查找指定目录中的所有exe文件"""
    exe_folder = os.path.join(root_dir, "exe")
    if not os.path.exists(exe_folder):
        logging.error(f"exe文件夹不存在: {exe_folder}")
        return []
    
    exe_files = []
    for file in os.listdir(exe_folder):
        if file.lower().endswith(".exe"):
            exe_files.append(os.path.join(exe_folder, file))
    
    return exe_files

def install_exe(exe_path):
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
    elif "wechat" in file_name.lower() or "qq" in file_name.lower():
        # 这些程序可能需要特殊处理，有些可能不支持静默安装
        silent_args = ["/S"]
    
    success = False
    
    # 首先尝试直接运行，不加参数（有些程序不需要参数）
    try:
        logging.info(f"尝试直接运行: {file_name}")
        result = subprocess.run([exe_path], 
                               shell=True, 
                               capture_output=True, 
                               text=True, 
                               timeout=300)  # 5分钟超时
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
                                   timeout=300)  # 5分钟超时
            
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

def main():
    """主函数"""
    logging.info("开始自动安装程序")
    
    # 获取当前脚本所在的目录作为根目录
    root_dir = os.path.dirname(os.path.abspath(__file__))
    logging.info(f"根目录: {root_dir}")
    
    # 查找所有exe文件
    exe_files = find_exe_files(root_dir)
    logging.info(f"找到 {len(exe_files)} 个exe文件")
    
    # 提示用户将要安装的程序数量
    print(f"找到 {len(exe_files)} 个安装程序，准备开始安装。")
    print("注意：一些程序可能会弹出安装界面需要手动操作。")
    print("按Enter键继续...")
    input()
    
    # 安装每个exe文件
    success_count = 0
    fail_count = 0
    
    for exe_file in exe_files:
        try:
            if install_exe(exe_file):
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
    print("按Enter键退出...")
    input()

if __name__ == "__main__":
    main() 