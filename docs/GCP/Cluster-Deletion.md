---
title: Proper Cluster Deletion on GCP
description: Correctly destroy GCP clusters created with gcluster (Cluster Toolkit) to avoid lingering resources and charges
canonical_url: https://docs.paratoolspro.com/GCP/Cluster-Deletion/
image: assets/images/gcluster/e4s_desktop_thumb.jpg
twitter_card: summary_large_image
---

# Proper Cluster Deletion on GCP

## Proper Deletion

When you are done using the cluster, you must use `gcluster` to destroy it.
When a cluster is created, `gcluster` provisions infrastructure (networks,
subnets, NAT gateways, IP addresses, Filestore instances, Slurm controller
and login VMs, and related resources). If any of these are deleted
out-of-band, some will remain and you will continue to be charged for
them. To delete your cluster correctly, run the following from the same
directory you ran `gcluster create` from:

``` bash
./gcluster destroy DEPLOYMENT_NAME/
```

where `DEPLOYMENT_NAME` is the value of `vars.deployment_name:` from your
blueprint (in the example tutorial: `ppro-e4s-25-11-cluster`).

## Improper Deletion

### Case 1: Compute Instances Deleted, Deployment Folder Remains

When the compute instances are deleted but the deployment folder still
exists, you can run the command `./gcluster destroy DEPLOYMENT_NAME/` and
it should properly remove all remaining created resources. You should
also run `rm -rf DEPLOYMENT_NAME/` to remove the deployment folder.

### Case 2: Deployment Folder Conflicts with a New Create

When the deployment folder has not been deleted, and you attempt to
create the cluster again, you may get the error:

```
  Error: Failed to overwrite existing deployment.

        Use the -w command line argument to enable overwrite.
        If overwrite is already enabled then this may be because you are attempting to remove a deployment group, which is not supported.
    original error: the directory already exists: DEPLOYMENT_NAME
```

In this case, either remove the folder as described above, or pass the
`-w` flag to `gcluster create` to overwrite the existing deployment
folder with the new contents.

### Case 3: Orphaned Infrastructure

If you are getting errors like the one below, `gcluster` is unable to
recreate a cluster because of leftover resources from a prior deployment
that was not cleanly destroyed:

```
Error: Error creating Address: googleapi: Error 409: The resource 'projects/YOUR-PROJECT/regions/us-central1/addresses/DEPLOYMENT_NAME' already exists, alreadyExists

with module.network.module.nat_ip_addresses["us-central1"].google_compute_address.ip[1],
on .terraform/modules/network.nat_ip_addresses/main.tf line 50, in resource "google_compute_address" "ip":
  50: resource "google_compute_address" "ip" {
```

You must manually delete the leftover resources before `gcluster` can
recreate them. The most common categories are:

- **Cloud NAT external IP addresses** -- shown directly in the error above.
  Find them under **VPC network** → **IP addresses** (or
  `gcloud compute addresses list`) and release them.
- **Filestore instances** (the home filesystem). Find them under
  **Filestore** → **Instances**. Confirm by creation date and name that
  the instance belongs to the cluster you are deleting, since other
  clusters may share the Filestore namespace.
- **VPC network resources**, including the VPC network, subnetworks, Cloud
  Router, NAT gateway, and peering. These often must be deleted in a
  specific order: NAT gateway first, then subnetwork, then VPC network
  peering, then Cloud Router, then VPC, and finally release the IP
  addresses. If a resource will not delete because it is "in use by
  another," find and delete the resource holding it first.

After all stray resources are removed, run
`./gcluster create -w DEPLOYMENT_NAME/` (or re-run `gcluster create`
against the original blueprint), and then
`./gcluster deploy DEPLOYMENT_NAME/`. If new "already exists" errors
appear, repeat the cleanup above.

!!! info "Legacy clusters: Slurm GCP v5 project-metadata cleanup"
    The procedure below applies **only** to clusters originally deployed with the
    Slurm GCP **v5** generation of the toolkit (`schedmd-slurm-gcp-v5-*` modules) -- back
    when the toolkit was named `ghpc` / "HPC Toolkit." Slurm GCP **v6** (used by the
    current ParaTools Pro for E4S™ blueprint) eliminated project-level metadata for
    cluster configuration, so v6 deployments will not produce the
    `*-ghpc_startup_sh` key collisions described below. Keep this section as a fallback
    for cleaning up older v5 deployments left behind by previous releases.

    If you see errors like
    ```
    Error: key "DEPLOYMENT_NAME-slurm-compute-script-ghpc_startup_sh" already present in metadata for project "YOUR-PROJECT". Use `terraform import` to manage it with Terraform

     with module.slurm_controller.module.slurm_controller_instance.google_compute_project_metadata_item.compute_startup_scripts["ghpc_startup_sh"],
      on .terraform/modules/slurm_controller.slurm_controller_instance/terraform/slurm_cluster/modules/slurm_controller_instance/main.tf line 281, in resource "google_compute_project_metadata_item" "compute_startup_scripts":
     281: resource "google_compute_project_metadata_item" "compute_startup_scripts" {
    ```
    you must manually delete each of the listed keys with `gcloud compute
    project-info remove-metadata`. See [`gcloud compute project-info`][gcloud-pi] for
    reference. Inspect current metadata with
    ```
    gcloud compute project-info describe --project=YOUR-PROJECT
    ```
    Remove keys one at a time:
    ```
    gcloud compute project-info remove-metadata \
        --keys="DEPLOYMENT_NAME-slurm-controller-script-ghpc_startup_sh" \
        --project=YOUR-PROJECT
    ```
    Or, if you have many keys to remove, batch them in a single call (replace each entry
    with the actual key name from your error output):
    ```
    gcloud compute project-info remove-metadata \
        --keys="DEPLOYMENT_NAME-slurm-compute-script-ghpc_startup_sh","DEPLOYMENT_NAME-slurm-controller-script-ghpc_startup_sh","DEPLOYMENT_NAME-slurm-tpl-slurmdbd-conf","DEPLOYMENT_NAME-slurm-tpl-cgroup-conf","DEPLOYMENT_NAME-slurm-tpl-slurm-conf","DEPLOYMENT_NAME-slurm-partition-compute-script-ghpc_startup_sh" \
        --project=YOUR-PROJECT
    ```

    !!! danger
        Project metadata is shared across all of your project's resources. Removing keys
        you do not recognize may break unrelated workloads. Only remove keys that are
        clearly named after the deleted v5 deployment.

[gcloud-pi]: https://cloud.google.com/sdk/gcloud/reference/compute/project-info
