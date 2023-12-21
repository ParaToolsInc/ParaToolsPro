# E4S Pro Getting Started with Amazon Web Services (AWS)

## General Background Information

In this tutorial we will show you how to launch an HPC cluster on AWS. You will use the command line tools, AWS CLI, and AWS ParallelCluster to create a .yaml file that describes your head-node, and the cluster-nodes. It will then launch a head-node that can spawn EC2 instances that are linked with EFA networking capabilities.

Up until step X. we essentially follow, with some extra clairifcation, ["Setting Up AWS ParallelCluster"][1]. For the purposes of this tutorial, we make the following assumptions:
- You have created an [AWS account][5], and [Administrative User][4]

## Tutorial

### Install [AWS ParallelCLuster][1]
To install Pcluster, upgrade pip, and install virtualenv if not installed. Note amazon rcommends installing pcluster in a virtual environment.

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
Now we must install AWS CLI, which will handle authenticating your information everytime you create a cluster.
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
Note, if you do not have sudo user rights, you must select the install and bin, with the flags `-i` and `-b`.
```
./aws/install -i ~.local/aws-cli -b ~/local/bin
```

### AWS Security Credentials and CLI Configuration 
If you do not already have a secure access key, you must create one. From the **IAM** page, on the left side of the page select **User**s, then select the **user** you would like to grant access credentials to, then select the **Security credential**, and scroll down to **
$ aws configure
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [us-east-1]: us-east-1
Default output format [None]:
```





  
- You have created an [EC2 key pair]
- You have downloaded [PCluster tool]
- You have downloaded [AWS CLI]
- You have made a security credential
- You have configured AWS cli with that security credential
- You have created the 3 policies, and assigned them to anyone creating clusters
- pcluster create configure -c cluster.yaml, select trhough tree
- open and edit, add ,, mention DCV
      Specify the E4S-Pro AMI
      ```Image:
        Os: ubuntu2004
        CustomAmi: <E4S-Pro-ami-id>

pcluster create -c cluster.yaml -n name_of_cluster
You can then ssh into the cluster


- You have [enabled the Secret Manager API][10].
- You are aware of [the costs for running instances on GCP Compute Engine][11] and
  of the costs of using the E4S Pro GCP marketplace VM image. <!-- FIXME: these need links when marketplace goes live -->
- You are comfortable using the [GCP Cloud Shell][12], or are running locally
    (which will match this tutorial) and are familiar with SSH, a terminal and have
    [installed][13] and [initialized the gcloud CLI][14]

[1]: https://docs.aws.amazon.com/parallelcluster/latest/ug/install-v3.html
[2]: https://aws.amazon.com/hpc/parallelcluster/
[3]: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
[4]: https://docs.aws.amazon.com/parallelcluster/latest/ug/setting-up.html#create-an-admin
[5]: https://docs.aws.amazon.com/parallelcluster/latest/ug/setting-up.html
[6]: 
[7]:  
[8]:  
[9]:  
[10]:  
[11]:  
[12]:  
[13]:  
[14]:  
[15]: 



Now that you have AWS, and Pcluster, you must configure them with the information required to authenticate you. First on AWS console, if you do not already have an AWS Access Key, go to IAM -> Users -> "your-user-name" -> Security Credentials -> Create ccess key. CHATGPT FIX THE NEXT STUFF Making sure to treat that key very safely. 

Then in the command line,  
``` bash linenums="1"
$ aws configure
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [us-east-1]: us-east-1
Default output format [None]:
```

pcluster config -c test.yaml
select through the list
then edit the yaml,
altering the lines as stated in e4s-pro.yaml
YOu must find the ami, this required me going to launch an instance, and selecting the ami found

then once it is ready do pcluster create


First, let's grab your `PROJECT_ID` and `PROJECT_NUMBER`.
Navigate to the [GCP project selector][15] and select the project that you'll be using for this tutorial.
Take note of the `PROJECT_ID` and `PROJECT_NUMBER`
Open your local shell or the [GCP Cloud Shell][12], and run the following commands:

export PROJECT_ID=<enter your project ID here>
export PROJECT_NUMBER=<enter your project number here>
```

Set a default project you will be using for this tutorial.
If you have multiple projects you can switch back to a different one when you are finished.

``` bash
gcloud config set project "${PROJECT_ID}"
```

Next, ensure that the default Compute Engine service account is enabled:
``` bash
gcloud iam service-accounts enable \
     --project="${PROJECT_ID}" \
     ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com
```
and add the `roles/editor` IAM role to the service account:

``` bash
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
    --role=roles/editor
