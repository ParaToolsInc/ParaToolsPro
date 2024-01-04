## Proper Deletion
It is very important that when you are done using the cluster you must use ghcp to destroy it. When a cluster is created, ghcp creates resources and adds project metadata tags, if improperly deleted, some of these will remain and you will be charged for them. To delete your cluster correctly, find the instructions in the folder created by ghpc, `CLUSTER-IMAGE/instructions.txt` and do   
```
./ghpc destroy CLUSTER-IMAGE/
```

## Improper Deletion
### Case 1
When the compute instances are deleted, but not the folder, you can run the command `./ghpc destroy CLUSTER-IMAGE/` and it should properly remove all the created resources. You should also run `rm -rf CLUSTER-IMAGE/` to remove the file.
### Case 2
When the folder hasn't been deleted, and you attempt to create the cluster again, you may get the error
```
  Error: Failed to overwrite existing deployment.
		
		Use the -w command line argument to enable overwrite.
		If overwrite is already enabled then this may be because you are attempting to remove a deployment group, which is not supported.
    original error: the directory already exists: e4s-23-11-cluster-slurm-rocky8
```
In this case remove the folder as stated above.
### Case 3
If you are getting the below errors, it indicates ghpc is unable to recreate a cluster due to leftover resources. 
```
Error: Error creating Address: googleapi: Error 409: The resource 'projects/YOUR-PROJECT/regions/us-central1/addresses/CLUSTER-IMAGE' already exists, alreadyExists
		
with module.network1.module.nat_ip_addresses["us-central1"].google_compute_address.ip[1],
on .terraform/modules/network1.nat_ip_addresses/main.tf line 50, in resource "google_compute_address" "ip":
  50: resource "google_compute_address" "ip" {
```
And also errors like 
```
Error: key "e4s2311clu-slurm-compute-script-ghpc_startup_sh" already present in metadata for project "e4s-pro". Use `terraform import` to manage it with Terraform
		
 with module.slurm_controller.module.slurm_controller_instance.google_compute_project_metadata_item.compute_startup_scripts["ghpc_startup_sh"],
  on .terraform/modules/slurm_controller.slurm_controller_instance/terraform/slurm_cluster/modules/slurm_controller_instance/main.tf line 281, in resource "google_compute_project_metadata_item" "compute_startup_scripts":
 281: resource "google_compute_project_metadata_item" "compute_startup_scripts" {
```
You must now go through the process of manually deleting each of the keys that are listed in the error list.  As shown [here](https://cloud.google.com/sdk/gcloud/reference/compute/project-info/describe), we will use `gcloud compute project-info describe` to see the cloud metadata, and `gcloud compute project-info remove-metadata --keys="the key" --project=YOUR-PROJECT`. You can either run this command once using a list, such as 
```
gcloud compute project-info remove-metadata --keys==["CLUSTER-IMAGEclu-slurm-compute-script-ghpc_startup_sh","CLUSTER-IMAGEclu-slurm-controller-script-ghpc_startup_sh", … ]
```
where you put in each relevant key. Be very careful in this process that you only delete the relevant keys as this metadata info can affect all of you projects.  
Or you can also do it one at a time,
```
gcloud compute project-info remove-metadata --keys="CLUSTER-IMAgE-clu-slurm-controller-script-ghpc_startup_sh" for each  key listed in the error message.
```	
In my case the command looked like:
```
gcloud compute project-info remove-metadata --keys=["e4s2311clu-slurm-compute-script-ghpc_startup_sh","e4s2311clu-slurm-controller-script-ghpc_startup_sh","e4s2311clu-slurm-tpl-slurmdbd-conf","e4s2311clu-slurm-tpl-cgroup-conf","e4s2311clu-slurm-tpl-slurm-conf","e4s2311clu-slurm-partition-compute-script-ghpc_startup_sh","e4s2311clu-slurm-compute-script-ghpc_startup_sh","e4s2311clu-slurm-controller-script-ghpc_startup_sh","e4s2311clu-slurm-tpl-slurmdbd-conf","e4s2311clu-slurm-tpl-cgroup-conf"]
```
Furthermore, the networking, and filestore resources will still be active, so those must be deleted. By searching filestore you should the instances page, in my case it looks like this 
![image](https://github.com/ParaToolsInc/E4S-Pro/assets/81718016/21e434a9-00a6-4018-8cb8-70c0df068e8f)
I know that this is the filestore created by the instance I improperly deleted. In your case you must be 100% sure, because if you delete the wrong one you will delete data for other clusters. Be sure to check the creation date and delete.
![image](https://github.com/ParaToolsInc/E4S-Pro/assets/81718016/6305427b-8740-4de6-a8b9-f767f3ad4684)
By searching in your project you should be able to find the network resource page, 
![image](https://github.com/ParaToolsInc/E4S-Pro/assets/81718016/c9c3ab74-1052-4767-94c7-3224f862720d)
You must delete all resources that are listed in the `Error 409: The resource 'projects/YOUR-PROJECT/regions/us-central1/addresses/CLUSTER-IMAGE' already exists` errors. For network resources they often have to be deleted in a specfic order. It is likely that you should delete the NAT gateway, then the subnetwork, and then the VPC network peering, router, and then VPC, then release the IP address. If you can't delete a resource, it is in use by another. Find and delete the prerequisite resources first, then delete it.
Now you should run `./ghpc create CLUSTER-IMAGE/` If any stray resources still exist, delete them as shown above and rerun these two commands.



