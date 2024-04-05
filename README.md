# docker

## Commandes

1. View Image history

| Goal                          | Commands               |
|-------------------------------|------------------------|
| | docker image history --no-trunc microsoft/windowsservercore docker image history --no-trunc ygo74/winrmenabled |
| | docker image inspect ygo74/winrmenableddokcer |


2. Run a Container

| Goal                          | Commands               |
|-------------------------------|------------------------|
| | docker run --detach --name windows  microsoft/windowsservercore ping -t localhost |
| | docker run --detach --name windows -p 9985:5985  ygo74/winrmenabled |
| | docker run --detach --name windows -p 9985:5985 -m 4GB --cpus 4 ygo74/winrmenabled |
| | docker run -it -name windows  microsoft/windowsservercore |

3. Attach to a container

| Goal                          | Commands               |
|-------------------------------|------------------------|
| Attach to a container | docker attach 2b0e5afcbbed              |
| Execute interactive command | docker exec -ti 2b0e5afcbbed powershell |
| Enter powershell remote session | Enter-PSSession -ContainerId (docker ps --no-trunc -qf "name=windows") -RunAsAdministrator |

4. Remove container / images

| Goal                          | Commands               |
|-------------------------------|------------------------|
| Stop all containers           | docker stop $(docker ps -aq) |
| Remove all stopped containers (Option 1) | docker rm $(docker ps -aq) |
| Remove all stopped containers (option 2) | docker container prune |
| Remove all images             | docker rmi $(docker images -q) |
| Remove all unused images      | docker image prune     |

5. Inspect container

| Goal                          | Commands               |
|-------------------------------|------------------------|
| Inspect container by name | docker inspect (docker ps --no-trunc -qf "name=windows") |

6. Build imqge

| Goal                          | Commands               |
|-------------------------------|------------------------|
| | docker build -t ygo74/winrmenabled -f .\windows\winrmenabled . |

## Installation

### Windows Installation

| Topic | Link |
| ----- | ---- |
| Install Docker on Windows         | https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-server |
| Install Docker on Windows         | https://docs.docker.com/install/windows/docker-ee/ |
| Running Docker on bash on Windows | https://blog.jayway.com/2017/04/19/running-docker-on-bash-on-windows/ |

**Enable features**
C:\WINDOWS\syswow64\dism.exe  /online /enable-feature /featurename:Containers /all /NoRestart  
C:\WINDOWS\syswow64\dism.exe  /online /enable-feature /featurename:Microsoft-Hyper-V /all /NoRestart  

**Install Docker with Internet Access**

```powershell
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name docker -ProviderName DockerMsftProvider
Restart-Computer -Force
```

**Install Docker without Internet Access**

```powershell
# On an online machine, download the zip file.
Invoke-WebRequest -UseBasicParsing -OutFile docker-18.09.5.zip https://download.docker.com/components/engine/windows-server/18.09/docker-18.09.5.zip

# Stop Docker service
Stop-Service docker

# Extract the archive.
Expand-Archive docker-18.09.5.zip -DestinationPath $Env:ProgramFiles -Force

# Clean up the zip file.
Remove-Item -Force docker-18.09.5.zip

# Install Docker. This requires rebooting.
$null = Install-WindowsFeature containers

# Add Docker to the path for the current session.
$env:path += ";$env:ProgramFiles\docker"

# Optionally, modify PATH to persist across sessions.
$newPath = "$env:ProgramFiles\docker;" +
[Environment]::GetEnvironmentVariable("PATH",
[EnvironmentVariableTarget]::Machine)

[Environment]::SetEnvironmentVariable("PATH", $newPath,
[EnvironmentVariableTarget]::Machine)

# Register the Docker daemon as a service.
dockerd --register-service

# Start the Docker service.
Start-Service docker

```

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


### Linux Installation

### Post Installation steps

(Docker documentation)[https://docs.docker.com/install/linux/linux-postinstall/]

```bash
sudo groupadd docker
sudo usermod -a -G docker almev0
sudo systemctl restart docker
```

## Operations

### Moving WSL files

sources:

- <https://woshub.com/move-wsl-another-drive-windows/>
- <https://stackoverflow.com/questions/62441307/how-can-i-change-the-location-of-docker-images-when-using-docker-desktop-on-wsl2>

``` powershell
wsl --shutdown
wsl --list -v

  NAME                   STATE           VERSION
* Ubuntu-22.04           Stopped         2
  docker-desktop         Stopped         2
  kali-linux             Stopped         2
  docker-desktop-data    Stopped         2

wsl --export Ubuntu-22.04 C:\Temp\backup\ubuntu.tar
wsl --export kali-linux  C:\Temp\backup\kali.tar
wsl --export docker-desktop C:\Temp\backup\docker-desktop.tar
wsl --export docker-desktop-data C:\Temp\backup\docker-desktop-data.tar

wsl --unregister Ubuntu-22.04
wsl --unregister kali-linux
wsl --unregister docker-desktop
wsl --unregister docker-desktop-data


wsl --import Ubuntu-22.04 c:\WSL\Ubuntu-22.04\ C:\Temp\backup\ubuntu.tar
wsl --import kali-linux c:\wsl\kali-linux  C:\Temp\backup\kali.tar
wsl --import docker-desktop c:\wsl\docker-desktop C:\Temp\backup\docker-desktop.tar
wsl --import docker-desktop-data c:\wsl\docker-desktop-data C:\Temp\backup\docker-desktop-data.tar

```