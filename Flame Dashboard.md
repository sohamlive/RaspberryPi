# Flame Dashboard

The [Flame Dashboard](https://github.com/jordanm88/flame-dashboard "Flame Dashboard") is used as an entry point to the services running in the home lab. Displays all the applications, bookmarks, etc and is customisable. 

The docker compose file works for Raspberry Pi. If running on a different architecture/machine, check the [Docker Hub](https://hub.docker.com/r/pawelmalak/flame#! "Docker Hub") for other images.

## Docker Compose

Run by `docker compose up -d`

Once started, it can be accessed by http://\<ip-address\>:5005.

```yaml
version: '3.6'

services:
  flame:
    image: pawelmalak/flame:multiarch
    container_name: flame
    volumes:
      - './data:/app/data'
    ports:
      - "5005:5005"
    environment:
      - PASSWORD=password123
    restart: unless-stopped
```