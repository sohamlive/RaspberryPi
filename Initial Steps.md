# Initial Steps
![Latest Release](https://img.shields.io/badge/Updated%20on-3rd%20June%202023-informational?style=for-the-badge)

The following document details the initial steps to be taken after starting up a Raspberry Pi 4B for the first time.

It is assumed that Raspberry Pi OS has been installed with user as `pi` and SSH enabled.

## Update
1. Update the package list - `sudo apt update`
2. Run a full upgrade on the packages which will install any additional dependencies - `sudo apt full-upgrade`
3. Reboot the system - `sudo reboot -h now`

*Cleaning up after the update*
1. Remove packages which are no longer required - `sudo apt upgrade`
2. Clean up package archive - `sudo apt clean`

## Block/Unblock Wifi & Bluetooth
1. Install rkfill package - `sudo apt install rfkill`
2. Block Wifi/Bluetooth - `sudo rfkill block wifi` `sudo rfkill block bluetooth`
3. Unblock Wifi/Bluetooth - `sudo rfkill unblock wifi` `sudo rfkill unblock bluetooth`

## Docker
1. Download and run the Docker installation script -
`curl -sSL https://get.docker.com | sh`
2. Normally Docker can only be called by the root superuser `su`. So, add the `pi` user to the docker group -
`sudo usermod -aG docker pi`
3. Since we made changes to the `pi` user, logout and login by - `logout`
4. After logging back in, check whether the user `pi` has been added to the groups by - `groups`
5. Test docker by running the Hello World container - 
`docker run hello-world`

## Setting static IP
*This is needed to get PiHole working without dependence on router's DHCP*
1. Retrieve the currently defined router (gateway) for the network - `ip r | grep default`
Make note of the first IP in the string. It is the gateway address (eg - 192.168.1.1).
2. Retrieve the current DNS server of the network - `sudo nano /etc/resolv.conf`
Copy the IP address at the nameserver (eg - 8.8.8.8).
3. Modify the “dhcpcd.conf” configuration file - `sudo nano /etc/dhcpcd.conf`
4. Static IP can be set for ethernet "`eth0`" connection or WiFi "`wlan0`" connection. Replace the following placeholders as needed - 
```
# <NETWORK> = eth0 or wlan0
# <STATICIP> = static IP needed for RPi
# <ROUTERIP> = router/gateway IP
# <DNSIP> = DNS IP
interface <NETWORK>
static ip_address=<STATICIP>/24
static routers=<ROUTERIP>
static domain_name_servers=<DNSIP>
```
5. Save the file by `Ctrl` + `X` and then `Y`.
6. Reboot for the changes to take place - `sudo reboot -h now`