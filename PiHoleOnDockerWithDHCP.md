# PiHole on Docker with DHCP

The following is a guide to install PiHole on Docker with DHCP enabled. It has been tested on Raspberry Pi OS (64 bit).
This uses the `host` Docker networking mode and hence any other service cannot run on the same device or may give problems. The PiHole admin web page can be accessed at http://pi.hole .

The following environment variables are absolutely necessary - 
1. `WEBPASSWORD` - Used for accessing the PiHole web interface. Not setting it during install time will result in PiHole generating a random password which will be displayed *inside* the Docker container after successful installation.
2. `FTLCONF_REPLY_ADDR4` - Static IP of the device PiHole is running on. Used for the resolution of the admin page by its own custom URL.

## Docker Compose

Run by `docker compose up -d`

```yaml
version: "3"

# More info at https://github.com/pi-hole/docker-pi-hole/ and https://docs.pi-hole.net/
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    # For DHCP it is recommended to remove these ports and instead add: network_mode: "host"
    network_mode: "host"
    #ports:
      #- "53:53/tcp"
      #- "53:53/udp"
      #- "67:67/udp" # Only required if you are using Pi-hole as your DHCP server
      #- "80:80/tcp"
    environment:
      TZ: 'Asia/Kolkata'
      WEBPASSWORD: 'Jamshedpur@123'
      FTLCONF_REPLY_ADDR4: "192.168.1.5"
    # Volumes store your data between container upgrades
    volumes:
      - './etc-pihole:/etc/pihole'
      - './etc-dnsmasq.d:/etc/dnsmasq.d'    
    #   https://github.com/pi-hole/docker-pi-hole#note-on-capabilities
    cap_add:
      - NET_ADMIN # Required if you are using Pi-hole as your DHCP server, else not needed
    restart: unless-stopped
```