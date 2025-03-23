# Shell Script Catalog: Ubuntu_Helpers_NoHardcode

## Root Directory Scripts
- `build.sh`: Main build orchestration script - clones repos, imports binaries, builds packages
- `build-is.sh`: Build information reporting script
- `install.sh`: Sets up build environment with symlinks and SSH keys
- `prepare.sh`: Prepares build environment with required packages
- `loop-build.sh`: Runs build.sh in a continuous loop
- `loop-compile.sh`: Continuously compiles specific components
- `release-pkg.sh`: Prepares and releases packages to repository
- `test-pkg.sh`: Tests built packages
- `test-src.sh`: Tests source code before compilation
- `update-repo.sh`: Updates package repositories with new builds

## Common Scripts
- `common/env.sh`: Sets up environment variables for the build system
- `common/logging.sh`: Provides logging functions and error handling
- `common/utils.sh`: Contains utility functions like removing duplicate packages

## Build Scripts
- `build-scripts/clone-git.sh`: Clones repos and handles git operations
- `build-scripts/build-maindebs.sh`: Compiles main packages by distro and architecture
- `build-scripts/build-maindebs-sim.sh`: Simulates package builds without compilation
- `build-scripts/build-makerelease.sh`: Generates release packages and versions
- `build-scripts/build-replacements.sh`: Builds replacement packages for system components
- `build-scripts/cd1-build.sh`: Builds first CD/DVD content
- `build-scripts/cd2-build.sh`: Builds second CD/DVD content
- `build-scripts/checkout-svn.sh`: Manages Subversion repository checkouts
- `build-scripts/create-repo.sh`: Creates Debian/Ubuntu package repositories
- `build-scripts/finalizedvd.sh`: Finalizes DVD image creation
- `build-scripts/get-closed-source-debs.sh`: Fetches closed-source dependencies
- `build-scripts/import-databases.sh`: Imports database structures for builds
- `build-scripts/import-win32bins.sh`: Imports Windows binaries
- `build-scripts/makedvd.sh`: Creates DVD images from Ubuntu base with custom content
- `build-scripts/name-packages.sh`: Manages package naming conventions
- `build-scripts/version-helper.sh`: Handles version numbering

## Prepare Scripts
- `prepare-scripts/add-ubuntu-release.sh`: Adds support for new Ubuntu releases
- `prepare-scripts/cd1-prepare.sh`: Prepares environment for CD1 build
- `prepare-scripts/cd2-prepare.sh`: Prepares environment for CD2 build
- `prepare-scripts/create-diskless-debootstrap.sh`: Creates diskless boot environments
- `prepare-scripts/import-external-files.sh`: Imports external files needed for builds
- `prepare-scripts/install-build-pkgs.sh`: Installs build dependencies
- `prepare-scripts/preseed-build-pkgs.sh`: Preseeds build package configurations

## DVD and VM Scripts
- `build-dvd/build-cd.sh`: Builds CD/DVD images
- `build-dvd/lite-installer.sh`: Creates lightweight installer versions
- `vmware-install/install_in_vmware.sh`: Automates LinuxMCE installation in VMware
- `vmware-install/mce-installer-unattended/mce-installer.sh`: Handles unattended installations