---
title: Getting Started with CycleCloud Workspace for Slurm
description: Deploy a complete E4S HPC Slurm cluster on Azure in a single marketplace deployment with CycleCloud Workspace for Slurm
canonical_url: https://docs.paratoolspro.com/Azure/getting-started-Azure-CCWS/
image: assets/images/gcluster/e4s_desktop_thumb.jpg
twitter_card: summary_large_image
---

# ParaTools Pro for E4S™ Getting Started with CycleCloud Workspace for Slurm

!!! info "Looking for the manual CycleCloud setup?"
    This guide covers **CycleCloud Workspace for Slurm (CCWS)**, which deploys a CycleCloud server and a running Slurm cluster in a single step, but has more limited configuration options compared to a full, manual CycleCloud deployment. To install a CycleCloud server and create clusters on it manually, see [Getting Started with Microsoft Azure](getting-started-Azure.md).

## General Background Information

[CycleCloud Workspace for Slurm][ccws-overview] (CCWS) is an Azure Marketplace solution that deploys an HPC environment in one pass. It deploys an Azure CycleCloud server, a virtual network, a NAT gateway for outbound internet access, an Azure Bastion host for inbound access, and storage, and configures and deploys a Slurm cluster that starts automatically alongside CycleCloud. This tutorial explains how to deploy CCWS to run the **ParaTools Pro for E4S™: AI/ML & HPC Tools on CycleCloud (AMD64)** image from the Azure Marketplace on the automatically-deployed Slurm cluster.

When deployed through CCWS, none of the nodes has a public IP address. All access, both to the CycleCloud web interface and to the cluster nodes over SSH, goes through the Bastion host using the Azure CLI.

This tutorial follows the same path as Microsoft's [CycleCloud Workspace for Slurm quickstart][ccws-quickstart], which includes screenshots of each step.

## Tutorial

### 1. Prerequisites

- An Azure subscription in which you have both the **Contributor** and **User Access Administrator** roles at the subscription scope. CCWS creates managed identities and assigns roles to them, which Contributor alone cannot do. See [Plan your CCWS deployment][ccws-plan] for details.
- An SSH key pair. You will paste the public key into the deployment wizard and use the private key to log in to the cluster. Generate one with `ssh-keygen -t ed25519` if needed.
- The [Azure CLI][az-cli] installed on your local machine and logged in with `az login`. The CLI is required to open Bastion tunnels to the CycleCloud web interface and the cluster nodes. You may also optionally deploy through the CLI.
- Sufficient VM quota in your chosen region for the CycleCloud node, the scheduler node, and as many compute nodes as you request.

### 2. Deploy through the marketplace wizard

In the [Azure Portal][azure-portal], search the marketplace for "CycleCloud Workspace for Slurm", select it, and click **Create**. The wizard walks through several tabs. The instructions below cover only the settings to change from their defaults; leave everything else alone.

**Basics:**

- Select your subscription and create a new resource group.
- Set **Region** to the region where you want to deploy and have sufficient quota.
- Leave the **CycleCloud VM Name** at its default, `ccw-cyclecloud-vm`. Later commands in this tutorial refer to it by that name. If you change the VM name, change it in future steps as well.
- Set **Admin User** to the username you will use for both the CycleCloud web interface and SSH to the cluster nodes, such as `cc-admin`.
- Set an **Admin Password**. This is the CycleCloud web interface password.
- Paste your SSH public key into **Admin SSH Public Key**, or select a key already stored in Azure.

**Networking:**

- Set **Virtual network options** to create a new virtual network.
- Check **Create a Bastion for SSH connections**. Without it there is no way to reach the deployment, since no VM gets a public IP.
- Check **Create a NAT Gateway**. This gives the cluster nodes outbound internet access.

**Slurm Settings:**

