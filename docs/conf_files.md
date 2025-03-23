# Configuration Files (conf-files)

This document describes the configuration files used by the build system to support multiple Ubuntu/Debian distributions and architectures.

## Directory Structure

The `conf-files` directory is organized by distribution, version, and architecture:

```
conf-files/
├── ubuntu-jammy-amd64/
├── ubuntu-bionic-amd64/
├── ubuntu-bionic-i386/
├── ubuntu-trusty-amd64/
...
├── raspbian-buster-armhf/
├── raspbian-jessie-armhf/
...
```

Some directories are symlinks to their full-name counterparts:
- `bionic-amd64` → `ubuntu-bionic-amd64`
- `xenial-amd64` → `ubuntu-xenial-amd64`
- etc.

## Standard Configuration Files

Each distribution directory typically contains:

### 1. builder.conf

The main configuration file that defines:
- Build environment variables
- Directory paths
- Repository URLs
- Database credentials
- Email notifications
- Package repositories

Example (simplified):
```bash
PACKAGE_REPOSITORY_HOST="repo.example.com"
PACKAGE_REPOSITORY_DIR="/var/www/repository"
BUILD_AREA="/usr/local/lmce-build/build"
...
```

### 2. ubuntu.conf / raspbian.conf

Distribution-specific configuration:
- Distribution codename
- Version numbers
- Compilation flags
- Architecture-specific parameters

### 3. build-packages

List of packages required for building the system, often one package per line.

## Additional Files

Older release directories may also contain:

### 1. CD/DVD Package Lists

- `cd1-packages`: Packages to include on first CD/DVD
- `cd1-packages-blacklist`: Packages to exclude from first CD/DVD
- `cd2-packages`: Packages for second CD/DVD
- `cdK-packages`: Additional packages for other media

### 2. Special Files

- `builder.key`/`builder.key.pub`: SSH keys for remote building
- `builder.custom.conf`: Optional custom overrides for builder.conf

## Usage

These configuration files are used by the build scripts to:
1. Set up the appropriate build environment for each distribution
2. Determine which packages to build and include
3. Configure repository locations and credentials
4. Set compilation parameters specific to each architecture

The configuration system enables reproducible builds across different Ubuntu/Debian versions while maintaining consistency in the build process.