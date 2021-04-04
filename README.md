# Ansible Playbooks and Scripts for Initial Raspberry Pi Lockdown

> Simple Ansible playbooks, roles, tasks and scripts to lock down and perform initial setup for a new Raspberry Pi.

## Assumptions and Dependencies

These playbooks assume a freshly minted Raspberry Pi running the current version of either Raspbian or Raspbian Lite.

These playbooks also assume that you have [Ansible installed](https://docs.ansible.com/ansible/latest/intro_installation.html) and ready on your control machine.

## Scripts
### Raspbian install

The script `scripts/install.sh` fetched the latest *Raspbian* image and tries to clone it on the SD card.

To execute the script, run:
```bash
./scripts/install.sh /dev/diskN
```

where `diskN` is the SD card disk. To discover this value, you have to run

```bash
diskutil list
```

The script will use `wget` to download the latest image, `unzip` to unzip it, `dd` to copy the image on the SD card and eventually `diskutil` to eject the SD card.

#### Variables

The following variables may be configured to customize the script:
- `RPI_OS_IMAGE_URL`: URL for dowloading OS for Raspberry (default is `https://downloads.raspberrypi.org/raspbian_lite_latest`);
- `UNZIP_CMD`: command to run to unzip downloaded OS (default is `unzip`)

### Setup Wi-Fi and SSD on the SD card

To setup WLAN supplicant (to connect to the Wi-Fi) and SSH, you may use the scripts:
- `scripts/network.sh`: this script creates the file `wpa_supplicant.conf` in the mounted SD card and creates an empty SSH file to enable SSD. You must set the environment variables `SSID` and `PSK`;
- `scripts/ssh-key.sh`: this scripts takes a list of users (space separated) and generates an SSH key for each one. Eventually copies the SSH key to the Raspberry and tests if everything works. You must set the environment variable `RASPBERRY_HOST` as the host of you raspberry.

## Ansible Playbooks

### Inventory

When a Pi first boots it (usually) receives a DHCP assigned IP address, which the `bootstrap` playbook changes to a static IP.

To save having to create an inventory file and then immediately update it, these playbooks use a _feature_ of the `--inventory` command line argument for `ansible-playbook` where you can supply an IP address followed _**immediately**_ by a comma so that Ansible knows the inventory is a list of hosts (even though there's a single host being targeted).

Like this ... `--inventory 192.168.10.20,`

### `pi_password` Playbook

Changes the password for the default `pi` account.

Why the separate playbook? As this playbook changes the password that Ansible is using to authenticate, Ansible will have reload its inventory and host variables, which will fail as the password provided at the start of the playbook is no longer valid.

See [this discussion](https://github.com/ansible/ansible/issues/15227) for more background.

### 
### Usage

```bash
$ ansible-playbook --user pi --ask-pass --inventory 'IP-ADDRESS,' pi_password.yml
```

Running this playbook on a Raspberry Pi with an initial DHCP assigned IP address of `192.168.1.237` will look something like this.

```bash
$ ansible-playbook --user pi --ask-pass -i <path to hosts> pi-password.yml
SSH password:
New pi account password:
confirm New pi account password:

PLAY [Default pi account password reset playbook] ******************************

TASK [Gathering Facts] *********************************************************
ok: [192.168.1.237]

TASK [pi-password : Set a new password for the default "pi" account] ***********
changed: [192.168.1.237]

PLAY RECAP *********************************************************************
192.168.1.237              : ok=2    changed=1    unreachable=0    failed=0   
```

## Lockdown Playbook

Performs some initial setup and lockdown on your new Pi.

* Creates a new user and deploys an SSH public key for the user
* Expands the root filesystem to fill any remaining space on the Pi's SD card
* Disables password authentication and enforces SSH key authentication
* Installs Docker on the RaspberryPi
* Creates and configures a UFW for RaspberryPi opening only the port `22`
* Sets a static IP address, router and DNS servers
* Sets the hostname for the RaspberryPi (local)
* Sets `wpa_supplicant` for connecting via WiFi (wifi)

### Usage

```bash
$ ansible-playbook --user pi --ask-pass -i <path to hosts> --tags "bootstrap,wifi,local" bootstrap.yml
```

`bootstrap.yml` playbook has four tags:
- **bootstrap**: defines the abovementioned operations without setting WiFi and local hostname;
- **docker**: installs and setups docker;
- **wifi**: sets wpa_supplicant for Raspberry;
- **local**: sets Raspberry host as desired for local machine.

Running this playbook on the same Raspberry Pi described above, with a static IP of `192.168.1.90` looks something like this (remember to use the new password for the `pi` account!)

```bash
$ ansible-playbook --user pi --ask-pass -i <path to hosts> --tags "bootstrap" lockdown.yml
SSH password:
User name: dario 
Password:
confirm Password:
Username description: Super Account
Path to public SSH key [keys/id_rsa.pub]: ./keys/id_rsa.pub
Ethernet interface [wlan0]:
Static IPv4 address: 192.168.1.90
Routers (comma separated): 192.168.1.1
DNS servers (comma separated) [192.168.1.1]:

...
```

The latter command will setup your Raspberry with the provided variables and will install Docker on it.

To avoid variables prompt, you can provide a variables file via `--extra-vars '@path-to-vars.{yml,json}`.

## Contribution

When contributing to this repository, please first discuss the change you wish to make via issue,
email, or any other method with the owners of this repository before making a change. 
