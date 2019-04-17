# docker

## Commandes

1. View Image history  
docker image history --no-trunc microsoft/windowsservercore  
docker image history --no-trunc ygo74/winrmenabled  
docker image inspect ygo74/winrmenableddokcer  

2. Run a Container  
docker run --detach --name windows  microsoft/windowsservercore ping -t localhost  
docker run --detach --name windows -p 9985:5985  ygo74/winrmenabled  
docker run -it -name windows  microsoft/windowsservercore  

3. Attach to a container  

| docker attach 2b0e5afcbbed              |
| docker exec -ti 2b0e5afcbbed powershell |
|  Enter-PSSession -ContainerId (docker ps --no-trunc -qf "name=windows") -RunAsAdministrator |

4. Remove container  
| Goal                          | Commands               |
|-------------------------------|------------------------|
| Remove all stopped containers | docker container prune |

5. Build imqge

| docker build -t ygo74/winrmenabled -f .\windows\winrmenabled . |

## Installation

### Windows Installation

| Topic | Link |
| ----- | ---- |
| Running Docker on bash on Windows | https://blog.jayway.com/2017/04/19/running-docker-on-bash-on-windows/ |


**Configure Docker on WSL**

```bash
cat <<EOT >> ~/.bash_profile
# Quick access to docker (Windows 10 Creators Update requirement)
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
export PATH="$PATH:/mnt/c/Program\ Files/Docker/Docker/resources/bin"
alias docker=docker.exe
alias docker-compose=docker-compose.exe

# Connect to Docker on Windows
#export DOCKER_HOST=tcp://192.168.99.100:2376  // your Docker IP
#export DOCKER_CERT_PATH=/mnt/c/Users/YOUR_USERNAME/.docker/machine/certs
#export DOCKER_TLS_VERIFY=1
export DOCKER_HOST='tcp://0.0.0.0:2375'
EOT
```

**Issues**
1. Shared Drives issues with Shared Drives  
Set-NetConnectionProfile -interfacealias "vEthernet (DockerNAT)" -NetworkCategory Private