- Leave the **Cluster name** at its default, `ccw`. If you change the cluster name, change it in future steps as well.
- Leave **Start cluster** checked so the cluster starts as soon as the deployment finishes.
- Check **Auto-accept VM image terms**.
- Under **Scheduler**, pick a size such as `Standard_D4as_v4`, then set **Image Name** to **Custom image** and paste the ParaTools Pro for E4S™ image URN into **Custom Image ID**:

    ```text
    paratools-inc:pt-pro-4-e4s-msa-cyclecloud-amd64:paratools-pro-cyclecloud-amd64:latest
    ```

- Check **Use image on all nodes** so the login, HTC, HPC, and GPU nodes boot the same image.
- Leave **Slurm Version** at its default, `25.11.5`.
- Leave **Use login nodes** checked, and under **Login Nodes** pick a size and set both the initial and maximum number of nodes to 1.

**Partition Settings:** the cluster gets three Slurm partitions, each backed by a node array that scales from zero.

- **HTC Partition**: a small non-InfiniBand SKU such as `Standard_F2s_v2`, with a maximum node count that fits your quota. Leave **Enable Azure Spot** unchecked.
- **HPC Partition**: an InfiniBand-capable SKU such as `Standard_HB120rs_v2` or `Standard_HB120-16rs_v3`, with **Maximum number of nodes** set to what your HB-series quota allows.
- **GPU Partition**: a GPU and InfiniBand-capable SKU, with **Maximum number of nodes** set to what your GPU quota allows, or 0 if you do not intend to use GPU nodes.

**Open OnDemand:** leave **Deploy Open OnDemand** unchecked.

**Advanced** and **Tags**: leave the defaults.

Click **Review + create**, then **Create**. The deployment takes 20 to 30 minutes.

### 3. Wait for the cluster to start

The portal marking the deployment **Succeeded** does not mean the cluster is ready. The CCWS installer keeps running on the CycleCloud VM for several minutes after the deployment completes, importing and starting the cluster, and the scheduler node takes roughly another 10 minutes to boot and configure. Expect 10 to 20 minutes between deployment success and a usable cluster. You can watch progress in the CycleCloud web interface as soon as the tunnel in the next step connects.

### 4. Connect to the CycleCloud web UI

Open a Bastion tunnel from your local machine to port 443 on the CycleCloud VM:

```bash
az network bastion tunnel --name bastion --resource-group <resource-group> \
    --target-resource-id "$(az vm show -g <resource-group> -n ccw-cyclecloud-vm --query id -o tsv)" \
    --resource-port 443 --port 8443
```

