# ParaTools Pro for E4S™ Getting Started with AWS Parallel Computing Service

## General Background Information

In this tutorial we will show you how to set up and launch an HPC cluster using AWS Parallel Computing Service (PCS).
You will use the command line tools, [AWS CLI](https://aws.amazon.com/cli/), and AWS console to create a cluster.
This will use a number of `.yaml` files that describe the stack and are inputs for AWS CloudFormation.
We will then launch a GPU-accelerated head node that can spawn EC2 compute node instances linked with EFA networking capabilities.

For the purposes of this tutorial, we make the following assumptions:

- You have created an [AWS account][5], and an are [Administrative User][4].

## Tutorial

Please reference the official [AWS PCS Getting Started](https://docs.aws.amazon.com/pcs/latest/userguide/getting-started.html) guide for more information.
This tutorial follows the official tutorial linked above, with a few minor changes.
If something is unclear, please check the official tutorial.

### 1. Create VPC and Subnets

??? tip "You can skip this step by reusing previously created resources"
    If you have already created the VPC and subnets, you can reuse them, and skip this step. Use this [link](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks?filteringText=PTPro&filteringStatus=active&viewNested=true) to search for VPC stacks in us-east-1 that contain the text "PTPro".

To create a new stack for the cluster's VPC and Subnets [using the CloudFormation console][1], please use the following template:

[`0-pcs-cluster-cloudformation-vpc-and-subnets.yaml`](../assets/aws/pcs/0-pcs-cluster-cloudformation-vpc-and-subnets.yaml)

??? note "Show template contents (click to expand)"

    ```yaml
    --8<-- "assets/aws/pcs/0-pcs-cluster-cloudformation-vpc-and-subnets.yaml"
    ```

Use the default options and give the stack a name, like `AWSPCS-PTPro-cluster`.
You can leave the options as the defaults.

!!! tip "Use this AWS Cloud Formation [quick-create link](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/quickcreate?templateURL=https%3A%2F%2Fs3.us-east-1.amazonaws.com%2Fcf-templates-behdg14v2lp8-us-east-1%2F2025-12-18T124707.749Zt1m-0-pcs-cluster-cloudformation-vpc-and-subnets.yaml&stackName=AWSPCS-PTPro-cluster&param_CidrPublicSubnetA=10.3.0.0%2F20&param_ProvisionSubnetsC=False&param_CidrBlock=10.3.0.0%2F16&param_CidrPrivateSubnetB=10.3.144.0%2F20&param_CidrPrivateSubnetC=10.3.160.0%2F20&param_CidrPublicSubnetC=10.3.32.0%2F20&param_CidrPublicSubnetB=10.3.16.0%2F20&param_CidrPrivateSubnetA=10.3.128.0%2F20) to quickly provision these resources with default settings."

Under Capabilities: Check the box for I acknowledge that AWS CloudFormation might create IAM resources.

Once you have created this new VPC, find its VPC ID and note it by searching for it in the [Amazon VPC Console](https://console.aws.amazon.com/vpc) by selecting "VPCs" and then searching for the name you picked above.
If you chose the stack name we suggested, you would search for `PTPro`, and if you are deploying this in `us-east-1` you can use this [link](https://us-east-1.console.aws.amazon.com/vpcconsole/home?region=us-east-1#vpcs:search=PTPro).
Make a note of the VPC ID once you have found it.

### 2. Create Security Groups

???+ summary
    In this section we will create three security groups:

    - A cluster security group enabling comms between the compute nodes, login node and AWS PCS controller
    - An inbound ssh group that can optionally be enabled to allow ssh logins on the login node
    - An DCV group that can optionally be enabled to allow DCV remote desktop connections to the login node

!!! tip "If you have already created these security groups you can reuse them and skip this step."

Using [CloudFormation][1], create a new stack for the security groups using the following template:

[`1-pcs-cluster-cloudformation-security-groups.yaml`](../assets/aws/pcs/1-pcs-cluster-cloudformation-security-groups.yaml)

??? note "Show template contents (click to expand)"

    ```yaml
    --8<-- "assets/aws/pcs/1-pcs-cluster-cloudformation-security-groups.yaml"
    ```

- Under stack name use something like `AWSPCS-PTPro-sg`.
- Select the VPC ID noted in [step 1].
- Enable ssh, and optionally enable DCV access.

??? warning "Use a Quick create link"

    You can use this AWS CloudFormation [quick-create link](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/quickcreate?templateURL=https%3A%2F%2Fs3.us-east-1.amazonaws.com%2Fcf-templates-behdg14v2lp8-us-east-1%2F2025-12-18T134612.678Zi9c-1-pcs-cluster-cloudformation-security-groups.yaml&stackName=AWSPCS-PTPro-sg&param_CreateInboundDcvSecurityGroup=True&param_VpcId=vpc-0c6a46e761800dead&param_CreateInboundSshSecurityGroup=True&param_ClientIpCidr=0.0.0.0%2F0) to provision these security groups in `us-east-1`, however, __*you must ensure that you change the VPC ID*__ to the one created in [step 1].

### 3. Create PCS Cluster

!!! tip "If you have already created a cluster in this manner you can skip this step"

Go to the [AWS PCS console](https://console.aws.amazon.com/pcs/home#/clusters) and create a new cluster.

- Under Cluster setup, choose a name like `AWSPCS-PTPro-cluster`
- Set the controller size to small.
- Use the version of slurm compatible with the ParaTools Pro for E4S(TM) image. This is usually the latest version available, 25.05 as of december 2025.
- Under Networking:
    - use the VPC ID created in [step 1]. (e.g., `AWSPCS-PTPro-cluster...`)
    - Use the subnet labeled as PrivateSubnetA created in [step 1].
    - Under "Security groups" choose "Select an existing security group"
        - Use the security group `cluster-*-sg` created in [step 2](#2-create-security-groups) (e.g., `cluster-AWSPCS-PTPro-sg`)
- Click "Create Cluster" to begin creating the cluster.

### 4. Create shared filesystem using EFS

- Go to [EFS console](https://console.aws.amazon.com/efs) and create a new filesystem.
- Ensure it is in the same region as the PCS cluster you are setting up.
- Create a file system
    - For the name choose something like `AWSPCS-PTPro-fs`.
    - Under "Virtual Private Cloud", use the VPC ID created in [step 1](#1-create-vpc-and-subnets).
    - Click "Create File System"
    - Note the FS ID.

### 5. Create an Instance Profile

Go to the [IAM console]. Under Access Management -> Policies
Check if a policy matching this one already exists, try searching for pcs.
If no such policy exists, then create a new one and specify the permissions using the JSON editor as the following:

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

Name the new policy, something like `AWS-PCS-polilcy` and note the name that you chose.

???+ note "Additional optional steps to enable DCV remote desktop access"

    If you plan to access the login node you will need to create an adaditional policy to access the DCV license server.
    If a matching policy exists you can reuse it, try searching for DCV to check.
    If no policy exists, then create a new one, specifying the permissions with the JSON editor as follows:

    ``` json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "s3:GetObject",
                "Resource": "arn:aws:s3:::dcv-license.region/us-*"
            }
        ]
    }
    ```

    Give it a name like `EC2AccessDCVLicenseS3`.

Next, in the [IAM Console] to to Access Management -> Roles check if a role starting with `AWS_PCS-` exists with the following policies attached.
If not follow these instructions to create it.

- Select "Create Role"
- Select Trusted Entity Type: "AWS Service"
- Service or use case: "EC2"
- Use Case: "EC2"
- Click Next
- Add permissions
    - Add the policy created earlier in [step 5](#5-create-an-instance-profile).
    - If planning to use DCV to access the login node, also add the `EC2AccessDCVLicenseS3` policy.
    - Add the `AmazonSSMManagedInstanceCore` policy.
- Click Next
- Give the role a name that starts with `AWSPCS-` (It must start with `AWSPCS-`)

### 6. Create EFA Placement Group

!!! note "If such a placement group already exists you may simply reuse it."

Under the [EC2 Console], navigate to Network & Security -> Placement Groups -> "Create placement group"

- Name it something like `AWSPCS-PTPro-cluster`
- Set strategy = "cluster"
- Click "Create group"

### 7. Create node Launch Template

[Using CloudFormation][1], create a new stack for the node launch templates using the following template:

[`2-pcs-cluster-cloudformation-launch-templates.yaml`](../assets/aws/pcs/2-pcs-cluster-cloudformation-launch-templates.yaml)

??? note "Show template contents (click to expand)"

    ```yaml
    --8<-- "assets/aws/pcs/2-pcs-cluster-cloudformation-launch-templates.yaml"
    ```

Set the following values:

- VpcDefaultSecurityGroupId = value of "default" security group obtained in [step 1](#1-create-vpc-and-subnets)
- ClusterSecurityGroupId = get value from output of [step 2](#2-create-security-groups) key = "ClusterSecurityGroupId"
- SshSecurityGroupId = get value from output of [step 2](#2-create-security-groups) key = "InboundSshSecurityGroupId"
- SshKeyName = pick a key
- VpcId = get value from output of [step 1](#1-create-vpc-and-subnets) key = "VPC"
- PlacementGroupName = use name chosen in [step 6](#6-create-efa-placement-group)
- NodeGroupSubnetId = select the subnet labeled with PrivateSubnetA created in [step 1](#1-create-vpc-and-subnets)
- EfsFilesystemId = EFS ID of FS created in [step 4](#4-create-shared-filesystem-using-efs)

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

[1]: https://console.aws.amazon.com/cloudformation/
[4]: https://docs.aws.amazon.com/parallelcluster/latest/ug/setting-up.html#create-an-admin
[5]: https://docs.aws.amazon.com/parallelcluster/latest/ug/setting-up.html
[step 1]: #1-create-vpc-and-subnets
[IAM Console]: https://console.aws.amazon.com/iam
[EC2 Console]: https://console.aws.amazon.com/ec2
