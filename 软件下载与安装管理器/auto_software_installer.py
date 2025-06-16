#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import platform
import logging
import json
import time
import re
import subprocess
import concurrent.futures
from pathlib import Path
import urllib.parse
import tempfile

import requests
from bs4 import BeautifulSoup
from tqdm import tqdm

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("software_installer.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Default headers to avoid being blocked
DEFAULT_HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Cache-Control': 'max-age=0',
}

# Detect operating system
def get_os_type():
    system = platform.system().lower()
    if 'windows' in system:
        return 'windows'
    elif 'darwin' in system:
        return 'macos'
    elif 'linux' in system:
        return 'linux'
    else:
        return 'unknown'

OS_TYPE = get_os_type()
logger.info(f"Detected operating system: {OS_TYPE}")

class SoftwareDownloader:
    def __init__(self, download_dir=None, max_workers=4):
        """
        Initialize the downloader with download directory and thread count
        
        Args:
            download_dir: Directory to save downloaded files (default: ./downloads)
            max_workers: Maximum number of concurrent downloads
        """
        self.download_dir = download_dir or os.path.join(os.getcwd(), 'downloads')
        self.max_workers = max_workers
        os.makedirs(self.download_dir, exist_ok=True)
        
    def download_file(self, url, filename=None, cookies=None):
        """
        Download a file from URL with progress bar
        
        Args:
            url: URL to download
            filename: Optional filename (default: extracted from URL)
            cookies: Optional cookies for the request
            
        Returns:
            Path to the downloaded file
        """
        try:
            if not filename:
                filename = os.path.basename(urllib.parse.urlparse(url).path)
                if not filename or '.' not in filename:
                    filename = f"download_{int(time.time())}"
            
            filepath = os.path.join(self.download_dir, filename)
            
            # If file already exists with same name, add timestamp
            if os.path.exists(filepath):
                name, ext = os.path.splitext(filename)
                filename = f"{name}_{int(time.time())}{ext}"
                filepath = os.path.join(self.download_dir, filename)
            
            logger.info(f"Downloading {url} to {filepath}")
            
            # Start the request with stream=True
            response = requests.get(url, headers=DEFAULT_HEADERS, 
                                   cookies=cookies, stream=True)
            response.raise_for_status()
            
            # Get file size if available
            total_size = int(response.headers.get('content-length', 0))
            
            # Download with progress bar
            with open(filepath, 'wb') as f, tqdm(
                desc=filename,
                total=total_size,
                unit='B',
                unit_scale=True,
                unit_divisor=1024,
            ) as bar:
                for chunk in response.iter_content(chunk_size=1024 * 8):
                    if chunk:
                        size = f.write(chunk)
                        bar.update(size)
            
            return filepath
        
        except requests.RequestException as e:
            logger.error(f"Download failed for {url}: {e}")
            return None
    
    def download_multiple(self, url_list):
        """
        Download multiple files concurrently
        
        Args:
            url_list: List of (url, filename) tuples or just URLs
            
        Returns:
            List of downloaded file paths
        """
        downloaded_files = []
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            # Create future tasks
            future_to_url = {}
            for item in url_list:
                if isinstance(item, tuple) and len(item) >= 2:
                    url, filename = item[0], item[1]
                    cookies = item[2] if len(item) > 2 else None
                    future = executor.submit(self.download_file, url, filename, cookies)
                else:
                    future = executor.submit(self.download_file, item)
                future_to_url[future] = item
            
            # Process results as they complete
            for future in concurrent.futures.as_completed(future_to_url):
                url_item = future_to_url[future]
                try:
                    filepath = future.result()
                    if filepath:
                        downloaded_files.append(filepath)
                except Exception as e:
                    url = url_item[0] if isinstance(url_item, tuple) else url_item
                    logger.error(f"Error downloading {url}: {e}")
        
        return downloaded_files

