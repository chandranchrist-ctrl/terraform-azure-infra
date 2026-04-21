# 🚀 Project 1: Modular and Secure Azure Hub-and-Spoke Architecture with Application Gateway, Firewall, and MSSQL (Terraform)

## 📌 Overview

This project demonstrates a **secure, scalable, and modular Azure infrastructure** built using Terraform. The architecture follows a **hub-and-spoke network model** with centralized security control and distributed application workloads.

It is designed with an emphasis on:
- Security-first cloud architecture
- Modular Terraform design (root + reusable modules)
- Enterprise-grade networking and access control
- Scalable compute and data services

The entire infrastructure is provisioned using Infrastructure as Code (IaC) principles using Terraform.

---

## 🏗️ Architecture Design

### 📍 Architecture Diagram 1: Resource Flow

> This diagram shows the **end-to-end request flow and traffic movement** across Azure components.

<img width="1535" height="1048" alt="image" src="https://github.com/user-attachments/assets/388664e5-69b6-4a41-b967-3fd6e6c689ec" />

Example:
- User traffic → Application Gateway → Backend VMs → MSSQL
- Traffic inspection via Azure Firewall
- Secure admin access via Bastion Host

---

### 📍 Architecture Diagram 2: Full Component View

> This diagram represents the **complete infrastructure layout and all deployed Azure resources**.

<img width="5411" height="2978" alt="Architecture_withdetails" src="https://github.com/user-attachments/assets/4f72c4ae-17de-441b-8445-576a2217b16e" />


Includes:
- Virtual Network and Subnets
- NSG and Route Tables
- Azure Firewall and Firewall Policy
- Application Gateway
- Linux & Windows VM modules
- MSSQL Server with Private Endpoint
- Key Vault for secrets management
- Storage Accounts for logs and diagnostics
- Bastion Host for secure access

---

## 📁 Folder Structure

