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

📌 *(Insert your flow architecture image here)*  
Example:
- User traffic → Application Gateway → Backend VMs → MSSQL
- Traffic inspection via Azure Firewall
- Secure admin access via Bastion Host

---

### 📍 Architecture Diagram 2: Full Component View

> This diagram represents the **complete infrastructure layout and all deployed Azure resources**.

📌 *(Insert full component architecture diagram here)*  

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
