# docker

## Installation

### Windows Installation

| Topic | Link |
| ----- | ---- |
Running Docker on bash on Windows | https://blog.jayway.com/2017/04/19/running-docker-on-bash-on-windows/


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