class SoftwareInstaller:
    def __init__(self, install_dir=None, temp_dir=None):
        """
        Initialize the installer with install directory
        
        Args:
            install_dir: Custom installation directory (optional)
            temp_dir: Temporary directory for installation files
        """
        self.install_dir = install_dir
        self.temp_dir = temp_dir or tempfile.gettempdir()
    
    def install_windows_exe(self, filepath):
        """
        Install Windows .exe file silently
        
        Args:
            filepath: Path to the .exe file
            
        Returns:
            True if installation was successful, False otherwise
        """
        try:
            install_cmd = [filepath]
            
            # Common silent install flags
            if "chrome" in filepath.lower():
                install_cmd.extend(['--silent', '--install-directory="{}"'.format(
                    self.install_dir) if self.install_dir else ''])
            elif "python" in filepath.lower():
                install_cmd.extend(['/quiet', 'InstallAllUsers=1', 'PrependPath=1', 
                                   'Include_test=0', 'Include_launcher=1'])
                if self.install_dir:
                    install_cmd.append(f'TargetDir="{self.install_dir}"')
            elif "vscode" in filepath.lower() or "code" in filepath.lower():
                install_cmd.extend(['/VERYSILENT', '/NORESTART', '/MERGETASKS=!runcode'])
                if self.install_dir:
                    install_cmd.append(f'/DIR="{self.install_dir}"')
            elif "notepad++" in filepath.lower():
                install_cmd.extend(['/S'])
                if self.install_dir:
                    install_cmd.append(f'/D={self.install_dir}')
            else:
                # Generic silent install commands to try
                install_cmd.extend(['/S', '/SILENT', '/VERYSILENT', '/quiet'])
            
            # Clean empty arguments
            install_cmd = [arg for arg in install_cmd if arg]
            
            logger.info(f"Installing {filepath} with command: {' '.join(install_cmd)}")
            
            # Execute the installation
            result = subprocess.run(
                install_cmd, 
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            logger.info(f"Installation completed for {filepath}")
            return True
            
        except subprocess.CalledProcessError as e:
            logger.error(f"Installation failed for {filepath}: {e}")
            logger.error(f"Error output: {e.stderr}")
            return False
        except Exception as e:
            logger.error(f"Unknown error during installation of {filepath}: {e}")
            return False
    
    def install_macos_dmg(self, filepath):
        """
        Install macOS .dmg file
        
        Args:
            filepath: Path to the .dmg file
            
        Returns:
            True if installation was successful, False otherwise
        """
        try:
            # Mount the DMG
            mount_dir = os.path.join(self.temp_dir, f"dmg_mount_{int(time.time())}")
            os.makedirs(mount_dir, exist_ok=True)
            
            mount_cmd = ["hdiutil", "attach", filepath, "-mountpoint", mount_dir, "-nobrowse"]
            subprocess.run(mount_cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            
            # Find application or package in the mounted volume
            app_path = None
            pkg_path = None
            
            for root, dirs, files in os.walk(mount_dir):
                for item in dirs:
                    if item.endswith('.app'):
                        app_path = os.path.join(root, item)
                        break
                for item in files:
                    if item.endswith('.pkg'):
                        pkg_path = os.path.join(root, item)
                        break
                if app_path or pkg_path:
                    break
            
            # Install the application or package
            result = False
            if app_path:
                # Copy .app to /Applications
                copy_cmd = ["cp", "-R", app_path, "/Applications/"]
                subprocess.run(copy_cmd, check=True)
                logger.info(f"Installed {app_path} to /Applications/")
                result = True
            elif pkg_path:
                # Install .pkg file
                install_cmd = ["installer", "-pkg", pkg_path, "-target", "/"]
                subprocess.run(install_cmd, check=True)
                logger.info(f"Installed package {pkg_path}")
                result = True
            else:
                logger.error(f"No application or package found in {filepath}")
                result = False
                
            # Unmount the DMG
            unmount_cmd = ["hdiutil", "detach", mount_dir, "-force"]
            subprocess.run(unmount_cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            
            return result
            
        except subprocess.CalledProcessError as e:
            logger.error(f"Installation failed for {filepath}: {e}")
            # Try to unmount if mount was successful
            try:
                subprocess.run(["hdiutil", "detach", mount_dir, "-force"], 
                              check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            except:
                pass
            return False
        except Exception as e:
            logger.error(f"Unknown error during installation of {filepath}: {e}")
            return False
            
    def install_macos_pkg(self, filepath):
        """
        Install macOS .pkg file
        
        Args:
            filepath: Path to the .pkg file
            
        Returns:
            True if installation was successful, False otherwise
        """
        try:
            install_cmd = ["installer", "-pkg", filepath, "-target", "/"]
            subprocess.run(install_cmd, check=True)
            logger.info(f"Installed package {filepath}")
            return True
        except subprocess.CalledProcessError as e:
            logger.error(f"Installation failed for {filepath}: {e}")
            return False
        except Exception as e:
            logger.error(f"Unknown error during installation of {filepath}: {e}")
            return False
    
    def install(self, filepath):
        """
        Install software based on file extension and OS
        
        Args:
            filepath: Path to the installation file
            
        Returns:
            True if installation was successful, False otherwise
        """
        _, ext = os.path.splitext(filepath.lower())
        
        if OS_TYPE == 'windows':
            if ext == '.exe' or ext == '.msi':
                return self.install_windows_exe(filepath)
            else:
                logger.error(f"Unsupported file type for Windows: {ext}")
                return False
                
        elif OS_TYPE == 'macos':
            if ext == '.dmg':
                return self.install_macos_dmg(filepath)
            elif ext == '.pkg':
                return self.install_macos_pkg(filepath)
            else:
                logger.error(f"Unsupported file type for macOS: {ext}")
                return False
                
        else:
            logger.error(f"Unsupported OS: {OS_TYPE}")
            return False

class SoftwareLinkFetcher:
    """Class to fetch download links from official software websites"""
    
    @staticmethod
    def get_chrome_download_link():
        """Get Chrome download link based on OS"""
        try:
            if OS_TYPE == 'windows':
                # Chrome direct download link for Windows
                return "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
            elif OS_TYPE == 'macos':
                # Chrome direct download link for macOS
                return "https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg"
            else:
                logger.error(f"Chrome download not supported for OS: {OS_TYPE}")
                return None
        except Exception as e:
            logger.error(f"Error getting Chrome download link: {e}")
            return None
            
    @staticmethod
    def get_python_download_link():
        """Get latest Python download link based on OS"""
        try:
            response = requests.get("https://www.python.org/downloads/", headers=DEFAULT_HEADERS)
            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Find the latest version download button
            download_link = soup.select_one('a.button.button-primary')
            if not download_link:
                logger.error("Could not find Python download button")
                return None
                
            version_page_url = download_link['href']
            
            # Get download page for specific version
            response = requests.get(version_page_url, headers=DEFAULT_HEADERS)
            response.raise_for_status()
            version_soup = BeautifulSoup(response.content, 'html.parser')
            
            # Find appropriate download based on OS
            if OS_TYPE == 'windows':
                # Look for Windows installer (64-bit)
                download_list = version_soup.select('a.button[href*="amd64.exe"]')
                if download_list:
                    for download in download_list:
                        # Prefer the executable installer
                        if "executable" in download.text.lower():
                            return download['href']
                    # If no executable installer found, use the first one
                    return download_list[0]['href']
            
            elif OS_TYPE == 'macos':
                # Look for macOS installer
                download_list = version_soup.select('a.button[href*="macos"]')
                if download_list:
                    return download_list[0]['href']
            
            logger.error(f"Could not find Python download for OS: {OS_TYPE}")
            return None
            
        except requests.RequestException as e:
            logger.error(f"Error fetching Python download link: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error getting Python download link: {e}")
            return None
            
    @staticmethod
    def get_vscode_download_link():
        """Get VS Code download link based on OS"""
        try:
            base_url = "https://code.visualstudio.com/download"
            response = requests.get(base_url, headers=DEFAULT_HEADERS)
            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Different OS selectors
            if OS_TYPE == 'windows':
                # Find Windows download link (.exe)
                download_link = soup.select_one('a[href*=".exe"]')
            elif OS_TYPE == 'macos':
                # Find macOS download link (.dmg)
                download_link = soup.select_one('a[href*="darwin"]')
            else:
                logger.error(f"VSCode download not supported for OS: {OS_TYPE}")
                return None
                
            if download_link and 'href' in download_link.attrs:
                return download_link['href']
                
            logger.error(f"Could not find VSCode download link for {OS_TYPE}")
            return None
            
        except requests.RequestException as e:
            logger.error(f"Error fetching VSCode download link: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error getting VSCode download link: {e}")
            return None
    
    @staticmethod
    def get_notepadpp_download_link():
        """Get Notepad++ download link (Windows only)"""
        if OS_TYPE != 'windows':
            logger.error("Notepad++ is only available for Windows")
            return None
            
        try:
            base_url = "https://notepad-plus-plus.org/downloads/"
            response = requests.get(base_url, headers=DEFAULT_HEADERS)
            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Find the latest version link
            version_link = soup.select_one('div.version h2 a')
            if not version_link or 'href' not in version_link.attrs:
                logger.error("Could not find latest Notepad++ version")
                return None
                
            # Navigate to the version page
            version_url = version_link['href']
            response = requests.get(version_url, headers=DEFAULT_HEADERS)
            response.raise_for_status()
            version_soup = BeautifulSoup(response.content, 'html.parser')
            
            # Find 64-bit installer link
            download_link = version_soup.select_one('a[href*="Installer.x64.exe"]')
            if download_link and 'href' in download_link.attrs:
                return download_link['href']
                
            logger.error("Could not find Notepad++ installer link")
            return None
            
        except requests.RequestException as e:
            logger.error(f"Error fetching Notepad++ download link: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error getting Notepad++ download link: {e}")
            return None

class SoftwareManager:
    """Main class to manage software downloads and installations"""
    
    def __init__(self, config=None):
        """
        Initialize the software manager
        
        Args:
            config: Configuration dict or path to JSON config file
        """
        self.config = self._load_config(config)
        self.download_dir = self.config.get('download_dir') or os.path.join(os.getcwd(), 'downloads')
        self.install_dir = self.config.get('install_dir')
        self.max_workers = self.config.get('max_workers', 4)
        
        self.downloader = SoftwareDownloader(self.download_dir, self.max_workers)
        self.installer = SoftwareInstaller(self.install_dir)
        self.link_fetcher = SoftwareLinkFetcher()
        
        # Create download directory if it doesn't exist
        os.makedirs(self.download_dir, exist_ok=True)
    
    def _load_config(self, config):
        """Load configuration from file or dict"""
        default_config = {
            'download_dir': os.path.join(os.getcwd(), 'downloads'),
            'install_dir': None,
            'max_workers': 4,
            'software_list': [
                {'name': 'chrome', 'enabled': True},
                {'name': 'python', 'enabled': True},
                {'name': 'vscode', 'enabled': True},
                {'name': 'notepadpp', 'enabled': True if OS_TYPE == 'windows' else False}
            ]
        }
        
        if not config:
            return default_config
            
        if isinstance(config, str) and os.path.exists(config):
            try:
                with open(config, 'r') as f:
                    user_config = json.load(f)
                    # Merge with default config
                    return {**default_config, **user_config}
            except Exception as e:
                logger.error(f"Error loading config file: {e}")
                return default_config
        elif isinstance(config, dict):
            return {**default_config, **config}
        else:
            return default_config
    
    def save_config(self, filepath='software_config.json'):
        """Save current configuration to JSON file"""
        try:
            with open(filepath, 'w') as f:
                json.dump(self.config, f, indent=4)
            logger.info(f"Configuration saved to {filepath}")
            return True
        except Exception as e:
            logger.error(f"Error saving configuration: {e}")
            return False
    
    def get_download_links(self):
        """
        Get download links for all enabled software
        
        Returns:
            List of (software_name, download_url) tuples
        """
        download_links = []
        
        for software in self.config['software_list']:
            if not software.get('enabled', True):
                continue
                
            name = software['name'].lower()
            url = None
            
            # Get download link based on software name
            if name == 'chrome':
                url = self.link_fetcher.get_chrome_download_link()
            elif name == 'python':
                url = self.link_fetcher.get_python_download_link()
            elif name == 'vscode':
                url = self.link_fetcher.get_vscode_download_link()
            elif name == 'notepadpp':
                url = self.link_fetcher.get_notepadpp_download_link()
            else:
                # Custom URL if provided in config
                url = software.get('url')
            
            if url:
                download_links.append((name, url))
            else:
                logger.error(f"Could not get download link for {name}")
        
        return download_links
    
    def download_software(self):
        """
        Download all enabled software
        
        Returns:
            List of (software_name, local_file_path) tuples
        """
        download_links = self.get_download_links()
        
        if not download_links:
            logger.error("No software links found for downloading")
            return []
        
        logger.info(f"Starting download of {len(download_links)} software packages")
        
        # Convert to format expected by downloader
        download_items = []
        for name, url in download_links:
            # Get filename from URL or create one based on software name
            filename = os.path.basename(urllib.parse.urlparse(url).path)
            if not filename or '.' not in filename:
                # Try to guess extension based on OS and software
                if OS_TYPE == 'windows':
                    ext = '.exe'
                elif OS_TYPE == 'macos':
                    ext = '.dmg'
                else:
                    ext = '.bin'
                filename = f"{name}_{int(time.time())}{ext}"
            
            download_items.append((url, filename))
        
        # Download all files
        downloaded_files = self.downloader.download_multiple(download_items)
        
        # Map software names to downloaded files
        result = []
        for i, filepath in enumerate(downloaded_files):
            if i < len(download_links):
                name = download_links[i][0]
                result.append((name, filepath))
        
        return result
    
    def install_software(self, downloaded_files):
        """
        Install downloaded software
        
        Args:
            downloaded_files: List of (software_name, local_file_path) tuples
            
        Returns:
            List of (software_name, success) tuples
        """
        results = []
        
        for name, filepath in downloaded_files:
            logger.info(f"Installing {name} from {filepath}")
            success = self.installer.install(filepath)
            results.append((name, success))
            
            if success:
                logger.info(f"Successfully installed {name}")
            else:
                logger.error(f"Failed to install {name}")
        
        return results
    
    def run(self):
        """
        Run the complete process: download and install all software
        
        Returns:
            Dict with overall results
        """
        start_time = time.time()
        
        logger.info(f"Starting software installation process")
        logger.info(f"Using download directory: {self.download_dir}")
        logger.info(f"Custom install directory: {self.install_dir or 'Not set (using defaults)'}")
        
        # Download all software
        downloaded_files = self.download_software()
        
        if not downloaded_files:
            logger.error("No files were downloaded")
            return {"success": False, "message": "No files were downloaded"}
        
        # Install all downloaded software
        install_results = self.install_software(downloaded_files)
        
        # Summarize results
        success_count = sum(1 for _, success in install_results if success)
        total_count = len(install_results)
        
        end_time = time.time()
        duration = round(end_time - start_time, 2)
        
        result = {
            "success": success_count > 0,
            "total": total_count,
            "successful": success_count,
            "failed": total_count - success_count,
            "duration_seconds": duration,
            "details": {name: "Success" if success else "Failed" for name, success in install_results}
        }
        
        logger.info(f"Installation complete. {success_count}/{total_count} successful in {duration} seconds")
        
        return result


def main():
    """Main function to run the script"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Automated Software Downloader and Installer')
    parser.add_argument('-c', '--config', help='Path to configuration JSON file')
    parser.add_argument('-d', '--download-dir', help='Directory to save downloaded files')
    parser.add_argument('-i', '--install-dir', help='Custom installation directory')
    parser.add_argument('-w', '--workers', type=int, default=4, help='Number of download worker threads')
    parser.add_argument('--download-only', action='store_true', help='Only download without installing')
    parser.add_argument('--list', action='store_true', help='List available software and exit')
    parser.add_argument('--create-config', help='Create a default configuration file')
    
    args = parser.parse_args()
    
    # Create a default config if requested
    if args.create_config:
        config = {
            'download_dir': args.download_dir or os.path.join(os.getcwd(), 'downloads'),
            'install_dir': args.install_dir,
            'max_workers': args.workers,
            'software_list': [
                {'name': 'chrome', 'enabled': True},
                {'name': 'python', 'enabled': True},
                {'name': 'vscode', 'enabled': True},
                {'name': 'notepadpp', 'enabled': True if OS_TYPE == 'windows' else False}
            ]
        }
        
        with open(args.create_config, 'w') as f:
            json.dump(config, f, indent=4)
        
        print(f"Default configuration file created at {args.create_config}")
        return
    
    # Prepare configuration
    config = None
    if args.config:
        config = args.config
    else:
        config = {
            'download_dir': args.download_dir,
            'install_dir': args.install_dir,
            'max_workers': args.workers
        }
    
    # Create software manager
    manager = SoftwareManager(config)
    
    # Handle --list option
    if args.list:
        print("Available software for installation:")
        for software in manager.config['software_list']:
            status = "Enabled" if software.get('enabled', True) else "Disabled"
            print(f"- {software['name']} ({status})")
        return
    
    # Handle download-only option
    if args.download_only:
        downloaded_files = manager.download_software()
        print("\nDownloaded files:")
        for name, filepath in downloaded_files:
            print(f"- {name}: {filepath}")
        return
    
    # Run full process
    result = manager.run()
    
    # Print summary
    print("\nInstallation Summary:")
    print(f"Total: {result['total']}")
    print(f"Successful: {result['successful']}")
    print(f"Failed: {result['failed']}")
    print(f"Duration: {result['duration_seconds']:.2f} seconds")
    print("\nDetails:")
    for software, status in result['details'].items():
        print(f"- {software}: {status}")

if __name__ == "__main__":
    main() 