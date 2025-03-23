# Ubuntu Helpers (No Hardcode)

A collection of shell scripts for building, packaging, and installing Ubuntu-based distributions, with a focus on LinuxMCE (Linux Media Center Edition).

## Overview

This repository contains scripts for:

- Building Debian/Ubuntu packages from source
- Creating custom installation media (CD/DVD)
- Setting up build environments
- Automating installations in virtual machines
- Managing repositories and package versioning

## Directory Structure

- `build-scripts/`: Main build process scripts
- `common/`: Shared utility and environment scripts
- `conf-files/`: Configuration files for different Ubuntu/Debian releases and architectures
- `prepare-scripts/`: Scripts to prepare the build environment
- `build-dvd/`: Scripts for building installation media
- `vmware-install/`: Scripts for automated installation in VMware
- `docs/`: Documentation

### Configuration Files

The `conf-files` directory contains configuration files organized by distribution, version, and architecture (e.g., ubuntu-jammy-amd64, raspbian-jessie-armhf). These files define build parameters, package lists, and distribution-specific settings used by the build system to create consistent builds across different Ubuntu/Debian versions. For detailed information, see [Configuration Files Documentation](docs/conf_files.md).

## Key Scripts

- `build.sh`: Main build orchestration script
- `install.sh`: Sets up the build environment
- `prepare.sh`: Prepares the build environment with required packages
- `update-repo.sh`: Updates package repositories with new builds

## Documentation

For a complete catalog of all scripts and their descriptions, see [Script Catalog](docs/script_catalog.md).

## Requirements

- Ubuntu/Debian-based system
- Package building tools (dpkg-dev, debhelper, etc.)
- Git and Subversion for source code management