The first `az network bastion` command offers to install the Azure CLI's `bastion` extension; accept. Leave the tunnel running and browse to <https://localhost:8443>. Your browser will issue a warning about the certificate because the VM's self-signed certificate does not match `localhost`; this is expected, so proceed past the warning. Log in with the admin username and password you specified in [step 2](#2-deploy-through-the-marketplace-wizard).

The cluster page for `ccw` shows the scheduler and login node provisioning. The cluster is ready when the scheduler node reaches **Started** with a green status. For more on Bastion access to the portal, see [Connect to the CycleCloud portal through Bastion][ccws-portal-bastion].

### 5. SSH into the login node

Login nodes are deployed in a VM scale set, so the Bastion needs the node's full resource ID rather than a VM name. The easiest place to get it is the CycleCloud web interface: select the `ccw` cluster, click the login node, and copy the **Resource ID** shown in the node's details. Alternatively, look it up with the CLI (Microsoft documents both approaches in [Connect to the login node through Bastion][ccws-login-bastion]):

```bash
LOGIN_ID=$(az vmss list-instances -g <resource-group> \
    -n "$(az vmss list -g <resource-group> --query "[?starts_with(name,'login')].name | [0]" -o tsv)" \
    --query "[0].id" -o tsv)
```

Then either connect in one command:

```bash
az network bastion ssh --name bastion --resource-group <resource-group> \
    --target-resource-id "$LOGIN_ID" \
    --auth-type ssh-key --username <admin-username> --ssh-key <path-to-private-key>
```

or open a port-22 tunnel, which also supports `scp` and port forwarding:

```bash
az network bastion tunnel --name bastion --resource-group <resource-group> \
    --target-resource-id "$LOGIN_ID" --resource-port 22 --port 2222
```

and, with the tunnel running, connect from a second terminal:

```bash
ssh -p 2222 -i <path-to-private-key> <admin-username>@localhost
```

The scheduler node is a regular VM, so the same commands work for it with its resource ID:

```bash
SCHED_ID=$(az vm list -g <resource-group> \
    --query "[?starts_with(name,'scheduler')].id | [0]" -o tsv)
```

### 6. VNC remote desktop (optional)

The ParaTools Pro for E4S™ image includes a VNC server for GPU-accelerated remote desktop sessions. Reuse the port-22 tunnel from [step 5](#5-ssh-into-the-login-node) and add a forward for the VNC port to the SSH connection:

```bash
ssh -p 2222 -i <path-to-private-key> -L 5901:localhost:5901 <admin-username>@localhost
```

Then point a VNC client at `localhost:5901`.

### Appendix: deploying with the Azure CLI

CCWS can also be deployed from the command line, which is useful for scripted or repeated deployments. Documentation on CLI deployments of CCWS is available in [Deploy CCWS with the CLI][ccws-cli]. The deployment takes two inputs: the Bicep template from the [CycleCloud Workspace for Slurm repository][ccws-repo], and a `parameters.json` file containing the settings the wizard would otherwise collect.

The `parameters.json` file can be produced through the Azure portal [Create UI Definition sandbox][uidef-sandbox]:

1. Clone the repository:

    ```bash
    git clone https://github.com/Azure/cyclecloud-slurm-workspace.git
    cd cyclecloud-slurm-workspace
    ```

2. Copy the entire contents of `uidefinitions/createUiDefinition.json` to the clipboard.
3. Open the [Create UI Definition sandbox][uidef-sandbox] in the Azure portal, paste the copied JSON into the text box on the right, replacing the placeholder definition already there, and click **Preview**.
4. The sandbox renders the same tabs as the marketplace wizard. Fill them in with the settings from [step 2](#2-deploy-through-the-marketplace-wizard), including the custom image URN and **Auto-accept VM image terms**.
5. On the **Review + create** tab, click **View outputs payload** next to the **Create** button. Copy the JSON it displays into a local file named `parameters.json`.

If you have already deployed CCWS through the marketplace, you can also read the settings back from that deployment: in the portal, open the resource group, select **Deployments**, pick the CCWS deployment, and open its **Inputs** tab.

Then deploy at subscription scope from the repository root:

```bash
az deployment sub create --location <region> \
    --template-file bicep/mainTemplate.bicep \
    --parameters parameters.json
```

[ccws-overview]: https://learn.microsoft.com/azure/cyclecloud/overview-ccws
[ccws-quickstart]: https://learn.microsoft.com/azure/cyclecloud/qs-deploy-ccws?view=cyclecloud-8
[ccws-plan]: https://learn.microsoft.com/azure/cyclecloud/how-to/ccws/plan-your-deployment?view=cyclecloud-8
[ccws-cli]: https://learn.microsoft.com/azure/cyclecloud/how-to/ccws/deploy-with-cli?view=cyclecloud-8
[ccws-portal-bastion]: https://learn.microsoft.com/azure/cyclecloud/how-to/ccws/connect-to-portal-with-bastion
[ccws-login-bastion]: https://learn.microsoft.com/azure/cyclecloud/how-to/ccws/connect-to-login-node-with-bastion
[ccws-repo]: https://github.com/Azure/cyclecloud-slurm-workspace
[uidef-sandbox]: https://portal.azure.com/#view/Microsoft_Azure_CreateUIDef/SandboxBlade
[azure-portal]: https://portal.azure.com/
[az-cli]: https://learn.microsoft.com/cli/azure/install-azure-cli