```

### Install the [Google Cloud HPC-Toolkit][2]

First install the dependencies of `ghpc`. Instructions to do this are included below.
If you encounter trouble please check the latest instructions from Google,
available [here]:[prereqs]. If you are running the google cloud shell you do not need to install the dependencies and can skip to cloning the hpctoolkit.

[prereqs]: https://cloud.google.com/hpc-toolkit/docs/setup/install-dependencies

!!! info "Install the [Google Cloud HPC-Toolkit][2]  Prerequisites"
    Please download and install any missing software packages from the following list:

    - [Terraform] version 1.2.0 or later
    - [Packer] version 1.7.9 or later
    - [Go] version 1.188 or later. Ensure that the `GOPATH` is setup and `go` is on your `PATH`.
      You may need to add the following to `.profile` or `.bashrc` startup "dot" file:
      ``` bash
      export PATH=$PATH:$(go env GOPATH)/bin
      ```
    - [Git]
    - `make` (see below for instructions specific to your OS)
    === "macOS"
        `make` is packaged with the Xcode command line developer tools on macOS.
        To install, run:
        ``` bash
        xcode-select --install
        ```
    === "Ubuntu/Debian"
        Install `make` with the OS' package manager:
        ``` bash
        apt-get -y install make
        ```
    === "CentOS/RHEL"
        Install `make` with the OS' package manager:
        ``` bash
        yum install -y make
        ```

    !!! Note
        Most of the packages above may be installable through your OSes package manager.
        For example, if you have [Homebrew] on macOS you should be able to `brew install <package_name>`
        for most of these items, where `<package_name>` is, e.g., `go`.

[Terraform]: https://www.terraform.io/downloads
[Packer]: https://www.packer.io/downloads
[Go]: https://go.dev/doc/install
[Git]: https://github.com/git-guides/install-git
[Homebrew]: https://brew.sh

Once all the software listed above has been verified and/or installed, clone the [Google Cloud HPC-Toolkit][2]
and change directories to the cloned repository:
``` bash linenums="1"
git clone https://github.com/GoogleCloudPlatform/hpc-toolkit.git
cd hpc-toolkit/
```
Next build the HPC-Toolkit and verify the version and that it built correctly.
``` bash
make
./ghpc --version
```
If you would like to install the compiled binary to a location on your `$PATH`,
run
``` bash
sudo make install
```
to install the `ghpc` binary into `/usr/local/bin`, of if you do not have root
priviledges or do not want to install the binary into a system wide location, run
``` bash
make install-user
```
to install `ghpc` into `${HOME}/bin` and then ensure this is on your path:

``` bash
export PATH="${PATH}:${HOME}/bin"
```

### Grant ADC access to Terraform and Enable OS Login

Generate cloud credentials associated with your Google Cloud account and grant
Terraform access to the Aplication Default Credential (ADC).

!!! note
    If you are using the [Cloud Shell][12] you can skip this step.

``` bash
gcloud auth application-default login
```

To be able to connect to VMs in the cluster OS Login must be enabled.
Unless OS Login is already enabled at the organization level, enable it at the project level.
To do this, run:

``` bash
gcloud compute project-info add-metadata \
     --metadata enable-oslogin=TRUE
```

### Deploy the Cluster

Copy the [e4s-pro-slurm-cluster-blueprint-example][blueprint] from the
E4S Pro documentation to your clipboard, then paste it into a file named
`E4S-Pro-Slurm-Cluster-Blueprint.yaml`. After copying the text, in your terminal
do the following:

``` bash
cat > E4S-Pro-Slurm-Cluster-Blueprint.yaml
# paste the copied text # (1)
# press Ctrl-d to add an end-of-file character
cat E4S-Pro-Slurm-Cluster-Blueprint.yaml # Check the file copied correctly #(2)
```

1. !!! note
       Usually `Ctrl-v`, or `Command-v` on macOS
2. !!! note
       This is optional, but usually a good idea

Using your favorite editor, select appropriate instance types for the compute partitions,
and remove the h3 partition if you do not have access to h3 instances yet.
See the expandable annotations and pay extra attention to the highlighted lines
on the [e4s-pro-slurm-cluster-blueprint-example][blueprint] example.

!!! Tip "Pay Attention"
    In particular:

    - Determine if you want to pass the `${PROJECT_ID}` on the command line or in the blueprint
    - Verify that the `image_family` key matches the image for E4S Pro from the GCP marketplace
    - Adjust the region and zone used, if desired
    - Limit the IP `ranges` to those you will be connecting from via SSH in the `ssh-login`
      `firewall_rules` rule, if in a production setting.
      If you plan to connect only from the [cloud shell][12] the `ssh-login`
      `firewall_rules` rule may be completely removed.
    - Set an appropriate `machine_type` and `dynamic_node_count_max` for your `compute_node_group`.

Once the blue print is configured to be consistent with your GCP usage quotas and your preferences,
set deployment variables and create the deployment folder.

!!! info "Create deployment folder"

    ``` bash
    ./ghpc create E4S-Pro-Slurm-Cluster-Blueprint.yaml \
      --vars project_id=${PROJECT_ID} # (1)!
    ```

    1. !!! note
           If you uncommented and updated the `vars.project_id:` you do not need to pass
           `--vars project_id=...` on the command line.
           If you're bringing a cluster back online that was previously deleted, but
           the blueprint has been modified and the deployment folder is still present,
           the `-w` flag will let you overwrite the deployment folder contents with the
           latest changes.

??? note inline end
    It may take a few minutes to finish provisioning your cluster.
At this point you will be prompted to review or accept the proposed changes.
You may review them if you like, but you should press `a` for accept once satisfied.
Now the cluster can be deployed.
Run the following command to deploy your E4S Pro cluster:

!!! info "Perform the deployment"
    ``` bash
    ./ghpc deploy e4s-23-11-cluster-slurm-rocky8
    ```

### Connect to the Cluster

Once the cluster is deployed, ssh to the login node.

1. Go to the __Compute Engine > VM Instances__ page.

    [GCP VM Instances](https://console.cloud.google.com/compute/instances){ .md-button }

2. `ssh`

[blueprint]: ./blueprint.md/#e4s-pro-slurm-cluster-blueprint-example
