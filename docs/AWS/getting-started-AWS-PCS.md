# ParaTools Pro for E4S™ Getting Started with AWS Parallel Computing Service

## General Background Information

In this tutorial we will show you how to launch an HPC cluster on AWS. You will use the command line tools, AWS CLI, and AWS Parallel Computing Service (PCS) to create a cluster. This will use a number of .yaml files that describe the stack and AWS Cloud Formation. We will then launch a GPU accelerated head-node that can spawn EC2 compute node instances that are linked with EFA networking capabilities.

For the purposes of this tutorial, we make the following assumptions:

- You have created an [AWS account][5], and an [Administrative User][4]

## Tutorial

Please reference the official [AWS PCS Getting Started](https://docs.aws.amazon.com/pcs/latest/userguide/getting-started.html) guide for more information.

### 1. Create VPC and Subnets

Using CloudFormation, create a new stack for the VPC and Subnets using the following template:

- 0-pcs-cluster-cloudformation-vpc-and-subnets.yaml

Use the default options and give the stack a name.

### 2. Create Security Groups

Using CloudFormation, create a new stack for the security groups using the following template:

- 1-pcs-cluster-cloudformation-security-groups.yaml

Use the VPC shown in Outputs section of stack created in [step 1](#1-create-vpc-and-subnets)

### 3. Create PCS Cluster

Go to the PCS console and create a new cluster.

- Under Cluster setup, choose a name and set the controller size to small.
- Under Networking:
  - use the VPC ID created in [step 1](#1-create-vpc-and-subnets)
  - Use the subnet labeled as PrivateSubnetA created in [step 1](#1-create-vpc-and-subnets)
  - Use the security group `cluster-*-sg` created in [step 2](#2-create-security-groups)

### 4. Create shared filesystem using EFS

Go to EFS console and create a new filesystem using the VPC created in [step 1](#1-create-vpc-and-subnets). Note the FS ID.

### 5. Create an Instance Profile

Go to IAM console. Under Access Management -> Policies, create a new policy and specify the permissions using the JSON editor as the following:

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

Note the name of the new policy.

Next, under IAM Console -> Access Management -> Roles, create a new role.

- Select Trusted Entity Type = AWS Service
- Service or use case = EC2
- Use Case = EC2
- Click Next
- Add permissions
  - Add the policy created earlier in [step 5](#5-create-an-instance-profile).
  - add AmazonSSMManagedInstanceCore
- Click Next
- Give the role a name that starts with `AWSPCS-` (It must start with `AWSPCS-`)

### 6. Create EFA Placement Group

Under EC2 Console -> Network & Security -> Placement Groups -> "Create placement group"

- Set strategy = "cluster"

### 7. Create node Launch Template

Using CloudFormation, create a new stack for the node launch templates using the following template:

- 2-pcs-cluster-cloudformation-launch-templates.yaml

Set the following values:

- VpcDefaultSecurityGroupId = value of "default" security group obtained in [step 1](#1-create-vpc-and-subnets)
- ClusterSecurityGroupId = get value from output of [step 2](#2-create-security-groups) key = "ClusterSecurityGroupId"
- SshSecurityGroupId = get value from output of [step 2](#2-create-security-groups) key = "InboundSshSecurityGroupId"
- SshKeyName = pick a key
- NumberOfNetworkCards = 1
- VpcId = get value from output of [step 1](#1-create-vpc-and-subnets) key = "VPC"
- PlacementGroupName = use name chosen in [step 6](#6-create-efa-placement-group)
- NodeGroupSubnetId = select the subnet labeled with PrivateSubnetA created in [step 1](#1-create-vpc-and-subnets)
- EfsFilesystemId = EFS ID of FS created in [step 4](#4-create-shared-filesystem-using-efs)

[quick create link](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/quickcreate?templateURL=https%3A%2F%2Fs3.us-east-1.amazonaws.com%2Fcf-templates-behdg14v2lp8-us-east-1%2F2025-12-02T162137.854Zrw0-2-pcs-cluster-cloudformation-launch-templates.yaml&stackName=PPro-PCS-launch-template&param_SshKeyName=Zaak-e4s-for-clouds&param_NodeGroupSubnetId=subnet-0ad8b185bf2442f8a&param_FSxLustreFilesystemMountName=&param_PlacementGroupName=PPro-PCS-EFA-placement-group&param_VpcId=vpc-011d7692cc7337ce2&param_SshSecurityGroupId=sg-056df816a182fd17b&param_VpcDefaultSecurityGroupId=sg-00e2bae45c867ce07&param_ClusterSecurityGroupId=sg-0ab58303be1f0f7fd&param_FSxLustreFilesystemId=&param_EfsFilesystemId=fs-06e054d9e1aba4819&param_NumberOfNetworkCards=1)

### 8. Create node groups

In the PCS console, select the cluster created in [step 3](#3-create-pcs-cluster)

1. Create one node group for compute nodes
   - Compute node groups -> Create compute node group
   - Group name = compute-1
   - EC2 Launch Template = `compute-<name>` where `<name>` is the stack name chosen in [step 7](#7-create-node-launch-template)
   - Subnets = PrivateSubnetA from [step 1](#1-create-vpc-and-subnets)
   - Instance types = g4dn.8xlarge (or other EFA-capable instance type)
   - min count = 0, max count = 2
   - AMI ID = Select a PCS-compatible AMI
2. Create one node group for the login node
   - Compute node groups -> Create compute node group
   - Group name = login
   - EC2 Launch Template = `login-<name>` where `<name>` is the stack name chosen in [step 7](#7-create-node-launch-template)
   - Subnets = PublicSubnetA from [step 1](#1-create-vpc-and-subnets)
   - Instance types = g4dn.4xlarge (or other instance type)
   - min count = 1, max count = 1
   - AMI ID = Select a PCS-compatible AMI

### 9. Create queue

In the PCS console, select the cluster created in [step 3](#3-create-pcs-cluster)

- Queues -> Create queue
  - name = compute-1
  - Add the compute node group created in [step 8.1](#8-create-node-groups)

### 10. Connect to login node

In the PCS console, select the cluster created in [step 3](#3-create-pcs-cluster)

- Compute node groups -> select login node group created in [step 8.2](#8-create-node-groups)
  - Copy the "compute node group ID"
- Go to EC2 console -> Instances
  - In the search bar "Find instances by attribute or tag (case sensitive)" search for the "compute node group ID"
  - Select the resulting instance -- this is the login node
  - Copy "Public IPv4 Address"
  - SSH to that IP (should allow the login node to prepare itself for at least 5 minutes before SSHing)
    - username = "ubuntu" (for our ubuntu-based images; username will vary depending on image type)
    - ssh key = use the key chosen in [step 7](#7-create-node-launch-template)

### 11. Run sample job

Once connected to the login node, run `sinfo` to see slurm queue information.
You should see the queue created in [step 9](#9-create-queue)
Submit a job: `sbatch -p <queue-name> script.sbatch`
Since compute nodes are launched on demand, the first job submitted to a queue will cause the nodes to be spun up.

- `squeue` will show the job state as `CF` while the nodes are provisioned

Compute nodes will be brought down automatically after a period of inactivity called `ScaledownIdletime`

- This can be configured in [step 3](#3-create-pcs-cluster) during cluster creation by changing the "Slurm configuration" settings.

### 12. Shut nodes down

In the PCS console, select the cluster created in [step 3](#3-create-pcs-cluster)

1. Delete the queue by going to "Queues" and deleting the queue created in [step 9](#9-create-queue)
2. Delete the login node group by gong to "Compute node groups" and deleting the node group created in [step 8.2](#8-create-node-groups)
3. Delete the compute node group by going to "Compute node groups" and deleting the node group created in [step 8.1](#8-create-node-groups)

[4]: https://docs.aws.amazon.com/parallelcluster/latest/ug/setting-up.html#create-an-admin
[5]: https://docs.aws.amazon.com/parallelcluster/latest/ug/setting-up.html
