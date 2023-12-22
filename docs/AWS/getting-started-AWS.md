# E4S Pro Getting Started with Amazon Web Services (AWS)

## General Background Information

In this tutorial we will show you how to launch an HPC cluster on AWS. You will use the command line tools, AWS CLI, and AWS ParallelCluster to create a .yaml file that describes your head-node, and the cluster-nodes. It will then launch a head-node that can spawn EC2 instances that are linked with EFA networking capabilities.

Up until step X. we essentially follow, with some extra clairifcation, ["Setting Up AWS ParallelCluster"][1]. For the purposes of this tutorial, we make the following assumptions:
- You have created an [AWS account][5], and an [Administrative User][4]
  
## Tutorial

### Install [AWS ParallelCluster][1]
To install Pcluster, upgrade pip, and install virtualenv if not installed. Note amazon recommends installing pcluster in a virtual environment.

``` bash linenums="1"
python3 -m pip install --upgrade pip
python3 -m pip install --user --upgrade virtualenv
```

Then create and source the virtual environment:
```
python3 -m virtualenv ~/apc-ve
source ~/apc-ve/bin/activate
```

Then install ParallelCluster
```
python3 -m pip install --upgrade "aws-parallelcluster"
```

ParallelCluster needs node.js for CloudFormation, so
```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
chmod ug+x ~/.nvm/nvm.sh
source ~/.nvm/nvm.sh
nvm install --lts
node --version
```

### Install [AWS Command Line Interface][3]
Now we must install AWS CLI, which will handle authenticating your information every time you create a cluster.
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
Note, if you do not have sudo user rights, you must select the install and bin, with the flags `-i` and `-b`, as shown below
```
./aws/install -i ~.local/aws-cli -b ~/.local/bin
```

### AWS Security Credentials and CLI Configuration 
If you do not already have a secure access key, you must create one. From the **IAM** page, on the left side of the page select **User**s, then select the **user** you would like to grant access credentials to, then select the **Security credentials**, and scroll down to **Create access key**. Create a key for **CLI** activities. Make sure to save these very securely.

Now we can configure AWS with the security credentials.
```
aws configure
```
And then enter the respective information,
```
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [us-east-1]: us-west-2
Default output format [None]: json
```
### AWS EC2 Key Pair

### [AWS user policies][6]
To create and manage clusters in an AWS account, AWS ParallelCluster requires permissions at two levels:
* Permissions that the pcluster user requires to invoke the pcluster CLI commands for creating and managing clusters.
* Permissions that the cluster resources require to perform cluster actions.  
The policies described here are supersets of the required permissions to create clusters. If you know what you are doing you can remove permissions as you feel fit. To make the policies, open the **IAM** page, select **Policies** on the left, and **Create Policy**, then select the **JSON** editor. Copy and paste the policy found [here][7]. Unless you plan to use AWS secrets, you must remove the final section from the JSON.
```
      {
          "Action": "secretsmanager:DescribeSecret",
          "Resource": "arn:aws:secretsmanager:<REGION>:<AWS ACCOUNT ID>:secret:<SECRET NAME>",
          "Effect": "Allow"
      }
```
If it reports errors, replace FILL IN HERE THE THING THAT THEY HAVE TO REPLACE
Then create and name the policy "ClusterPolicy1". Create another policy, with this [JSON][8], naming it "ClusterPolicy2", similarly replacing account id where it prompts you to. From the policies menu, find and open **ClusterPolicy1** and click **Entities attached**,  and attach the users you would like to be able to create clusters. Repeat this process for "ClusterPolicy2". Similarly, in the policies list, find the policy "AmazonVPCFullAccess" and attach the users to this. This will allow them to create VPC's if necessary. We have now granted the required permissions to users to create clusters.

### Find the ami
I don't know the right way to do this.

### Cluster configuration and creation
When creating a cluster you will be prompted for the region, EC2 key, scheduler,  OS, head node instance type, information regarding the structure of your queues, compute instance types, and network settings. Your region should be whichever region you are planning to launch these in. Your EC2 key pair should be the one you just created. For OS, select Ubuntu 22.04<Is this right?>. For head node instance type, as it only controls the nodes it does not require much compute capabilities. A t3.large will often suffice. Note the head node does not have to be EFA capable. Select the structure of your queue as relevant to your use case. For the compute instance types you **must** select an EFA capable node. You can find these out by:
```
aws ec2 describe-instance-types --filters "Name=processor-info.supported-architecture,Values=x86_64*" "Name=network-info.efa-supported,Values=true" --query InstanceTypes[].InstanceType
```
Furthermore you can find which EFA capable nodes that have GPU support by
```
aws ec2 describe-instance-types --filters "Name=processor-info.supported-architecture,Values=x86_64" "Name=network-info.efa-supported,Values=true" --query 'InstanceTypes[?GpuInfo.Gpus!=null].InstanceType'
```
For the network settings, select as required for your workflow, or follow below.


To create the cluster-config.yaml file,
```
     `pcluster configure --config cluster-config.yaml`
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
Operating System [ubuntu2004]:
Head node instance type [t2.micro]:
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

If there is an error regarding a failed authorization, there may have been an issue in setting up your policies, make sure you have created the 3 policies correctly.

### Final Cluster Configurations
Opening cluster-config.yaml, add the line `CustomAmi: <E4S-Pro-ami-id>` under the Image section. Replacing <E4S-Pro-ami-id> with the AMI you got in the prior section.
```
Image:
      Os: ubuntu2004
      CustomAmi: <E4S-Pro-ami-id>
```
Furthermore, if you want to be able to RDP/DCV into the head node, then add the "DCV enabled" section as shown:
```
HeadNode:
      Dcv:
            Enabled: true
```

### Spinning up the cluster head node
Now that all configuration is complete,
```
pcluster create -c cluster.yaml -n name_of_cluster
```
This process will should return some JSON such as
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
      "message": "Could not check node AMI ami-12345678910 OS and cluster OS ubuntu2004 compatibility, please make sure they are compatible before cluster creation and update operations."
    }
  ]
}
```
This process will take a few minutes to finish. Progress can be viewed by performing `pcluster list-clusters`
### Accessing your cluster
Once your cluster is finished launching, enter the **EC2** page, and select **Instances**. Then select the newly created node, which should be labled "Head Node". The in the upper right select **Connect** and select your method of connection. Note for ssh, the username is likely to be "ubuntu".
From there you should be able to launch jobs.




[1]: https://docs.aws.amazon.com/parallelcluster/latest/ug/install-v3.html
[2]: https://aws.amazon.com/hpc/parallelcluster/
[3]: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
[4]: https://docs.aws.amazon.com/parallelcluster/latest/ug/setting-up.html#create-an-admin
[5]: https://docs.aws.amazon.com/parallelcluster/latest/ug/setting-up.html
[6]: https://docs.aws.amazon.com/parallelcluster/latest/ug/iam-roles-in-parallelcluster-v3.html
[7]: https://docs.aws.amazon.com/parallelcluster/latest/ug/iam-roles-in-parallelcluster-v3.html#iam-roles-in-parallelcluster-v3-base-user-policy
[8]: https://docs.aws.amazon.com/parallelcluster/latest/ug/iam-roles-in-parallelcluster-v3.html#iam-roles-in-parallelcluster-v3-privileged-iam-access
