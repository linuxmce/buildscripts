#!/bin/bash

set -e
set -x

# Bulletproof Debian Package Builder Script
# Creates a .deb package using equivs-build with comprehensive error checking
# 
# Usage: ./build_debian_package.sh <name> <version> <dependencies> <architecture> <description>
# Example: ./build_debian_package.sh "my-package" "1.0.0" "libc6, bash" "amd64" "My custom package"

# Function to display usage information
usage() {
    cat << EOF
Usage: $0 <name> <version> <dependencies> <architecture> <description>

Parameters:
  name         - Package name (required, must be valid Debian package name)
  version      - Package version (required, must be valid Debian version)
  dependencies - Package dependencies (optional, comma-separated list, use "" for none)
  architecture - Target architecture (optional, defaults to 'all')
  description  - Package description (required)

Example:
  $0 "my-package" "1.0.0" "libc6, bash" "amd64" "My custom package"
  $0 "simple-pkg" "2.1" "" "all" "A simple package with no dependencies"
EOF
}

# Validation function for package names
validate_package_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || [[ ${#name} -lt 2 ]]; then
        return 1
    fi
    return 0
}

# Validation function for version strings
validate_version() {
    local version="$1"
    # Basic Debian version validation (simplified)
    if [[ ! "$version" =~ ^[0-9][a-zA-Z0-9+.~:-]*$ ]]; then
        return 1
    fi
    return 0
}

# Validation function for architecture
validate_architecture() {
    local arch="$1"
    local valid_archs=("all" "amd64" "i386" "arm64" "armhf" "armel" "mips" "mipsel" "mips64el" "ppc64el" "s390x")
    for valid_arch in "${valid_archs[@]}"; do
        if [[ "$arch" == "$valid_arch" ]]; then
            return 0
        fi
    done
    return 1
}

# Main script execution
build_dummy_deb() {
    # Check for minimum required parameters
    if [[ $# -lt 3 ]]; then
        echo "ERROR: Insufficient parameters provided" >&2
        usage
        exit 1
    fi

    if [[ $# -gt 5 ]]; then
        echo "ERROR: Too many parameters provided" >&2
        usage
        exit 1
    fi

    # Parameter assignment and validation
    local pkg_name="$1"
    local pkg_ver="$2"
    local pkg_deps="$3"
    local pkg_arch="${4:-all}"  # Default to 'all' if not provided
    local pkg_desc="$5"

    # Validate required parameters
    if [[ -z "$pkg_name" ]]; then
        echo "ERROR: Package name cannot be empty" >&2
        exit 1
    fi

    if [[ -z "$pkg_ver" ]]; then
        echo "ERROR: Package version cannot be empty" >&2
        exit 1
    fi

    if [[ -z "$pkg_desc" ]]; then
        echo "ERROR: Package description cannot be empty" >&2
        exit 1
    fi

    # Validate package name format
    if ! validate_package_name "$pkg_name"; then
        echo "ERROR: Invalid package name '$pkg_name'. Must start with alphanumeric, contain only lowercase letters, numbers, hyphens, periods, and plus signs" >&2
        exit 1
    fi

    # Validate version format
    if ! validate_version "$pkg_ver"; then
        echo "ERROR: Invalid version format '$pkg_ver'. Must start with a digit and contain only valid Debian version characters" >&2
        exit 1
    fi

    # Validate architecture
    if ! validate_architecture "$pkg_arch"; then
        echo "ERROR: Invalid architecture '$pkg_arch'. Must be one of: all, amd64, i386, arm64, armhf, armel, mips, mipsel, mips64el, ppc64el, s390x" >&2
        exit 1
    fi

    # Check for required tools
    if ! command -v equivs-build &> /dev/null; then
        echo "ERROR: equivs-build not found. Please install equivs package: sudo apt-get install equivs" >&2
        exit 1
    fi

    # Sanitize inputs to prevent injection attacks
    pkg_name=$(printf '%s' "$pkg_name" | tr -cd '[:alnum:]+-.')
    pkg_ver=$(printf '%s' "$pkg_ver" | tr -cd '[:alnum:]+.~:-')
    pkg_arch=$(printf '%s' "$pkg_arch" | tr -cd '[:alnum:]')

    # Set working directory and create temporary workspace
    local work_dir="${PWD}"
    local temp_dir
    temp_dir=$(mktemp -d) || {
        echo "ERROR: Failed to create temporary directory" >&2
        exit 1
    }

    # Cleanup function
    cleanup() {
        if [[ -n "$temp_dir" && -d "$temp_dir" ]]; then
            rm -rf "$temp_dir"
        fi
    }
    trap cleanup EXIT

    echo "Building Debian package: $pkg_name version $pkg_ver for $pkg_arch"

    # Create the equivs control file
    local control_file="${temp_dir}/${pkg_name}.equivs"
    
    # Write control file with proper error handling
    {
        cat << EOF
Maintainer: LinuxMCE Developers <developers@linuxmce.org>
Architecture: ${pkg_arch}
Section: misc
Priority: optional
Package: ${pkg_name}
Version: ${pkg_ver}
Description: ${pkg_desc}
EOF
        # Only add Depends line if dependencies are provided
        if [[ -n "$pkg_deps" ]]; then
            echo "Depends: ${pkg_deps}"
        fi
    } > "$control_file" || {
        echo "ERROR: Failed to create control file" >&2
        exit 1
    }

    echo "Created control file: $control_file"

    # Change to temp directory for building
    cd "$temp_dir" || {
        echo "ERROR: Failed to change to temporary directory" >&2
        exit 1
    }

    # Build the package
    echo "Running equivs-build..."
    if ! equivs-build "${pkg_name}.equivs"; then
        echo "ERROR: equivs-build failed" >&2
        cd "$work_dir"
        exit 1
    fi

    # Find the generated .deb file
    local deb_file
    deb_file=$(find . -maxdepth 1 -name "${pkg_name}_*.deb" | head -1)
    
    if [[ -z "$deb_file" ]]; then
        echo "ERROR: Generated .deb file not found" >&2
        cd "$work_dir"
        exit 1
    fi

    # Move the .deb file to the original working directory
    if ! mv "$deb_file" "$work_dir/"; then
        echo "ERROR: Failed to move .deb file to working directory" >&2
        cd "$work_dir"
        exit 1
    fi

    cd "$work_dir"
    
    local final_deb_file="${work_dir}/$(basename "$deb_file")"
    
    # Verify the package was created successfully
    if [[ ! -f "$final_deb_file" ]]; then
        echo "ERROR: Package file not found after build" >&2
        exit 1
    fi

    echo "SUCCESS: Package created successfully: $(basename "$deb_file")"
    echo "File location: $final_deb_file"
    echo "File size: $(stat -c%s "$final_deb_file") bytes"
    
    # Optional: Display installation command
    echo ""
    echo "To install the package, run:"
    echo "sudo dpkg -i \"$final_deb_file\""
    echo ""
    echo "If there are dependency issues, run:"
    echo "sudo apt-get install -f"

    return 0
}

# Execute main function with all passed arguments
build_dummy_deb "$@"
