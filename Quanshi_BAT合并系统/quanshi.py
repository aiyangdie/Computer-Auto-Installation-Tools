#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import argparse
import shutil
from datetime import datetime

def list_bat_files(directory='.'):
    """List all .bat files in the specified directory"""
    bat_files = []
    for file in os.listdir(directory):
        if file.lower().endswith('.bat'):
            bat_files.append(os.path.join(directory, file))
    return bat_files

def merge_bat_files(output_file, bat_files, add_headers=True):
    """Merge multiple .bat files into a single file"""
    with open(output_file, 'w', encoding='utf-8') as outfile:
        # Write header
        outfile.write('@echo off\n')
        outfile.write(':: Merged BAT file created by quanshi.py\n')
        outfile.write(f':: Created on {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
        outfile.write(':: Contains the following files:\n')
        
        for bat_file in bat_files:
            outfile.write(f'::   - {os.path.basename(bat_file)}\n')
        
        outfile.write('\n')
        
        # Merge the files
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
                    # Skip the @echo off line if it exists at the beginning
                    first_line = infile.readline()
                    if not first_line.lower().strip() == '@echo off':
                        outfile.write(first_line)
                    
                    # Copy the rest of the file
                    for line in infile:
                        outfile.write(line)
            except UnicodeDecodeError:
                # Try with a different encoding if utf-8 fails
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
    
    print(f"Successfully merged {len(bat_files)} bat files into {output_file}")

def backup_file(file_path):
    """Create a backup of the specified file"""
    if os.path.exists(file_path):
        backup_path = f"{file_path}.bak.{datetime.now().strftime('%Y%m%d%H%M%S')}"
        shutil.copy2(file_path, backup_path)
        print(f"Created backup: {backup_path}")

def main():
    parser = argparse.ArgumentParser(description='Merge multiple .bat files into a single file')
    parser.add_argument('-o', '--output', default='merged.bat', help='Output file name')
    parser.add_argument('-d', '--directory', default='.', help='Directory containing .bat files')
    parser.add_argument('-f', '--files', nargs='+', help='Specific .bat files to merge')
    parser.add_argument('--no-headers', action='store_true', help='Do not add section headers for each file')
    parser.add_argument('--backup', action='store_true', help='Create a backup if output file exists')
    
    args = parser.parse_args()
    
    # Check if output file exists and create backup if requested
    if os.path.exists(args.output) and args.backup:
        backup_file(args.output)
    
    # Get the list of bat files to merge
    if args.files:
        bat_files = [f for f in args.files if os.path.exists(f) and f.lower().endswith('.bat')]
    else:
        bat_files = list_bat_files(args.directory)
    
    if not bat_files:
        print("No .bat files found to merge.")
        return
    
    print(f"Found {len(bat_files)} .bat files:")
    for i, file in enumerate(bat_files, 1):
        print(f"{i}. {file}")
    
    # Merge the files
    merge_bat_files(args.output, bat_files, not args.no_headers)

if __name__ == '__main__':
    main() 