# Create Jenkins images

## Jenkins Master

## Jenkins slave
we need to be able to do Docker in Docker. Term is DinD.  
https://support.cloudbees.com/hc/en-us/articles/360001566111-Set-up-a-Docker-in-Docker-Agent-Template


Not applicable : doesn' work
Steps :
* Got to Curent directory : jenkins
* Execute command :  
```cmd
docker build slave --tag jenkins-slave:0.1
```


## Jenkins Github integration
https://support.cloudbees.com/hc/en-us/articles/115003015691-GitHub-Webhook-Non-Multibranch-Jobs

Credential:  
type : secret text
value : github api token

## jenkins ACR Integration
Credential:  
type : UserName  / password



### Azure ACR registration
```
az acr login --name mesfcontainerregistry
docker tag jenkins-slave:0.1 mesfcontainerregistry.azurecr.io/jenkins-slave:0.1
docker tag jenkins-slave:0.1 mesfcontainerregistry.azurecr.io/jenkins-slave:latest

docker push mesfcontainerregistry.azurecr.io/jenkins-slave:0.1
docker push mesfcontainerregistry.azurecr.io/jenkins-slave:latest
```