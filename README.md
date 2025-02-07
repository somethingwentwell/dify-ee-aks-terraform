# Dify EE AKS Terraform

This repository contains Terraform configurations and scripts for deploying and managing Dify Enterprise Edition using PaaS components like Azure Kubernetes Service (AKS) and Azure Database for PostgreSQL. It automates the setup of necessary infrastructure, configuration of AKS, and generation of Helm values for deploying the application.

## Important Note

This setup is intended for **Proof of Concept (PoC)** purposes only. The PostgreSQL database and Blob Storage are exposed to the internet, which is not suitable for production environments. For production best practices, please consult the Dify team to ensure secure and scalable deployment.

## Features

- **Terraform Infrastructure Management**: Automates the provisioning of Azure resources, including AKS, PostgreSQL, and Blob Storage.
- **Helm Values Generation**: Dynamically generates `values.yaml` for Helm deployments using Terraform outputs.
- **AKS Configuration**: Configures `kubectl` with AKS credentials for seamless Kubernetes management.
- **Domain Configuration**: Outputs `consoleWebDomain` and `enterpriseDomain` for application access.

## Prerequisites

Before using this repository, ensure you have the following installed:

- [Terraform](https://www.terraform.io/downloads.html)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)

## Usage

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-org/dify-ee-aks-terraform.git
   cd dify-ee-aks-terraform
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Apply Terraform Configuration**:
   Run the following command to provision the infrastructure:
   ```bash
   terraform apply -var="subscription_id=your-azure-subscription-id"
   ```
   Review the plan and confirm the changes.

4. **Generate Helm Values and Configure AKS**:
   Use the provided script to configure AKS and generate the `values.yaml` file:
   ```bash
   . ./configure_aks_and_generate_helm_values.sh
   ```
   This script will:
   - Fetch Terraform outputs.
   - Configure `kubectl` with AKS credentials.
   - Generate `values.yaml` for Helm deployment.

5. **Deploy with Helm**:
   Use the generated `values.yaml` to deploy the application:
   ```bash
   helm repo add dify https://langgenius.github.io/dify-helm
   helm repo update
   helm upgrade -i dify -f values.yaml dify/dify
   ```

## Outputs

You can access the console from the `consoleWebDomain` specified in `values.yaml` and use the `enterpriseDomain` from `values.yaml` for license activation.

## File Structure

- `main.tf`: Terraform configuration for provisioning Azure resources.
- `configure_aks_and_generate_helm_values.sh`: Script for configuring AKS and generating Helm values.
- `values.yaml.template`: Template for generating `values.yaml`.
- `README.md`: Project documentation.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.