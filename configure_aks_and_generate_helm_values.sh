#!/bin/bash

# Fetch Terraform outputs dynamically
BLOB_ACCOUNT_URL=$(terraform output -raw blob_account_url)
BLOB_ACCOUNT_KEY=$(terraform output -raw blob_account_key)
# Extract the Blob Account Name from the Blob Account URL
BLOB_ACCOUNT_NAME=$(echo $BLOB_ACCOUNT_URL | awk -F[/:] '{print $4}' | cut -d'.' -f1)
POSTGRES_FQDN=$(terraform output -raw postgres_fqdn)
POSTGRES_ADMIN_USER=$(terraform output -raw postgres_admin_user)
POSTGRES_ADMIN_PASSWORD=$(terraform output -raw postgres_admin_password)
AKS_CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
RESOURCE_GROUP_NAME=$(terraform output -raw resource_group_name)
# Configure kubectl with AKS credentials
echo "Configuring kubectl with AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME

# Load Traefik Ingress IP using kubectl
INGRESS_IP=$(kubectl get svc -n traefik traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Replace dots in the ingress IP with dashes
INGRESS_IP_DASHED=$(echo $INGRESS_IP | sed 's/\./-/g')

# Replace placeholders in values.yaml.template and save to values.yaml
sed -e "s|<BLOB_ACCOUNT_URL>|$BLOB_ACCOUNT_URL|g" \
    -e "s|<BLOB_ACCOUNT_KEY>|$BLOB_ACCOUNT_KEY|g" \
    -e "s|<BLOB_ACCOUNT_NAME>|$BLOB_ACCOUNT_NAME|g" \
    -e "s|<POSTGRES_FQDN>|$POSTGRES_FQDN|g" \
    -e "s|<POSTGRES_ADMIN_USER>|$POSTGRES_ADMIN_USER|g" \
    -e "s|<POSTGRES_ADMIN_PASSWORD>|$POSTGRES_ADMIN_PASSWORD|g" \
    -e "s|<INGRESS_IP>|$INGRESS_IP_DASHED|g" \
    values.yaml.template > values.yaml

echo "values.yaml has been generated successfully."