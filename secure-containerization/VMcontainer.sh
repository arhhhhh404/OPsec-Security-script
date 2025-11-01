#!/bin/bash

set -euo pipefail

error_exit() {
  echo "[!]> ERROR: $1"
  exit 1
}

if [ $# -lt 1 ]; then
  echo "Usage: $0 <nom_app> [network_type]"
  echo "network_type: none | restricted | full"
  echo "enable_gui: yes | no"
  exit 1
fi

APP_NAME="$1"
NETWORK_TYPE="${2:-none}"
ENABLE_GUI="${3:-no}"
VM_NAME="${APP_NAME}-VM"
IMG_BASE="/var/lib/libvirt/images/"
IMG_VM="${IMG_BASE}${VM_NAME}.qcow2"
CLOUD_DIR="$HOME/cloud-init-${APP_NAME}"

echo "[+] Maj + dependance installation..."
sudo apt update || error_exit "Updating failure."
sudo apt install -y libvirt-clients libvirt-daemon-system virtinst cloud-utils genisoimage docker.io policycoreutils selinux-utils selinux-basics wget || error_exit "Installation failure."

sudo systemctl enable --now libvirtd || error_exit "Starting of libvirtd failure."

echo "[+] Searching for: $APP_NAME"
DOCKER_NAME=$(docker search "$APP_NAME" | /usr/bin/awk 'NR==2 {print $1}')

if [ -z "$DOCKER_NAME" ]; then
  error_exit "No Docker image find for: $APP_NAME."
fi

echo "[+]> installation of the image-cloud"
sudo wget -nc -O "${IMG_BASE}debian-12-generic-amd64.qcow2" https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2 || error_exit "Downloading of the debian cloud image failure."

echo "[+]> create the cloud-init"
mkdir -p "$CLOUD_DIR" || error_exit "Cloud init directory failure."
cat > "$CLOUD_DIR/user-data" <<EOF
#cloud-config
users:
  - name: nobody
    sudo: ALL=(ALL) NOPASSWD:ALL

package_update: true
package_upgrade: true
packages:
  - docker.io
  - policycoreutils
  - selinux-utils
  - selinux-basics
  - ufw

runcmd:
  # SELinux enforcing
  - setenforce 1
  - sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

  # Firewall strict par défaut
  - ufw default deny incoming
  - ufw default deny outgoing
EOF

# --- Config réseau ---
if [[ "$NETWORK_TYPE" == "restricted" ]]; then
cat >> "$CLOUD_DIR/user-data" <<EOF
  - ufw allow out 80,443/tcp
EOF
elif [[ "$NETWORK_TYPE" == "full" ]]; then
cat >> "$CLOUD_DIR/user-data" <<EOF
  - ufw default allow outgoing
EOF
fi

cat >> "$CLOUD_DIR/user-data" <<EOF
  - ufw --force enable

  # Docker service
  - systemctl enable docker
  - systemctl start docker

EOF

# --- Conteneur Docker ---
DOCKER_RUN="docker run -d --name=${APP_NAME}-app --user 1000:1000 --cap-drop=ALL --cap-add=NET_BIND_SERVICE --read-only --tmpfs /tmp"

# Graphique support
if [[ "$ENABLE_GUI" == "yes" ]]; then
  DOCKER_RUN="$DOCKER_RUN -e DISPLAY=:0 -v /tmp/.X11-unix:/tmp/.X11-unix"
fi

# Network config
if [[ "$NETWORK_TYPE" == "none" ]]; then
  DOCKER_RUN="$DOCKER_RUN --network none"
fi

DOCKER_RUN="$DOCKER_RUN -e DISABLE_TELEMETRY=1 $DOCKER_NAME"

cat >> "$CLOUD_DIR/user-data" <<EOF
  - $DOCKER_RUN
EOF
cat > "$CLOUD_DIR/meta-data" <<EOF
instance-id: $VM_NAME
local-hostname: $VM_NAME
EOF

cloud-localds "$CLOUD_DIR/seed.iso" "$CLOUD_DIR/user-data" "$CLOUD_DIR/meta-data" || error_exit "ISO seed creation failure."

echo "[+]> clone the image"
sudo qemu-img create -f qcow2 -b "${IMG_BASE}debian-12-generic-amd64.qcow2" "$IMG_VM" 10G || error_exit "VM image creation failure."

NET_OPTION="--network network=default"
if [[ "$NETWORK_TYPE" == "none" ]]; then
  NET_OPTION="--network none"
fi

sudo virt-install \
    --name "$VM_NAME" \
    --memory 2048 \
    --vcpus 2 \
    --disk path="$IMG_VM",format=qcow2 \
    --disk path="$CLOUD_DIR/seed.iso",device=cdrom \
    --os-variant=debian12 \
    --import \
    $NET_OPTION \
    --graphics none \
    --noautoconsole || error_exit "VM installation failure."

echo "[+] Starting of $VM_NAME..."
sudo virsh start "$VM_NAME" || error_exit "$VM_NAME starting failure."
