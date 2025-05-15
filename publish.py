#!/usr/bin/env python3
"""
Script to bump minor version and publish a Poetry package
"""

import re
import subprocess
import sys
from pathlib import Path


def get_current_version():
    """Read current version from pyproject.toml"""
    pyproject_path = Path("pyproject.toml")
    if not pyproject_path.exists():
        print("Error: pyproject.toml not found in current directory")
        sys.exit(1)
    
    content = pyproject_path.read_text()
    version_match = re.search(r'version\s*=\s*"(\d+\.\d+\.\d+)"', content)
    
    if not version_match:
        print("Error: Could not find version in pyproject.toml")
        sys.exit(1)
        
    return version_match.group(1)


def increment_minor_version(version):
    """Increment the minor version number"""
    major, minor, patch = map(int, version.split('.'))
    return f"{major}.{minor + 1}.0"


def update_version(new_version):
    """Update version in pyproject.toml"""
    pyproject_path = Path("pyproject.toml")
    content = pyproject_path.read_text()
    
    updated_content = re.sub(
        r'version\s*=\s*"(\d+\.\d+\.\d+)"',
        f'version = "{new_version}"',
        content
    )
    
    pyproject_path.write_text(updated_content)
    print(f"Updated version to {new_version}")


def build_and_publish():
    """Build and publish the package"""
    print("Building package...")
    result = subprocess.run(["poetry", "build"], check=False)
    if result.returncode != 0:
        print("Error: Package build failed")
        sys.exit(1)
        
    print("Publishing package...")
    result = subprocess.run(["poetry", "publish"], check=False)
    if result.returncode != 0:
        print("Error: Package publishing failed")
        sys.exit(1)
        
    print("Package published successfully!")


def main():
    """Main function"""
    # Get current version
    current_version = get_current_version()
    print(f"Current version: {current_version}")
    
    # Increment version
    new_version = increment_minor_version(current_version)
    print(f"New version will be: {new_version}")
    
    # Confirm with user
    choice = input("Continue with version update and publish? [y/N]: ")
    
    if choice.lower() != 'y':
        print("Operation cancelled")
        sys.exit(0)
    
    # Update version in pyproject.toml
    update_version(new_version)
    
    # Build and publish
    build_and_publish()


if __name__ == "__main__":
    main()