# Initial Steps
![Latest Release](https://img.shields.io/badge/Updated%20on-6th%20July-informational?style=for-the-badge)

The following document details the initial steps to be taken after starting up a Raspberry Pi 4B for the first time.

## Update
1. It is assumed that Raspberry Pi OS has been installed. To update it - 
`sudo apt update`
`sudo apt upgrade`
2. Reboot the system - `sudo reboot -h now`

## Docker
1. Download and run the Docker installation script -
`curl -sSL https://get.docker.com | sh`
2. Normally Docker can only be called by the root superuser `su`. So, add the `pi` user to the docker group -
`sudo usermod -aG docker pi`
3. Since we made changes to the `pi` user, logout and login by - `logout`
4. After logging back in, check whether the user `pi` has been added to the groups by - `groups`
5. Test docker by running the Hello World container - 
`docker run hello-world`
