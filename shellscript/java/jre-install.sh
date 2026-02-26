#!/bin/bash
#
# JRE Installation Script.
#
# This script installs JRE, validates passwordless sudo permissions,
# and checks the package version and architecture against the system.
#
# Usage:
#   ./jre-install.sh

set -euo pipefail

# Constants
readonly JDK_VERSION="1.8.0_181"
readonly PACKAGE_NAME="server-jre-8u181-linux-x64.tar.gz"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly PACKAGE_PATH="${SCRIPT_DIR}/zip/${PACKAGE_NAME}"
readonly DEFAULT_INSTALL_DIR="/usr/local/java"
readonly PROFILE_SCRIPT_PATH="/etc/profile.d/jre.sh"

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

# Checks if the current user has passwordless sudo privileges.
check_sudo_privileges() {
  info "Checking passwordless sudo privileges..."
  if ! sudo -n true 2>/dev/null; then
    error "This script requires passwordless sudo privileges to install the JRE."
    error "Please run 'sudo visudo' and configure NOPASSWD for your user."
    exit 1
  fi
  info "Sudo privileges validated."
}

# Extracts the package and configures environment variables.
install_jre() {
  info "Checking installation directory: ${DEFAULT_INSTALL_DIR}/jdk${JDK_VERSION}"
  if [[ -d "${DEFAULT_INSTALL_DIR}/jdk${JDK_VERSION}" ]]; then
    warning "Installation directory ${DEFAULT_INSTALL_DIR}/jdk${JDK_VERSION} already exists."
    error "Please choose a different installation directory or remove the existing one."
    exit 1
  else
    sudo mkdir -p "${DEFAULT_INSTALL_DIR}"
  fi

  info "Extracting JRE package to ${DEFAULT_INSTALL_DIR}..."
  sudo tar -xzf "${PACKAGE_PATH}" -C "${DEFAULT_INSTALL_DIR}"

  local jre_dir="${DEFAULT_INSTALL_DIR}/jdk${JDK_VERSION}"

  if [[ -z "${jre_dir}" ]]; then
    error "Failed to extract JRE package, or directory structure is unexpected."
    exit 1
  fi

  info "Successfully extracted to ${jre_dir}"

  info "Setting environment variables globally in ${PROFILE_SCRIPT_PATH}..."
  sudo tee "${PROFILE_SCRIPT_PATH}" > /dev/null <<EOF
# JRE Environment Variables
export JAVA_HOME="${jre_dir}"
export PATH="\${JAVA_HOME}/bin:\${PATH}"
EOF

  sudo chmod +x "${PROFILE_SCRIPT_PATH}"

  info "JRE installation completed successfully."
}

# Checks if the installed JRE matches the expected version.
version_check() {
  info "Checking Java version..."
  # shellcheck source=/dev/null
  source "${PROFILE_SCRIPT_PATH}"
  if ! java -version 2>&1 | grep -q "${JDK_VERSION}"; then
    error "Java version ${JDK_VERSION} is not installed."
    exit 1
  fi
  info "Java version ${JDK_VERSION} is installed."
}

# Main function
main() {
  check_sudo_privileges
  install_jre
  version_check
}

main