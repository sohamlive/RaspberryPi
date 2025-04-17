# PiHole on Docker with NGINX

This is to be used when Nginx Proxy Manager is being used. Uses the latest Docker compose script.

Better to use it with Portainer since it allows easier maintainability.

## Steps
1. Open Portainer and go to Stacks.
2. Click on Add Stack and in the Web Editor, paste the following compose script.
3. Click on Deploy Stack.

## Docker Compose

It can also be run by Run by `docker compose up -d`

```yaml
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "8080:80/tcp" # For Web UI. 192.168.1.2:8080 will lead to Web UI.
    dns:
      - 127.0.0.1
    environment:
      TZ: 'Asia/Kolkata'
      WEBPASSWORD: 'Jamshedpur@123' # Set your Pi-Hole Web UI password here
      FTLCONF_REPLY_ADDR4: "192.168.1.2" # Set your Pi's static IP here
    # Volumes store your data between container upgrades
    volumes:
      - './etc-pihole:/etc/pihole'
      - './etc-dnsmasq.d:/etc/dnsmasq.d'
    restart: unless-stopped
```
