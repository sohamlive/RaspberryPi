# Nginx Proxy Manager
The [Nginx Proxy Manager](https://nginxproxymanager.com/ "Nginx Proxy Manager") is needed to route the domain names to services running on different ports using the reverse proxy feature. 

**The NPM needs to run on port 80 of the server so that it can intercept and redirect the calls.**

Default username is *admin@example.com*. 

Default password is *changme*.

## Docker Compose
Run by `docker compose up -d`

Once started, NPM can be accessed at http://\<ip-address\>:81
```yaml
version: "3"
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      # These ports are in format <host-port>:<container-port>
      - '80:80' # Public HTTP Port
      - '443:443' # Public HTTPS Port
      - '81:81' # Admin Web Port
      # Add any other Stream port you want to expose
      # - '21:21' # FTP

    # Uncomment the next line if you uncomment anything in the section
    # environment:
      # Uncomment this if you want to change the location of 
      # the SQLite DB file within the container
      # DB_SQLITE_FILE: "/data/database.sqlite"

      # Uncomment this if IPv6 is not enabled on your host
      # DISABLE_IPV6: 'true'

    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
```

## Adding redirection capabilities
For this to work, Pi Hole needs to be configured first since that is the primary DNS server on the network. In the Pi Hole DNS settings, add a record for the custom domain you want (eg - sudo.me) and map it to the device you want to point. You cannot add the port number to a DNS record.

All calls made to the domain will be listened to by the NPM on port 80 of the device and based on the domain, it will redirect to the *specific port* on the device on which there are different services. In this way, a single device can host many services and we can have custom domains for each of them.

## Redirecting to a specific location
By default, all the redirection done by NPM will go to the root of the service running at the port i.e \<ip-address\>:\<port\> and not to \<ip-address\>:\<port\>\/location. If you want to redirect an URL to a specific location, use this code in the custom Nginx configurations - 

This configuration will redirect all calls made to http://pi.lab to http://192.168.1.5:8080/admin/. Without this, the calls made to the pi.lab domain will remain at the root and will give an error.

```
# Pihole /admin/ Fix
 location / {
 proxy_pass http://192.168.1.5:8080/admin/;
 proxy_set_header Host $host;
 proxy_set_header X-Real-IP $remote_addr;
 proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
 proxy_hide_header X-Frame-Options;
 proxy_set_header X-Frame-Options "SAMEORIGIN";
 proxy_read_timeout 90;
 }
```