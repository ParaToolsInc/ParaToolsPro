---
title: Getting Started with AWS ParallelCluster
description: Step-by-step guide to deploy E4S HPC clusters on AWS ParallelCluster
canonical_url: https://docs.paratoolspro.com/AWS/getting-started-AWS/
image: assets/images/gcluster/e4s_desktop_thumb.jpg
twitter_card: summary_large_image
---

# ParaTools Pro for E4S™ Getting Started with AWS ParallelCluster

!!! info "Looking for AWS Parallel Computing Service (PCS)?"
    This guide covers **AWS ParallelCluster (PC)**, the open-source self-managed orchestrator. For the managed-service alternative, see [Getting Started with AWS Parallel Computing Service (PCS)](getting-started-AWS-PCS.md).

## General Background Information

This tutorial configures AWS ParallelCluster (PC) with the matching **ParaTools Pro for E4S™ on ParallelCluster** AMI from the AWS Marketplace:

| Architecture | AWS Marketplace product |
|---|---|
| `x86_64` | [ParaTools Pro for E4S™ on ParallelCluster (x86)](https://aws.amazon.com/marketplace/pp/prodview-xprkx44kyqgp6) |
| `arm64` (Graviton) | [ParaTools Pro for E4S™ on ParallelCluster (arm64)](https://aws.amazon.com/marketplace/pp/prodview-ozpychswxmldi) |

You will use the command line tools, AWS CLI, and AWS ParallelCluster to create a `.yaml` file that describes your head node and the cluster nodes. It will then launch a head node that can spawn EC2 instances linked with EFA networking capabilities.

This tutorial assumes that you have already created an [AWS account][5] and an [Administrative User][4].

## Tutorial

### Install [AWS ParallelCluster][1]

To install ParallelCluster, upgrade `pip` and install `virtualenv` if it is not already installed. Amazon recommends installing ParallelCluster in a virtual environment. This section follows ["Setting Up AWS ParallelCluster"][1]; refer to it if you run into issues.

``` bash linenums="1"
python3 -m pip install --upgrade pip
python3 -m pip install --user --upgrade virtualenv
```

Then create and source the virtual environment:

```
python3 -m virtualenv ~/apc-ve
source ~/apc-ve/bin/activate
```

Install ParallelCluster. If the version of ParallelCluster does not match the version used to generate the AMI, the cluster creation operation will fail. At the time of writing, ParaTools Pro for E4S™ AMIs are built with ParallelCluster 3.10.0. Check the version string of your selected ParaTools Pro for E4S™ AMI, visible on the AWS Marketplace listing, for the associated ParallelCluster version.

```
python3 -m pip install --upgrade "aws-parallelcluster"==3.10.0
```

ParallelCluster requires Node.js for CloudFormation. Install it with:

```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
chmod ug+x ~/.nvm/nvm.sh
source ~/.nvm/nvm.sh
nvm install --lts
node --version
```

### Install [AWS Command Line Interface][3]

Install the AWS CLI, which handles authentication every time you create a cluster. This section follows ["Installing AWS CLI"][9]; refer to it if you run into issues.

```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

If you do not have `sudo` privileges, specify install and binary locations with the `-i` and `-b` flags:

```
./aws/install -i ~/.local/aws-cli -b ~/.local/bin
```

### AWS Security Credentials and CLI Configuration

This section follows [Creating Access Keys][11] and [Configuring AWS CLI][10]; refer to them if you run into issues.

If you do not already have an access key, create one. From the **IAM** page, select **Users** on the left, choose the user to grant access credentials to, open the **Security credentials** tab, and scroll down to **Create access key**. Create a key for **CLI** activities, and store it securely.

Configure the AWS CLI with those credentials:

```
aws configure
```

Enter the requested information:

```
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [us-east-1]: us-west-2
Default output format [None]: json
```

### AWS EC2 Key Pair

Cluster tasks such as running jobs, monitoring jobs, and managing users require access to the cluster head node. Access over SSH requires an EC2 key pair. If none exists in the target region, follow [this guide][12] to create one.

### [AWS user policies][6]

To create and manage clusters in an AWS account, AWS ParallelCluster requires permissions at two levels:

* Permissions that the `pcluster` user requires to invoke the `pcluster` CLI commands for creating and managing clusters.
* Permissions that the cluster resources require to perform cluster actions.

The policies described here are supersets of the required permissions; trim them down as needed. To create the policies, open the **IAM** page, select **Policies** on the left, click **Create Policy**, and select the **JSON** editor. Copy and paste the policy found [here][7]. Unless AWS Secrets Manager is in use, remove the final section from the JSON:
```
      {
          "Action": "secretsmanager:DescribeSecret",
          "Resource": "arn:aws:secretsmanager:<REGION>:<AWS ACCOUNT ID>:secret:<SECRET NAME>",
          "Effect": "Allow"
      }
```
If the editor reports errors, replace `<AWS ACCOUNT ID>` with your 12-digit account ID.

Create the policy and name it `ClusterPolicy1`. Create another policy using this [JSON][8], naming it `ClusterPolicy2` and replacing the account ID placeholder as before. From the policies menu, open **ClusterPolicy1**, click **Entities attached**, and attach the users who will create clusters. Repeat for `ClusterPolicy2`. In the policies list, find `AmazonVPCFullAccess` and attach it to the same users. This allows them to create VPCs when needed.

### Find the AMI

Prepare the AMI (Amazon Machine Image) for the next step. Open the [ParaTools Pro for E4S™ marketplace listing][13] for the image you want, click **Subscribe**, click **Continue to Configuration**, select the correct region, and copy the AMI ID that is displayed.

![AMIPNG](https://github.com/ParaToolsInc/ParaToolsPro/assets/81718016/2904fc9f-a07c-4570-89d0-1d5c5f87dfe5)

### Cluster configuration and creation

Cluster creation prompts for the following:

- **Region**: the region in which to launch the cluster.
- **EC2 key pair**: the key pair you created earlier, or one you intend to use to access the nodes.
- **Scheduler**: select **slurm**.
- **OS**: **Ubuntu 22.04**.
- **Head node instance type**: the head node only manages the compute fleet, so it does not require much compute capacity. A `t3.large` is usually sufficient. The head node does **not** need to be EFA-capable.
- **Queue structure**: select as required by your use case.
- **Compute instance types**: select an EFA-capable instance. To list EFA-capable instance types:

  ```
  aws ec2 describe-instance-types --filters "Name=processor-info.supported-architecture,Values=x86_64*" "Name=network-info.efa-supported,Values=true" --query InstanceTypes[].InstanceType
  ```

  To list EFA-capable instances that also have GPU support:

  ```
  aws ec2 describe-instance-types --filters "Name=processor-info.supported-architecture,Values=x86_64" "Name=network-info.efa-supported,Values=true" --query 'InstanceTypes[?GpuInfo.Gpus!=null].InstanceType'
  ```

- **Network settings**: select as required for your workflow, or accept the defaults.
- **Automatic VPC**: unless you already have a VPC to reuse, select yes. Note that AWS imposes per-account VPC limits, so unused VPCs should be deleted periodically.

Create the `cluster-config.yaml` file:

```
pcluster configure --config cluster-config.yaml
```

```
INFO: Configuration file cluster-config.yaml will be written.
Press CTRL-C to interrupt the procedure.

Allowed values for AWS Region ID:
1. ap-northeast-1
2. ap-northeast-2
...
15. us-west-1
16. us-west-2
AWS Region ID [us-west-2]:
Allowed values for EC2 Key Pair Name:
1. Your-EC2-key

EC2 Key Pair Name [Your-EC2-key]: 1
Allowed values for Scheduler:
1. slurm
2. awsbatch
Scheduler [slurm]: 1
Allowed values for Operating System:
1. alinux2
2. centos7
3. ubuntu2004
4. ubuntu2204
Operating System [ubuntu2204]:
Head node instance type [t3.large]:
Number of queues [1]:
Name of queue 1 [queue1]:
Number of compute resources for queue1 [1]:
Compute instance type for compute resource 1 in queue1 [t3.micro]: t3.micro
Maximum instance count [10]:
Automate VPC creation? (y/n) [n]: y
Allowed values for Availability Zone:
1. us-west-2a
2. us-west-2b
3. us-west-2c
Availability Zone [us-west-2a]: 1
Allowed values for Network Configuration:
1. Head node in a public subnet and compute fleet in a private subnet
2. Head node and compute fleet in the same public subnet
Network Configuration [Head node in a public subnet and compute fleet in a private subnet]:
Beginning VPC creation. Please do not leave the terminal until the creation is finalized
Creating CloudFormation stack...
Do not leave the terminal until the process has finished.
```

If the command reports an authorization failure, one of the policies was likely misconfigured. Verify that all three policies were created correctly.

### Final Cluster Configurations

Open `cluster-config.yaml` and add `CustomAmi: <ParaTools-Pro-ami-id>` under the `Image` section, replacing `<ParaTools-Pro-ami-id>` with the AMI ID obtained in the prior section:

```
Image:
      Os: ubuntu2204
      CustomAmi: <ParaTools-Pro-ami-id>
```

To enable RDP/DCV access to the head node, add the following `Dcv` block:

```
HeadNode:
  Dcv:
    Enabled: true
```

### Spinning up the cluster head node

Once configuration is complete, launch the cluster:

```
pcluster create-cluster -c cluster.yaml -n name_of_cluster
```

The command returns JSON similar to:

```
{
  "cluster": {
    "clusterName": "name_of_cluster",
    "cloudformationStackStatus": "CREATE_IN_PROGRESS",
    "cloudformationStackArn": "arn:aws:cloudformation:us-west-2:123456789100:stack/name_of_cluster",
    "region": "us-west-2",
    "version": "3.5.1",
    "clusterStatus": "CREATE_IN_PROGRESS",
    "scheduler": {
      "type": "slurm"
    }
  },
  "validationMessages": [
    {
      "level": "WARNING",
      "type": "CustomAmiTagValidator",
      "message": "The custom AMI may not have been created by pcluster. You can ignore this warning if the AMI is shared or copied from another pcluster AMI. If the AMI is indeed not created by pcluster, cluster creation will fail. If the cluster creation fails, please go to https://docs.aws.amazon.com/parallelcluster/latest/ug/troubleshooting.html#troubleshooting-stack-creation-failures for troubleshooting."
    },
    {
      "level": "WARNING",
      "type": "AmiOsCompatibleValidator",
      "message": "Could not check node AMI ami-12345678910 OS and cluster OS ubuntu2204 compatibility, please make sure they are compatible before cluster creation and update operations."
    }
  ]
}
```

Cluster creation takes a few minutes. Monitor progress with `pcluster list-clusters`. If creation fails, a common cause is a ParallelCluster version mismatch between the CLI and the AMI. Verify that the installed version matches the AMI.

### Accessing your cluster

Once the cluster finishes launching, open the **EC2** page and select **Instances**. Select the newly created instance labeled **Head Node**. Click **Connect** in the upper right and choose your connection method. For SSH, the default username is typically `ubuntu`; if it is not, connect with a standard SSH client and the server will report the expected username.

Alternatively, connect from your local terminal with:

```
pcluster ssh -i /path/to/key/file -n name_of_cluster
```

From the head node, you can submit jobs using Slurm.

### Running Examples

The head node contains an `examples` directory with tests and example workloads. For NVIDIA NeMo™, see `examples/nemo/ex2/text_classification/ex2.sbatch`.

!!! note "NVIDIA NeMo™ and BioNeMo™ live in a dedicated Python environment"
    NeMo and BioNeMo are installed in a separate virtual environment to avoid dependency conflicts with other GPU/ML packages. Activate it before running NeMo or BioNeMo workloads (or `source` it from your sbatch script):

    ```bash
    source /usr/local/py-env/nemo/bin/activate
    ```

    Other Python packages (including vLLM) are available in the default system Python and require no activation.

[1]: https://docs.aws.amazon.com/parallelcluster/latest/ug/install-v3.html
[2]: https://aws.amazon.com/hpc/parallelcluster/
[3]: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
[4]: https://docs.aws.amazon.com/parallelcluster/latest/ug/setting-up.html#create-an-admin
[5]: https://docs.aws.amazon.com/parallelcluster/latest/ug/setting-up.html
[6]: https://docs.aws.amazon.com/parallelcluster/latest/ug/iam-roles-in-parallelcluster-v3.html
[7]: https://docs.aws.amazon.com/parallelcluster/latest/ug/iam-roles-in-parallelcluster-v3.html#iam-roles-in-parallelcluster-v3-base-user-policy
[8]: https://docs.aws.amazon.com/parallelcluster/latest/ug/iam-roles-in-parallelcluster-v3.html#iam-roles-in-parallelcluster-v3-privileged-iam-access
[9]: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
[10]: https://docs.aws.amazon.com/parallelcluster/latest/ug/install-v3-configuring.html
[11]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey
[12]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/get-set-up-for-amazon-ec2.html#create-a-key-pair
[13]: https://aws.amazon.com/marketplace/search/results?searchTerms=ParaTools+Pro&CREATOR=4790cdfc-e838-4372-a130-05ed1b70b62d&filters=CREATOR