```bash
terraform-azure-infra/
│
├── LICENSE
│
├── envs/
│   └── staging/
│       └── main.tf   # Root deployment entry point
│
└── modules/
    ├── virtual_network/
    ├── firewall/
    ├── fw_policy/
    ├── appgw/
    ├── linux_vm/
    ├── windows_vm/
    ├── mssql/
    ├── key_vault/
    ├── storage_account/
    ├── sql_logs_storage_account/
    ├── bastion/
    ├── route_tables/
    ├── private_dns/
    └── vnet_peering/

---

## 🧩 Module Breakdown

This section explains the role of each Terraform module in the overall Azure architecture.

---

### 🌐 Network Layer

This layer forms the foundation of the architecture and controls all network connectivity, segmentation, and routing.

- **Virtual Network (VNet)** – Core network boundary that hosts all Azure resources  
- **Subnets** – Logical segmentation of workloads such as application, data, and security zones  
- **NSG (Network Security Groups)** – Controls inbound and outbound traffic at subnet and NIC level  
- **Route Tables** – Defines custom routing paths, typically through Azure Firewall for traffic inspection  
- **VNet Peering** – Enables secure communication between multiple virtual networks  

---

## 🔐 Security Layer

This layer ensures centralized security control, identity protection, and secure traffic inspection across the architecture.

- **Azure Firewall + Firewall Policy** – Provides centralized traffic filtering and network-level security enforcement  
- **Key Vault (Secrets, Keys, Certificates)** – Secure storage for credentials, encryption keys, and certificates  
- **Private DNS Zones** – Enables secure name resolution for private endpoints within the virtual network  
- **Diagnostic Settings** – Collects logs and telemetry for monitoring, auditing, and compliance  

---

## 🖥️ Compute Layer

This layer hosts the application workloads and virtual machines.

- **Linux VM Module** – Deploys Linux-based application servers  
- **Windows VM Module** – Deploys Windows-based application servers  
- **VM Extensions (AMA, initialization scripts)** – Used for monitoring, configuration, and automated setup tasks  
- **Availability Sets** – Ensures high availability and fault tolerance for virtual machines  
- **Application Security Groups (ASG)** – Logical grouping of VMs for simplified network security rule management  

---

## 🗄️ Data Layer

This layer manages database services and secure data storage.

- **Azure SQL Server (MSSQL)** – Managed relational database service  
- **SQL Database** – Stores application data  
- **Transparent Data Encryption (TDE)** – Encrypts data at rest automatically  
- **Private Endpoint Integration** – Ensures secure, private connectivity to SQL Server  
- **Auditing & Vulnerability Assessment** – Provides security monitoring and compliance checks for databases  

---

## 🌍 Application Layer

This layer manages traffic distribution and application routing.

- **Application Gateway (AppGW)** – Layer 7 load balancer with routing capabilities (and optional WAF support)  
- **Backend VM Integration** – Connects application gateway to virtual machine backend pool  
- **Load Balancer (existing/integrated)** – Handles internal traffic distribution where applicable  

---

## 💾 Storage Layer

This layer provides persistent storage and log management.

- **Storage Accounts (General + SQL logs)** – Stores application data, logs, and diagnostic information  
- **Blob Containers** – Object storage for unstructured data  
- **Lifecycle Management Policies** – Automates data retention, archiving, and cleanup  

---

## 🛠️ Management Layer

This layer provides operational support, monitoring, and secure access to resources.

- **Azure Bastion Host** – Secure access to virtual machines without exposing public IPs  
- **Recovery Services Vault (Backup)** – Manages backup and restore operations for virtual machines  
- **Monitoring & Diagnostic Settings** – Centralized logging, monitoring, and alerting for infrastructure health  

## ⚙️ Terraform Concepts Used

This project leverages multiple Terraform features to ensure modularity, scalability, and dynamic infrastructure provisioning.

---

### ✔ count
Used for creating multiple instances of similar resources dynamically when duplication is required.

---

### ✔ for_each
Used for key-value based dynamic resource creation such as:
- NSG rules  
- Key Vault secrets  
- Storage containers  

---

### ✔ depends_on
Used to explicitly control resource creation order where Azure implicit dependencies are not sufficient.

---

### ✔ dynamic blocks
Used for flexible and reusable configuration structures such as:
- Firewall rules  
- NSG rules  
- Policy-based configurations  

---

🧪 Terraform Deployment Commands

terraform init -reconfigure - Initializes Terraform working directory and reconfigures backend settings.
terraform init -migrate-state - Migrates Terraform state when backend configuration changes.
terraform plan -out=tfplan-rg - Creates an execution plan and saves it for controlled deployment.
terraform apply tfplan - Applies the saved execution plan.
terraform graph > graph.dot - Generates infrastructure dependency graph (used for visualization and architecture understanding).

🧰 PowerShell Automation Used

📌 Combine all Terraform files into a single document

$out='combined.txt'
Remove-Item $out -ErrorAction SilentlyContinue
Get-ChildItem *.tf | ForEach-Object {
    Add-Content $out ('===== ' + $_.Name + ' =====')
    Add-Content $out (Get-Content $_ -Raw)
    Add-Content $out ''
}

📌 Recursive full project export

$out='combined.txt'
Remove-Item $out -ErrorAction SilentlyContinue
Get-ChildItem -Recurse -File | ForEach-Object {
    Add-Content $out ('===== ' + $_.FullName + ' =====')
    Add-Content $out (Get-Content $_.FullName -Raw)
    Add-Content $out ''
}

🔐 Security Implementation

This architecture follows a multi-layer security approach:

🔑 Azure Key Vault for centralized secret management
🌐 Azure Firewall for traffic inspection and control
🛑 NSG rules for subnet-level security enforcement
🔒 Private Endpoints for MSSQL isolation from public internet
📊 Diagnostic logging for monitoring and auditing
💾 Backup using Recovery Services Vault
🔐 Transparent Data Encryption (TDE) for SQL Server
🚨 Vulnerability assessment enabled for database security

🧩 Optional Components

This architecture can be extended with:

1. Internal/External Load Balancer
2. MySQL database integration
3. Azure Firewall Classic Rules (alternative to policy-based rules)

🚀 Key Design Principles

1. Modular Terraform architecture using reusable modules
2. Separation of concerns between network, compute, and data layers
3. Environment-based deployment structure (envs/staging)
4. Secure-by-default configuration approach
5. Scalable infrastructure design for enterprise workloads

📌 Conclusion

This project demonstrates a real-world, production-style Azure infrastructure architecture built using Terraform modular design principles.

Key achievements include:

1. Fully modular and reusable Terraform codebase
2. Secure cloud architecture using Azure-native security services
3. Scalable and maintainable infrastructure design
4. Clear separation between root configuration and submodules

💡 The infrastructure is intentionally designed to be reusable across multiple environments (dev, staging, production) with minimal changes, making it highly efficient for enterprise adoption.

⚠️ Disclaimer
1. This project is intended for learning and architectural demonstration purposes
2. Some resources may incur Azure costs when deployed
3. Certain configurations may require subscription-level permissions or quotas
4. Private DNS resolution may require environment-specific tuning
