---
layout: default
title: Usefull commands
nav_order: 2
has_children: false
---

## Docker Commands

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

