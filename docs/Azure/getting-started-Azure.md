# ParaTools Pro for E4S™ Getting Started with Microsoft Azure

## General Background Information

In this tutorial we will show you how to launch an HPC cluster on Microsoft Azure. You will use Azure CycleCloud to configure a cluster which use the ParaTools Pro for E4S™ software stack. It will then launch a head-node that can spawn Azure instances that are linked with InfiniBand networking capabilities.
  
## Tutorial

### Configure CycleCloud

As a prerequisite to this tutorial, you must first have a running CycleCloud server and the ability to log into CycleCloud as an administrator. If you do not already have such a CycleCloud install, first [create one by following Microsoft's official CycleCloud tutorial][1]. Complete the CycleCloud tutorial including all of the section titled "Exercise - Install and configure Azure CycleCloud" and Task 1 of the section titled "Exercise - Create an HPC cluster from built-in templates". The below instructions replace Tasks 2 and 3 of the official CycleCloud tutorial.

### Accept terms of the ParaTools Pro for E4S™ image and allow programmatic access
First, enable the use of the **ParaTools Pro for E4S™: AI/ML & HPC Tools on CycleCloud (AMD64)** image on Microsoft Azure. To do this:
- Go to the [Azure Portal][2] at https://portal.azure.com/.
- In the "Search resources, services, and docs" text field in the top center of the page, enter "ParaTools" to list ParaTools images.
- Select the entry "ParaTools Pro for E4S™: AI/ML & HPC Tools on CycleCloud (AMD64)" from the list.
- On the Marketplace page for the image, click the link titled "Want to deploy programmatically? Get started"
- Next to each Subscription in which you wish to deploy ParaTools Pro for E4S™, change the Status to "Enable".
- Click "Save"

### Configure a CycleCloud Cluster using a ParaTools Pro for E4S™ image
- Open the administrative interface of your CycleCloud server in a web browser and log in as an administrator.
- If the "Create a New Cluster" page is not already shown, click the "+" icon.
- In the "Create a New Cluster" page, select "Slurm".
- In the "About" tab, enter a name for your cluster and click "Next".
- In the "Required Settings" section, change the "HPC VM Type" to a node type which supports InfiniBand networking, such as `Standard_HB120-16rs_v3`.
- In the "Required Settings" section, set the "Max HPC Cores" to the number of cores you wish to make available in the cluster.
- In the "Required Settings" section, set "Subnet ID" to the subnet you created in Task 1 of the "Exercise - Create an HPC cluster from built-in templates" section of the official CycleCloud tutorial.
- Click "Advanced Settings".
- Under advanced settings, click "Custom image" under both "Scheduler OS" and "HPC OS".
- For both "Custom image" fields, enter the identifier of the custom image: `paratools-inc:pt-pro-4-e4s-msa-cyclecloud-amd64:paratools-pro-cyclecloud-amd64:latest`
- Click "Save"

### Launch the cluster
- If not already open, open the administrative interface of your CycleCloud server in a web browser and log in as an administrator.
- If not already selected, select the Cluster created in the previous section.
- Click "Start" in the Cluster details page. When asked "Are you sure you want to start the selected cluster(s)?", click "OK".
- Wait approximately 10 minutes for the cluster to start. When cluster startup is complete, the message "Node scheduler has started" will appear in the log on the right of the page and the scheduler will show a green status.
- In the Nodes list, click "scheduler". In the detail view below, the scheduler node should show a status of "Ready":
- The detail view will show an IP address for the scheduler node. 
- SSH into that node with the username `cc-admin` and the SSH key you configured when setting up the account in the official CycleCloud tutorial.

You will now be able to schedule jobs using Slurm.

[1]: https://learn.microsoft.com/en-us/training/modules/azure-cyclecloud-high-performance-computing/
[2]: https://portal.azure.com/