# OPsec-Security-script
this repo have some OPsec or secure script.

## secure-containerization

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
./VMcontainer.sh <app_name> [network_type] [enable_gui]
```
- [network_type]:
  
  - none: No network access (completely isolated)

  - restricted: Limited access to HTTP/HTTPS (ports 80 and 443)

  - full: Full network access

    - Default value: none

- [enable_gui]:

  - yes: GUI enabled (requires X11 to be running on the host)

  - no: Console mode only

    - Default value: no
   
#### Exemple

```bash
./VMcontainer.sh librewolf full yes
```

---

## firefox-opsec-session

### Features

- Launches a **temporary Firefox session** isolated in memory (`tmpfs`).
- Creates a secure ephemeral Firefox profile (auto-deleted on exit).
- Allows configuration of an optional **SOCKS** or **HTTP** proxy.
- Disables most Firefox telemetry, WebRTC, and tracking features.
- Prevents persistent data storage — cookies, cache, history are wiped on exit.
- Can allocate custom RAM size for the temporary profile (default: 64 MB).
- Automatically unmounts and cleans up after Firefox closes.
- Compatible with Wayland and X11.

---

### Prerequisites

- Host system: Debian, Ubuntu, or any Linux distribution supporting `bash`, `firefox`, and `tmpfs`.
- Required packages:
  - `firefox`
  - `sudo`
  - `coreutils` (for `mktemp`, `chmod`, `find`, etc.)
  - `mount`, `umount`
- `sudo` access is required **only for mounting tmpfs**.

---

### Installation

```bash
git clone https://github.com/arhhhhh404/OPsec-Security-script.git
cd OPsec-Security-script/firefox-opsec
chmod +x sessionweb.sh
```

---

### Usage

```bash
./sessionweb.sh [proxy_type] [proxy_host] [proxy_port]
```
- [Proxy type]:
  
  - http: A http proxy

  - socks: A socks proxy
    
    - Default value: none

- [Proxy host]:

  - give the ip of the proxy

    - Default value: none
   
- [Proxy host]:

  - give the ip of the proxy

    - Default value: none
   
#### Exemple

```bash
./sessionweb.sh --proxy-type socks --proxy-host 127.0.0.1 --proxy-port 9050
```

---
