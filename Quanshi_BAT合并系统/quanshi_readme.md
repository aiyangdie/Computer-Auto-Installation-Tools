# Quanshi.py - BAT文件合并工具

这是一个用于合并多个BAT批处理文件的Python工具。

## 功能特点

- 自动合并目录下所有的.bat文件，或者指定特定文件进行合并
- 为每个文件添加清晰的分隔标记
- 自动跳过重复的`@echo off`命令
- 支持UTF-8和GBK编码的BAT文件
- 可选择是否创建输出文件的备份
- 可选择是否添加文件分隔标记

## 使用方法

### 基本用法

合并当前目录下所有BAT文件:

```
python quanshi.py
```

这将创建一个名为`merged.bat`的合并文件。

### 高级选项

```
python quanshi.py -o 输出文件名 -d 目录路径 -f 文件1 文件2 ... --no-headers --backup
```

参数说明:

- `-o, --output`: 指定输出文件名 (默认: merged.bat)
- `-d, --directory`: 指定要搜索BAT文件的目录 (默认: 当前目录)
- `-f, --files`: 指定要合并的特定BAT文件列表
- `--no-headers`: 不添加文件分隔标记
- `--backup`: 如果输出文件已存在，创建备份

### 示例

1. 合并指定的BAT文件:
   ```
   python quanshi.py -f winget_install.bat winget_update.bat -o combined.bat
   ```

2. 合并特定目录下的所有BAT文件并创建备份:
   ```
   python quanshi.py -d C:\scripts -o all_scripts.bat --backup
   ```

3. 合并文件但不添加分隔标记:
   ```
   python quanshi.py --no-headers
   ```

## 输出格式

合并后的文件将包含:
- 文件头部信息，包括创建时间和包含的原始文件列表
- 每个原始文件的内容，带有清晰的开始和结束标记（除非使用`--no-headers`选项）
- 自动去除重复的`@echo off`命令

## 注意事项

- 如果文件无法以UTF-8编码读取，程序会尝试使用GBK编码
- 建议在合并重要文件前使用`--backup`选项创建备份 