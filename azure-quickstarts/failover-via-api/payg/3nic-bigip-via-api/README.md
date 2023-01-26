## Azure login

1. `az login`
2. set the correct subscription 
```
# view and select your subscription account

az account list -o table
SUBSCRIPTION=<id>
az account set --subscription $SUBSCRIPTION
```