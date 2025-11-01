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
cd OPsec-Security-script/secure/containerization
chmod +x VMcontainer.sh
```

---

### Usage

```bash
./setup_vm.sh <app_name> [network_type] [enable_gui]
```
- [network_type]:
-- none: No network access (completely isolated)

-- restricted: Limited access to HTTP/HTTPS (ports 80 and 443)

-- full: Full network access
--- Default value: none

- [enable_gui]:
-- yes: GUI enabled (requires X11 to be running on the host)

-- no: Console mode only
--- Default value: no
