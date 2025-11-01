# OPsec-Security-script
this repo have some OPsec or secure script.

##secure-containerization

### Features

- Creates a Debian 12 VM via `libvirt` and `virt-install`.
- Installs Docker and runs the application in a secure container.
- Enables SELinux in `enforcing` mode.
- Configures a strict firewall with `ufw`:
- `none`: no network access for the container. 
- `restricted`: outbound access limited to HTTP/HTTPS. 
- `full`: full network access.
- Option for graphical display for GUI applications.
- Attempts to disable telemetry for the Docker application.

---

### Prerequisites

- Host system based on Debian/Ubuntu.
- Packages: `libvirt`, `virtinst`, `cloud-utils`, `genisoimage`, `docker.io`, `policycoreutils`, `selinux-utils`, `selinux-basics`, `ufw`, `wget`.
- `sudo` access.

---

### Installation

```bash
git clone https://github.com/arhhhhh404/OPsec-Security-script.git
cd OPsec-Security-script
chmod +x VMcontainer.sh
```

---

### Usage

```bash
./setup_vm.sh <app_name> [network_type] [enable_gui]
```
