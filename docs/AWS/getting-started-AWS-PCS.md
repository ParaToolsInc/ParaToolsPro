---
title: Getting Started with AWS Parallel Computing Service (PCS)
description: Step-by-step tutorial for deploying E4S HPC clusters on AWS PCS with CloudFormation templates, security groups, and Slurm integration
canonical_url: https://docs.paratoolspro.com/AWS/getting-started-AWS-PCS/
image: assets/images/gcluster/e4s_heidi_infra_thumb.jpg
twitter_card: summary_large_image
---

# ParaTools Pro for E4S™ Getting Started with AWS Parallel Computing Service

!!! info "Looking for AWS ParallelCluster (PC)?"
    This guide covers **AWS Parallel Computing Service (PCS)**, the AWS-managed Slurm service. For the open-source self-managed alternative, see [Getting Started with AWS ParallelCluster](getting-started-AWS.md).

## General Background Information

This tutorial configures AWS Parallel Computing Service (PCS) with the matching **ParaTools Pro for E4S™ on AWS PCS** AMI from the AWS Marketplace:

| Architecture | AWS Marketplace product |
|---|---|
| `x86_64` | [ParaTools Pro for E4S™ on AWS PCS (x86)](https://aws.amazon.com/marketplace/pp/prodview-wryfn3vd5c63k) |
| `arm64` (Graviton) | [ParaTools Pro for E4S™ on AWS PCS (ARM64)](https://aws.amazon.com/marketplace/pp/prodview-lge7nswatwzkm) |

Use the command line tools, [AWS CLI](https://aws.amazon.com/cli/), and the AWS console to create a cluster. The workflow uses several `.yaml` files that describe the stack and serve as inputs for AWS CloudFormation. The result is a GPU-accelerated head node that can spawn EC2 compute node instances linked with EFA networking.

For the purposes of this tutorial, you have already created an [AWS account][5] and are an [Administrative User][4].

## Tutorial

For additional context, see the official [AWS PCS Getting Started](https://docs.aws.amazon.com/pcs/latest/userguide/getting-started.html) guide. This tutorial follows the official guide with a few minor changes; refer to it if anything is unclear.

### 1. Create VPC and Subnets

??? tip "It is possible to reuse existing VPC and subnets"
    If a compatible VPC and subnets already exist, skip this step and use them in place of the `VpcId`, `PrivateSubnetA`, and `PublicSubnetA` references in later steps. Search for existing PTPro VPC stacks in `us-east-1` with this [link](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks?filteringText=PTPro&filteringStatus=active&viewNested=true).

Create a new stack for the cluster's VPC and subnets [using the CloudFormation console][1] with the following template:

[`0-pcs-cluster-cloudformation-vpc-and-subnets.yaml`](../assets/aws/pcs/0-pcs-cluster-cloudformation-vpc-and-subnets.yaml)

??? note "Show template contents (click to expand)"

    ```yaml
    --8<-- "assets/aws/pcs/0-pcs-cluster-cloudformation-vpc-and-subnets.yaml"
    ```

Give the stack a name like `AWSPCS-PTPro-cluster` and leave the options at their defaults.

!!! tip "Use this AWS CloudFormation [quick-create link](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/quickcreate?templateURL=https%3A%2F%2Fs3.us-east-1.amazonaws.com%2Fcf-templates-behdg14v2lp8-us-east-1%2F2025-12-18T124707.749Zt1m-0-pcs-cluster-cloudformation-vpc-and-subnets.yaml&stackName=AWSPCS-PTPro-cluster&param_CidrPublicSubnetA=10.3.0.0%2F20&param_ProvisionSubnetsC=False&param_CidrBlock=10.3.0.0%2F16&param_CidrPrivateSubnetB=10.3.144.0%2F20&param_CidrPrivateSubnetC=10.3.160.0%2F20&param_CidrPublicSubnetC=10.3.32.0%2F20&param_CidrPublicSubnetB=10.3.16.0%2F20&param_CidrPrivateSubnetA=10.3.128.0%2F20) to quickly provision these resources with default settings"

Under "Capabilities", check the box for "I acknowledge that AWS CloudFormation might create IAM resources".

After the VPC is created, find its ID in the [Amazon VPC Console](https://console.aws.amazon.com/vpc) by selecting "VPCs" and searching for the stack name. If the suggested stack name was used, search for `PTPro`. For deployments in `us-east-1`, use this [link](https://us-east-1.console.aws.amazon.com/vpcconsole/home?region=us-east-1#vpcs:search=PTPro). Note the VPC ID for use in later steps.

### 2. Create Security Groups

???+ summary
    In this section, you will create three security groups:

    - A cluster security group enabling communication between the compute nodes, login node, and AWS PCS controller.
    - An inbound SSH group that can optionally be enabled to allow SSH logins on the login node.
    - A DCV group that can optionally be enabled to allow DCV remote desktop connections to the login node.

??? tip "It is possible to reuse existing security groups"
    If compatible security groups already exist, skip this step and substitute their IDs for the `cluster-*-sg`, `InboundSshSecurityGroupId`, and `InboundDcvSecurityGroupId` references in later steps.

Using [CloudFormation][1], create a new stack for the security groups with the following template:

[`1-pcs-cluster-cloudformation-security-groups.yaml`](../assets/aws/pcs/1-pcs-cluster-cloudformation-security-groups.yaml)

??? note "Show template contents (click to expand)"

    ```yaml
    --8<-- "assets/aws/pcs/1-pcs-cluster-cloudformation-security-groups.yaml"
    ```

- Under "Stack name", use something like `AWSPCS-PTPro-sg`.
- Set "VpcId" to the VPC ID noted in [step 1].
- Enable SSH, and optionally enable DCV access.

??? warning "Use a Quick create link"

    Use this AWS CloudFormation [quick-create link](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/quickcreate?templateURL=https%3A%2F%2Fs3.us-east-1.amazonaws.com%2Fcf-templates-behdg14v2lp8-us-east-1%2F2025-12-18T134612.678Zi9c-1-pcs-cluster-cloudformation-security-groups.yaml&stackName=AWSPCS-PTPro-sg&param_CreateInboundDcvSecurityGroup=True&param_VpcId=vpc-0c6a46e761800dead&param_CreateInboundSshSecurityGroup=True&param_ClientIpCidr=0.0.0.0%2F0) to provision these security groups in `us-east-1`. __*Change the VPC ID*__ to the one created in [step 1].

### 3. Create PCS Cluster

??? tip "It is possible to reuse an existing PCS cluster"
    If a compatible PCS cluster already exists, skip this step and reference its name in later steps.

Go to the [AWS PCS console](https://console.aws.amazon.com/pcs/home#/clusters) and create a new cluster.

- Under "Cluster setup", choose a name like `AWSPCS-PTPro-cluster`.
- Set the "Controller size" to "Small".
- Use the version of Slurm compatible with the ParaTools Pro for E4S™ image. This is usually the latest version available (`25.05` as of December 2025).
- Under "Networking":
    - Use the VPC ID created in [step 1] (e.g., `AWSPCS-PTPro-cluster...`).
    - Select the subnet labeled `PrivateSubnetA` created in [step 1].
    - Under "Security groups" choose "Select an existing security group".
        - Use the security group `cluster-*-sg` created in [step 2](#2-create-security-groups) (e.g., `cluster-AWSPCS-PTPro-sg`).
- Click "Create Cluster" to begin creating the cluster.

### 4. Create shared filesystem using EFS

- Go to the [EFS console](https://console.aws.amazon.com/efs) and ensure the region matches the region where the PCS cluster is being set up.
- Click "Create file system":
    - **Name**: something like `AWSPCS-PTPro-fs`.
    - **Virtual Private Cloud (VPC)**: the VPC ID from [step 1](#1-create-vpc-and-subnets).
- Click "Create".
- Note the "File system ID" (e.g., `fs-0123456789abcdef0`); it is needed in [step 7](#7-create-node-launch-templates).

### 5. Create an Instance Profile

!!! tip "Recommended: use the CloudFormation template"

    The fastest and least error-prone path is to deploy the CloudFormation template below, which creates the policy, role, and instance profile in one step, including the DCV license policy correctly parameterized for the stack's region.

    [`3-pcs-cluster-cloudformation-iam.yaml`](../assets/aws/pcs/3-pcs-cluster-cloudformation-iam.yaml)

    ??? note "Show template contents (click to expand)"

        ```yaml
        --8<-- "assets/aws/pcs/3-pcs-cluster-cloudformation-iam.yaml"
        ```

    Parameters:

    - `RoleNameSuffix` (default `PCS-cluster`) -- final role and instance-profile name is `AWSPCS-<RoleNameSuffix>`. The `AWSPCS-` prefix is required by AWS PCS.
    - `EnableDcvLicenseAccess` (default `true`) -- attach the DCV license read policy for remote-desktop use.

    After the stack completes, reference the `InstanceProfileName` output in the node launch template in [step 7](#7-create-node-launch-templates). Skip to [step 6](#6-create-efa-placement-group).

To create the policy and role manually via the IAM console, follow the rest of this section.

Go to the [IAM console]. Under "Access Management" → "Policies", check whether a policy matching this one already exists (search for `pcs`).
If none exists, create a new one and specify the permissions using the JSON editor as follows:

``` json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "pcs:RegisterComputeNodeGroupInstance"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
```

Name the new policy something like `AWS-PCS-policy` and note the name you chose.

???+ note "Additional optional steps to enable DCV remote desktop access"

    To access the login node via DCV, create an additional policy granting read access to the DCV license server.
    If a matching policy already exists, reuse it (search for `DCV`).
    Otherwise, create a new one, specifying the permissions with the JSON editor as follows:

    ``` json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "s3:GetObject",
                "Resource": "arn:aws:s3:::dcv-license.*/*"
            }
        ]
    }
    ```

    Give it a name like `EC2AccessDCVLicenseS3`.

    ??? note "Tighter region scope (optional)"
        The wildcard `dcv-license.*` matches only AWS-owned DCV license buckets (bucket name is reserved by AWS), so it is safe. For an explicit allowlist, enumerate the regions you deploy in, for example:

        ``` json
        "Resource": [
            "arn:aws:s3:::dcv-license.us-east-1/*",
            "arn:aws:s3:::dcv-license.us-east-2/*",
            "arn:aws:s3:::dcv-license.us-west-1/*",
            "arn:aws:s3:::dcv-license.us-west-2/*"
        ]
        ```

        In a CloudFormation template the policy Resource can be parameterized with `!Sub 'arn:${AWS::Partition}:s3:::dcv-license.${AWS::Region}/*'` so it substitutes the stack's region automatically. IAM policy JSON itself has no built-in variable for the EC2 instance's region.

Next, in the [IAM Console] go to "Access Management" → "Roles" and check whether a role starting with `AWSPCS-` already exists with the required policies attached.
Otherwise, create it as follows:

- Select "Create Role".
- For "Trusted Entity Type", choose "AWS Service".
- For "Service or use case", choose "EC2"; for "Use Case", choose "EC2".
- Click "Next".
- Under "Add permissions":
    - Add the policy created earlier in [step 5](#5-create-an-instance-profile).
    - If planning to use DCV to access the login node, also add the `EC2AccessDCVLicenseS3` policy.
    - Add the `AmazonSSMManagedInstanceCore` policy.
- Click "Next".
- Give the role a name that **must** start with `AWSPCS-` (e.g., `AWSPCS-PTPro-role`).

### 6. Create EFA Placement Group

??? tip "It is possible to reuse an existing placement group"
    If a compatible cluster placement group already exists, skip this step and reference its name in later steps.

Under the [EC2 Console], navigate to "Network & Security" → "Placement Groups" → "Create placement group".

- **Name**: something like `AWSPCS-PTPro-cluster`.
- **Placement strategy**: "Cluster".
- Click "Create group".

### 7. Create node Launch Templates

This step creates two EC2 launch templates -- one for the login node and one for compute nodes -- both wired up for EFA networking and the shared EFS filesystem.

[Using CloudFormation][1], create a new stack using the following template:

[`2-pcs-cluster-cloudformation-launch-templates.yaml`](../assets/aws/pcs/2-pcs-cluster-cloudformation-launch-templates.yaml)

??? note "Show template contents (click to expand)"

    ```yaml
    --8<-- "assets/aws/pcs/2-pcs-cluster-cloudformation-launch-templates.yaml"
    ```

Give the stack a name (e.g., `AWSPCS-PTPro-lt`). Populate the parameters as follows:

| Parameter | Value |
|---|---|
| `VpcId` | Output `VPC` from [step 1](#1-create-vpc-and-subnets) |
| `VpcDefaultSecurityGroupId` | The "default" security group of the VPC created in [step 1](#1-create-vpc-and-subnets) |
| `ClusterSecurityGroupId` | Output `ClusterSecurityGroupId` from [step 2](#2-create-security-groups) |
| `SshSecurityGroupId` | Output `InboundSshSecurityGroupId` from [step 2](#2-create-security-groups) |
| `SshKeyName` | An existing EC2 key pair you control |
| `PlacementGroupName` | Name chosen in [step 6](#6-create-efa-placement-group) |
| `NodeGroupSubnetId` | `PrivateSubnetA` from [step 1](#1-create-vpc-and-subnets) |
| `EfsFilesystemId` | EFS filesystem ID from [step 4](#4-create-shared-filesystem-using-efs) |
| `DcvUbuntuPassword` | Optional initial password for the `ubuntu` user, used to sign in to DCV web sessions (see [DCV remote desktop](#dcv-remote-desktop-optional) in step 10). Leave blank to skip and set a password manually later. Marked `NoEcho` so it is not shown in the console or stack events. |

After the stack reaches `CREATE_COMPLETE`, note the launch template names from the stack outputs. They will be named `login-<stack-name>` and `compute-<stack-name>`, and are referenced in [step 8](#8-create-node-groups).

### 8. Create node groups

A cluster requires at least two compute node groups: one for interactive login nodes (statically scaled) and one for elastic compute nodes that run jobs.

In the [AWS PCS console](https://console.aws.amazon.com/pcs/home#/clusters), select the cluster created in [step 3](#3-create-pcs-cluster), navigate to "Compute node groups", and click "Create".

!!! note "AMI selection"
    For the "AMI ID" field, use a ParaTools Pro for E4S™ PCS-compatible AMI from the AWS Marketplace. Use the same AMI for both node groups so the login and compute environments stay in sync. Pick the product matching your cluster's target architecture:

    | Architecture | AWS Marketplace product |
    |---|---|
    | `x86_64` | [ParaTools Pro for E4S™ on AWS PCS (x86)](https://aws.amazon.com/marketplace/pp/prodview-wryfn3vd5c63k) |
    | `arm64` (Graviton) | [ParaTools Pro for E4S™ on AWS PCS (ARM64)](https://aws.amazon.com/marketplace/pp/prodview-lge7nswatwzkm) |

    **Obtaining the AMI ID after subscribing:**

    1. Open the marketplace product page above and click "View purchase options" / "Continue to Subscribe".
    2. Accept the terms and wait for the subscription to be processed.
    3. Click "Continue to Configuration".
    4. Select the delivery method, software version, and AWS region matching your cluster.
    5. Copy the AMI ID shown on the configuration page (format: `ami-0123456789abcdef0`). Use this value in the "AMI ID" field when creating the compute node groups below.

    Alternatively, after subscribing, find the AMI in the [EC2 console](https://console.aws.amazon.com/ec2) under "Images" → "AMIs", filtered by "Owner alias = `aws-marketplace`" and searching for `ParaTools`.

??? tip "Recommended instance types"
    Choose instance types that match the AMI architecture. EFA is required for tightly-coupled MPI on compute nodes; GPU login nodes enable DCV/interactive visualization without EFA.

    | Role | `x86_64` | `arm64` |
    |---|---|---|
    | Compute node group | `g4dn.8xlarge` (NVIDIA T4, EFA) | `hpc7g.8xlarge` (Graviton3E, 200 Gbps EFA, no GPU) |
    | Login node group (`~4xlarge`) | `g4dn.4xlarge` (NVIDIA T4) | `g5g.4xlarge` (Graviton2 + NVIDIA T4G) |

    `g5g` has no EFA and is suited only for login / interactive visualization, not for compute.

#### 8.1 Compute node group (`compute-1`)

This is a **dynamic node group**: instances are launched when jobs are submitted and terminated after the configured idle time, scaling down to zero when the queue is empty.

- Under "Compute node group details":
    - **Compute node group name**: `compute-1`.
- Under "Compute configuration":
    - **EC2 launch template**: `compute-<stack-name>` from [step 7](#7-create-node-launch-templates).
    - **Version**: select the latest version of the launch template.
    - **IAM instance profile**: select the "Use an existing profile" radio, then under **Selected profile** choose the `AWSPCS-*` role created in [step 5](#5-create-an-instance-profile).
    - **Subnets**: `PrivateSubnetA` from [step 1](#1-create-vpc-and-subnets).
    - **Instance types**: `g4dn.8xlarge` (for `arm64` clusters, see the "Recommended instance types" tip above).
    - **Scaling configuration**: select the "Dynamic node group" radio. Set **Minimum instance count** to `0` and **Maximum instance count** to `2`.
    - **AMI ID**: select the "Custom AMI" radio, then paste the ParaTools Pro for E4S™ AMI ID obtained from the marketplace subscription (see the "AMI selection" note above).
- Leave "Capacity purchase option" at its default (`On-Demand`). Skip "Scheduler configuration" and "Tags".
- Click "Create compute node group" and wait for the "Status" field to show "Active" before proceeding.

#### 8.2 Login node group (`login`)

This is a **static node group**: a single long-running instance you SSH into (or access via Session Manager) to submit jobs.

- Navigate back to "Compute node groups" and click "Create".
- Under "Compute node group details":
    - **Compute node group name**: `login`.
- Under "Compute configuration":
    - **EC2 launch template**: `login-<stack-name>` from [step 7](#7-create-node-launch-templates).
    - **Version**: select the latest version of the launch template.
    - **IAM instance profile**: select the "Use an existing profile" radio, then under **Selected profile** choose the same `AWSPCS-*` role used for `compute-1`.
    - **Subnets**: `PublicSubnetA` from [step 1](#1-create-vpc-and-subnets).
    - **Instance types**: `g4dn.4xlarge` (for `arm64` clusters, see the "Recommended instance types" tip above).
    - **Scaling configuration**: select the "Static node group" radio. Set both **Minimum instance count** and **Maximum instance count** to `1`.
    - **AMI ID**: select the "Custom AMI" radio and paste the same ParaTools Pro for E4S™ AMI ID used for `compute-1`.
- Leave "Capacity purchase option", "Scheduler configuration", and "Tags" at their defaults.
- Click "Create compute node group".

!!! tip "Wait for Active status"
    Wait for the `login` group to reach "Active" before attempting to connect in [step 10](#10-connect-to-login-node). The login instance needs several minutes after activation for cloud-init and slurm configuration to complete.

### 9. Create queue

A queue exposes a compute node group to Slurm as a partition. Jobs submitted with `sbatch -p <queue-name>` will land on the attached compute node group.

Before creating the queue, ensure the `compute-1` group from [step 8.1](#81-compute-node-group-compute-1) has reached "Active" status.

In the [AWS PCS console](https://console.aws.amazon.com/pcs/home#/clusters), select the cluster created in [step 3](#3-create-pcs-cluster), navigate to "Queues", and click "Create queue".

- Under "Queue configuration":
    - **Queue name**: `compute-1` (this becomes the Slurm partition name).
    - **Compute node groups**: select `compute-1` from [step 8.1](#81-compute-node-group-compute-1).
- Click "Create queue" and wait for the "Status" field to show "Active".

### 10. Connect to login node

Once the `login` compute node group has reached "Active", locate its EC2 instance and connect.

1. **Find the login instance.**
    - In the [AWS PCS console](https://console.aws.amazon.com/pcs/home#/clusters), select the cluster from [step 3](#3-create-pcs-cluster).
    - Go to "Compute node groups" and select the `login` group from [step 8.2](#82-login-node-group-login).
    - Copy the "Compute node group ID" (e.g., `cng-abc123def456...`).
2. **Locate the instance in EC2.**
    - In the [EC2 Console], choose "Instances".
    - In the "Find instances by attribute or tag (case sensitive)" search bar, filter by the PCS tag:

        ```text
        tag:aws:pcs:compute-node-group-id = <compute-node-group-id>
        ```

        There should be exactly one running instance matching the login group's ID.
    - Select the instance and copy its "Public IPv4 address".

3. **Connect.** Use either SSH or AWS Systems Manager Session Manager.

    === "SSH"

        Use the key pair specified in [step 7](#7-create-node-launch-templates). For the ParaTools Pro for E4S™ Ubuntu-based AMIs, the default user is `ubuntu`:

        ```bash
        ssh -i <path-to-key.pem> ubuntu@<public-ipv4-address>
        ```

    === "Session Manager"

        - In the EC2 console, select the instance and click "Connect".
        - Choose the "Session Manager" tab and click "Connect".
        - An interactive browser-based terminal opens as user `ssm-user`.
        - Switch to the default user to pick up the cluster environment:

            ```bash
            sudo -i -u ubuntu
            ```

!!! warning "Allow time for cluster bootstrap"
    Wait about 2 minutes after the login node reaches "Active" before connecting, so cloud-init can finish.

#### DCV remote desktop (optional)

The ParaTools Pro for E4S™ AMI ships with [NICE DCV][dcv] configured to serve a GPU-accelerated Linux desktop on TCP `8443`. The DCV license is granted to the node via the IAM policy from [step 5](#5-create-an-instance-profile), and inbound access is allowed by the DCV security group from [step 2](#2-create-security-groups).

1. **Open the DCV URL.** Browse to the login node's public IPv4 (located via the same steps used to SSH in above):

    ```text
    https://<login-public-ipv4>:8443/
    ```

    The browser warns about a self-signed certificate; accept to continue.

    !!! tip "Shortcut: grab the URL from the MOTD"
        The login node's cloud-init installs a MOTD drop-in that prints the fully-resolved DCV URL on every SSH / Session Manager login, e.g.:

        ```text
        DCV remote desktop: https://54.81.250.30:8443/  (user: ubuntu)
        ```

        Copy-paste that URL into your browser instead of hunting for the instance IP in the EC2 console.

2. **Sign in.**
    - **Username:** `ubuntu`.
    - **Password:** the value supplied for `DcvUbuntuPassword` when creating the launch-template stack in [step 7](#7-create-node-launch-templates).

    If `DcvUbuntuPassword` was left blank, set a password on the login node before connecting:

    ```bash
    sudo passwd ubuntu
    ```

!!! tip "Rotate or set the password later"
    `DcvUbuntuPassword` is only consumed once during cloud-init on first boot. To change the password later (or to set one when the parameter was left blank), SSH into the login node and run `sudo passwd ubuntu`.

### 11. Verify the Slurm environment

Once connected to the login node, confirm Slurm can see the queue and partition you created:

```bash
sinfo
```

`sinfo` lists the Slurm partitions, their node states, and the compute node groups backing them. You should see the queue from [step 9](#9-create-queue) listed as a partition in the `idle~` state (the `~` suffix indicates dynamically-provisioned nodes that are currently powered down).

Compute nodes are automatically terminated after a period of inactivity governed by the `ScaledownIdletime` parameter. This can be configured in [step 3](#3-create-pcs-cluster) during cluster creation by adjusting the "Slurm configuration" settings.

### 12. Run sample jobs from ParaTools E4S Cloud Examples

The ParaTools Pro for E4S™ AMI ships with a set of MPI/HPC example programs pre-copied into your home directory at `~/examples`.

??? question "Examples missing from `~/examples`?"
    If `~/examples` is empty or missing, first check `/opt/demo` -- the source copies live there and may not have been propagated to your home directory:

    ```bash
    ls /opt/demo
    cp -R /opt/demo ~/examples
    ```

    If neither exists (for instance, on a fresh EFS mount that masked the AMI's `/home` contents), clone the [ParaTools E4S Cloud Examples][e4s-cloud-examples] repository directly from GitHub:

    ```bash
    git clone https://github.com/ParaToolsInc/e4s-cloud-examples.git ~/examples
    ```

Move into the examples directory:

```bash
cd ~/examples
```

!!! note "NVIDIA NeMo™ and BioNeMo™ live in a dedicated Python environment"
    NeMo and BioNeMo are installed in a separate virtual environment to avoid dependency conflicts with other GPU/ML packages. Activate it before running NeMo or BioNeMo workloads (or `source` it from your sbatch script):

    ```bash
    source /usr/local/py-env/nemo/bin/activate
    ```

    Other Python packages (including vLLM) are available in the default system Python and require no activation.

#### 12.1 Run the `mpi-procname` example

`mpi-procname` is a tiny MPI program that prints the rank and hostname of each process. It is a quick sanity check that MPI launches and that EFA is reachable between nodes.

```bash
cd ~/examples/mpi-procname
./clean.sh
./compile.sh
sbatch -p compute-1 mpiprocname.sbatch
```

Because compute nodes in this partition are provisioned on demand, the first `sbatch` submission will trigger an EC2 launch. Expect a few minutes of delay before the job starts; subsequent jobs on the same warm nodes will start almost immediately.

Monitor the job state with:

```bash
squeue
```

`squeue` lists the pending and running jobs. While nodes are being provisioned, the state column shows `CF` (configuring); once the nodes are up, it transitions to `R` (running), and the job disappears from the list when it completes. For node-level detail, run `sinfo -N -l`.

Once the job completes, the output file (e.g., `slurm-<jobid>.out`) will contain one line per MPI rank, showing rank/host placement.

#### 12.2 Run the OSU Micro-Benchmarks

The [OSU Micro-Benchmarks](https://mvapich.cse.ohio-state.edu/benchmarks/) measure point-to-point MPI performance over EFA. The `latency`, `bw` (bandwidth), and `bibw` (bi-directional bandwidth) benchmarks are pre-built in the image and driven by the sbatch scripts in `osu-benchmarks/`:

```bash
cd ~/examples/osu-benchmarks
./clean.sh
sbatch -p compute-1 latency.sbatch
sbatch -p compute-1 bw.sbatch
sbatch -p compute-1 bibw.sbatch
```

Since the compute nodes were warmed up by the `mpi-procname` run, these three jobs should start back-to-back without further provisioning delay. Track them with `squeue` as before.

Each job writes to its own log file (`osu-latency.log`, `osu-bw.log`, `osu-bibw.log`) in the current directory.

### 13. Shut nodes down

To stop incurring EC2 charges, tear down the queue and node groups. The cluster, VPC, and CloudFormation stacks can be kept around for future use.

In the [AWS PCS console](https://console.aws.amazon.com/pcs/home#/clusters), select the cluster created in [step 3](#3-create-pcs-cluster) and, in order:

1. Delete the queue created in [step 9](#9-create-queue) ("Queues" → select queue → "Delete").
2. Delete the `login` node group from [step 8.2](#82-login-node-group-login) ("Compute node groups" → select group → "Delete").
3. Delete the `compute-1` node group from [step 8.1](#81-compute-node-group-compute-1) ("Compute node groups" → select group → "Delete").

!!! tip "Deletion order matters"
    The queue must be deleted before its attached compute node group, otherwise the node group delete will fail.

[1]: https://console.aws.amazon.com/cloudformation/
[4]: https://docs.aws.amazon.com/parallelcluster/latest/ug/setting-up.html#create-an-admin
[5]: https://docs.aws.amazon.com/parallelcluster/latest/ug/setting-up.html
[step 1]: #1-create-vpc-and-subnets
[IAM Console]: https://console.aws.amazon.com/iam
[EC2 Console]: https://console.aws.amazon.com/ec2
[e4s-cloud-examples]: https://github.com/ParaToolsInc/e4s-cloud-examples
[dcv]: https://aws.amazon.com/hpc/dcv/
