#!/bin/bash

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

info() {
  echo -e "${GREEN}[INFO]${NC} $*"
}

warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*"
}

error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Detect package manager
detect_pkg_manager() {
    if command -v apt &> /dev/null; then
        echo "apt"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    else
        error "Unsupported package manager. Only apt, yum, and dnf are supported."
        exit 1
    fi
}

# Install NFS client
install_nfs_client() {
    local pkg_manager=$1
    info "Installing NFS client using $pkg_manager..."

    local pkg_name
    case $pkg_manager in
        apt)
            pkg_name="nfs-common"
            apt update && apt install -y "$pkg_name"
            ;;
        yum|dnf)
            pkg_name="nfs-utils"
            $pkg_manager install -y "$pkg_name"
            ;;
    esac || {
        error "Failed to install NFS client ($pkg_name)."
        exit 1
    }

    info "NFS client installed successfully."
}

# Mount NFS share
mount_nfs() {
    local server=$1
    local remote_path=$2
    local local_path=$3
    local options=${4:-"-o defaults"}

    # Check if local mount point exists
    if [ ! -d "$local_path" ]; then
        info "Creating mount point: $local_path"
        mkdir -p "$local_path" || {
            error "Failed to create mount point: $local_path"
            exit 1
        }
    fi

    # Check if already mounted
    if mountpoint -q "$local_path" 2>/dev/null; then
        warning "$local_path is already a mount point."
        return 0
    fi

    info "Mounting NFS share: $server:$remote_path -> $local_path"

    # Add timeo (timeout) option if not present to avoid long hangs
    case "$options" in
        *timeo=*) ;;
        *) options="timeo=50,$options" ;;
    esac

    if mount -t nfs -o "$options" "$server:$remote_path" "$local_path"; then
        info "NFS mounted successfully."
    else
        error "Failed to mount NFS share."
        exit 1
    fi
}

# Add to fstab for persistent mount
add_to_fstab() {
    local server=$1
    local remote_path=$2
    local local_path=$3
    local options=${4:-"defaults"}

    local fstab_entry="$server:$remote_path $local_path nfs $options 0 0"

    # Check if entry already exists
    if grep -q "${server}:${remote_path}[[:space:]]*${local_path}" /etc/fstab; then
        warning "Entry already exists in /etc/fstab"
        return 0
    fi

    info "Adding entry to /etc/fstab..."
    echo "$fstab_entry" >> /etc/fstab
    info "Entry added to /etc/fstab."
}

# Show usage
usage() {
    echo "Usage: $0 [OPTIONS] <server> <remote_path> <local_mount_point>"
    echo ""
    echo "Examples:"
    echo "  $0 192.168.1.100 /exports/data /mnt/nfs/data"
    echo "  $0 -m compat 192.168.1.100 /exports/data /mnt/nfs/data"
    echo "  $0 -c \"hard,noatime,rsize=1048576\" 192.168.1.100 /exports/data /mnt/nfs"
    echo "  $0 -p -m compat 192.168.1.100 /exports/data /mnt/nfs/data"
    echo ""
    echo "Options:"
    echo "  -p, --persistent      Add to /etc/fstab for persistent mount"
    echo "  -m, --mode <mode>     Mount mode: default (v4.2) | compat (v4.1)"
    echo "  -c, --custom <opts>   Custom mount options (e.g., 'hard,noatime')"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Mount Modes:"
    echo "  default  - NFSv4.2, 1MB rsize/wsize (modern systems, Linux 4.0+)"
    echo "  compat   - NFSv4.1, 1MB rsize/wsize (CentOS 7, legacy systems)"
}

# Get default mount options based on mode
get_mount_options() {
    local mode=$1
    case $mode in
        default)
            # Modern systems: NFSv4.2 with high performance options
            echo "hard,noatime,rsize=1048576,wsize=1048576,vers=4.2"
            ;;
        compat)
            # Legacy compatible: NFSv4.1 for CentOS 7 and older systems
            echo "hard,noatime,rsize=1048576,wsize=1048576,vers=4.1"
            ;;
        *)
            echo "defaults"
            ;;
    esac
}

main() {
    local persistent=false
    local mode="default"
    local mount_options=""
    local custom_options=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--persistent)
                persistent=true
                shift
                ;;
            -m|--mode)
                mode="$2"
                shift 2
                ;;
            -c|--custom)
                custom_options="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done

    # Check arguments
    if [ $# -lt 3 ]; then
        error "Missing required arguments."
        usage
        exit 1
    fi

    local server=$1
    local remote_path=$2
    local local_path=$3

    # Determine mount options
    if [ -n "$custom_options" ]; then
        # Remove '-o ' prefix if user included it
        mount_options="${custom_options#-o }"
        info "Using custom mount options: $mount_options"
    else
        mount_options=$(get_mount_options "$mode")
        info "Using $mode mode mount options: -o $mount_options"
    fi

    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root (use sudo)."
        exit 1
    fi

    info "Starting NFS mount script..."

    # Detect package manager
    local pkg_manager
    pkg_manager=$(detect_pkg_manager)
    info "Detected package manager: $pkg_manager"

    # Check and install NFS client
    case $pkg_manager in
        apt)
            if ! dpkg -l | grep -q nfs-common; then
                install_nfs_client "$pkg_manager"
            else
                info "NFS client already installed."
            fi
            ;;
        yum|dnf)
            if ! rpm -q nfs-utils &> /dev/null; then
                install_nfs_client "$pkg_manager"
            else
                info "NFS client already installed."
            fi
            ;;
    esac

    # Mount NFS
    mount_nfs "$server" "$remote_path" "$local_path" "$mount_options"

    # Add to fstab if requested
    if [ "$persistent" = true ]; then
        add_to_fstab "$server" "$remote_path" "$local_path" "${mount_options:-defaults}"
    fi

    info "NFS setup completed successfully!"
}

main "$@"
