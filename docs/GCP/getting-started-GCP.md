---
title: Getting Started with Google Cluster Toolkit (GCP)
description: Guide for deploying E4S on Google Cloud using the Cluster Toolkit
canonical_url: https://docs.paratoolspro.com/GCP/getting-started-GCP/
image: assets/images/gcluster/e4s_desktop_thumb.jpg
twitter_card: summary_large_image
---

# ParaTools Pro for E4S™ Getting Started with Google Cloud Platform (GCP)

## General Background Information

This tutorial roughly follows the same steps as the
["Deploy an HPC cluster with Slurm" quickstart][1] from the [Cluster Toolkit][2] project.
This tutorial assumes the following:

- You have [created a Google Cloud account][3].
- You have [created a Google Cloud project][4] appropriate for this tutorial,
  and it is [selected][15].
- You have [set up billing for your Google Cloud project][5].
- You have [enabled the Compute Engine API][6].
- You have [enabled the Filestore API][7].
- You have [enabled the Cloud Storage API][8].
- You have [enabled the Service Usage API][9].
- You have [enabled the Cloud Resource Manager API][10].
- You are aware of [the costs for running instances on GCP Compute Engine][11], and
  of the costs of using the ParaTools Pro for E4S™ GCP marketplace VM image.
- You are comfortable using the [GCP Cloud Shell][12], or are running locally
    (which will match this tutorial), are familiar with SSH and a terminal, and
    have [installed][13] and [initialized the gcloud CLI][14].

[1]: https://docs.cloud.google.com/cluster-toolkit/docs/quickstarts/slurm-cluster
[2]: https://github.com/GoogleCloudPlatform/cluster-toolkit?tab=readme-ov-file#quickstart
[3]: https://console.cloud.google.com/freetrial
[4]: https://cloud.google.com/resource-manager/docs/creating-managing-projects
[5]: https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#console
[6]: https://console.cloud.google.com/apis/api/compute.googleapis.com/overview
[7]: https://console.cloud.google.com/apis/api/file.googleapis.com/overview
[8]: https://console.cloud.google.com/apis/api/storage.googleapis.com/overview
[9]: https://console.cloud.google.com/apis/api/serviceusage.googleapis.com/overview
[10]: https://console.cloud.google.com/apis/api/cloudresourcemanager.googleapis.com/overview
[11]: https://docs.cloud.google.com/cluster-toolkit/docs/quickstarts/slurm-cluster#costs
[12]: https://docs.cloud.google.com/cluster-toolkit/docs/quickstarts/slurm-cluster#launch
[13]: https://cloud.google.com/sdk/docs/install
[14]: https://cloud.google.com/sdk/docs/initializing
[15]: https://console.cloud.google.com/projectselector2/home/dashboard

## Tutorial

### Getting Set Up

First, capture your `PROJECT_ID` and `PROJECT_NUMBER`.
Navigate to the [GCP project selector][15] and select the project for this tutorial.
Take note of the `PROJECT_ID` and `PROJECT_NUMBER`.
Open your local shell or the [GCP Cloud Shell][12], and run the following commands:
``` bash
export PROJECT_ID=<enter your project ID here>
export PROJECT_NUMBER=<enter your project number here>
```

Set a default project you will be using for this tutorial.
If you have multiple projects, you can switch back to a different one when you are finished.

``` bash
gcloud config set project "${PROJECT_ID}"
```

Next, ensure that the default Compute Engine service account is enabled:
``` bash
gcloud iam service-accounts enable \
     --project="${PROJECT_ID}" \
     ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com
```
and grant the service account the IAM roles required by Cluster Toolkit
(`roles/compute.instanceAdmin.v1` for managing Compute Engine resources, and
`roles/iam.serviceAccountUser` to act as the service account):

``` bash
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
    --role=roles/compute.instanceAdmin.v1
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
    --role=roles/iam.serviceAccountUser
```

!!! note "Minimum required IAM roles"
    Older tutorials grant `roles/editor` to this service account. That role is
    project-wide and far broader than required. The two roles above are the
    minimum recommended by the upstream
    [Cluster Toolkit setup guide][prereqs].

### Install the [Cluster Toolkit][2]

!!! tip "Pre-built binary bundle (alternative)"
    Since Cluster Toolkit v1.82.0, Google publishes pre-built `gcluster` bundles on the
    [Releases page][releases]. Download the bundle matching your OS and architecture
    (e.g., `gcluster_bundle_linux_amd64.zip`, `gcluster_bundle_mac_arm64.zip`), unzip it,
    and skip the build-from-source steps below. The bundle includes the `gcluster` binary
    plus the `examples/` and `community/examples/` directories. The build-from-source
    instructions below are still supported and required on Windows hosts.

[releases]: https://github.com/GoogleCloudPlatform/cluster-toolkit/releases

First install the dependencies of `gcluster`. Instructions to do this are included below.
If you encounter trouble please check the latest instructions from Google,
available [here][prereqs]. If you are running the GCP Cloud Shell, you do not need to install the dependencies and can skip ahead to cloning the Cluster Toolkit.

[prereqs]: https://docs.cloud.google.com/cluster-toolkit/docs/setup/configure-environment

!!! info "Install the [Cluster Toolkit][2] Prerequisites"
    Please download and install any missing software packages from the following list:

    - [Terraform] version 1.12.2 or later (note: Terraform 1.6 and later are licensed under the BUSL)
    - [Packer] version 1.10.0 or later
    - [Go] version 1.23 or later. Ensure that the `GOPATH` is set up and `go` is on your `PATH`.
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

    !!! note "Use your OS package manager"
        Most of the packages above may be installable through your OS's package manager.
        For example, if you have [Homebrew] on macOS you should be able to `brew install <package_name>`
        for most of these items, where `<package_name>` is, e.g., `go`.

[Terraform]: https://www.terraform.io/downloads
[Packer]: https://www.packer.io/downloads
[Go]: https://go.dev/doc/install
[Git]: https://github.com/git-guides/install-git
[Homebrew]: https://brew.sh

Once all the software listed above has been verified or installed, clone the [Cluster Toolkit][2]
and change directories to the cloned repository:
``` bash
git clone https://github.com/GoogleCloudPlatform/cluster-toolkit.git
cd cluster-toolkit/
```
Next, build the Cluster Toolkit, then verify the version and confirm that it built correctly.
``` bash
make
./gcluster --version
```
To install the compiled binary on your `$PATH`, run:

``` bash
sudo make install
```

This installs the `gcluster` binary into `/usr/local/bin`. If you do not have
root privileges or do not want to install the binary into a system-wide
location, run:

``` bash
make install-user
```

This installs `gcluster` into `${HOME}/bin`; then ensure that directory is
on your `PATH`:

``` bash
export PATH="${PATH}:${HOME}/bin"
```

### Grant ADC Access to Terraform

Generate cloud credentials associated with your Google Cloud account and grant
Terraform access to the Application Default Credential (ADC).

!!! note "Cloud Shell users skip this step"
    If you are using the [Cloud Shell][12] you can skip this step.

``` bash
gcloud auth application-default login
```

!!! info "OS Login is already enabled by default"
    The Slurm GCP v6 modules used by the example blueprint
    (`schedmd-slurm-gcp-v6-controller`, `schedmd-slurm-gcp-v6-login`, and
    `schedmd-slurm-gcp-v6-nodeset`) all enable [OS Login][oslogin] **at the
    instance level by default**, so you do not need to enable it at the
    project level for the cluster's VMs to accept SSH from your Google
    identity. Skip the `gcloud compute project-info add-metadata --metadata
    enable-oslogin=TRUE` step you may have seen in older tutorials.

    If you have a non-default scenario where you actively want to **disable**
    OS Login on a specific role (for example, to use legacy project-wide SSH
    keys on the login node), set `enable_oslogin: false` in that module's
    `settings:` block in your blueprint -- do not change project-level
    metadata.

    !!! warning "Heidi conflict"
        Do not enable OS Login at the **project** level on a project that also
        runs ParaTools Pro Heidi (the Adaptive Computing-orchestrated
        marketplace product). Heidi relies on instance-metadata-injected SSH
        keys for cluster-internal authentication, and project-level OS Login
        breaks that injection. The default behavior of the v6 modules
        (instance-level OS Login, no project-level change) is safe to mix
        with Heidi in the same project.

Your **user identity** still needs the right IAM roles for SSH to succeed.
At minimum, grant yourself:

- `roles/compute.osLogin` (or `roles/compute.osAdminLogin` if you need
  `sudo`) so the VMs accept your Google identity as a Linux user.
- `roles/iap.tunnelResourceAccessor` so the GCP Console "SSH" button (which
  tunnels through [Identity-Aware Proxy][iap]) can reach the login node.

``` bash
USER_EMAIL=$(gcloud config get-value account)
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="user:${USER_EMAIL}" --role=roles/compute.osLogin
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="user:${USER_EMAIL}" --role=roles/iap.tunnelResourceAccessor
```

[oslogin]: https://cloud.google.com/compute/docs/oslogin
[iap]: https://cloud.google.com/iap

### Deploy the Cluster

Copy the [ParaTools-Pro-slurm-cluster-blueprint-example][blueprint] from the
ParaTools Pro for E4S™ documentation to your clipboard, then paste it into a file
named `e4s-25.11-cluster-slurm-gcp-v6.yaml`. After copying the text, in your
terminal do the following:

``` bash
cat > e4s-25.11-cluster-slurm-gcp-v6.yaml
# paste the copied text # (1)!
# press Ctrl-d to add an end-of-file character
cat e4s-25.11-cluster-slurm-gcp-v6.yaml # check that the file copied correctly # (2)!
```

1. Usually `Ctrl-v`, or `Command-v` on macOS.
2. Optional, but recommended.

Using your favorite editor, select appropriate instance types for the compute
partitions. If you do not have access to H3 instances, remove the `h3_nodeset`
and `h3_partition` modules from the blueprint, **and** remove the `- h3_partition`
entry from the `slurm_controller.use:` list (otherwise `gcluster create` will
fail with an unresolved-reference error). See the expandable annotations and
pay extra attention to the highlighted lines on the
[ParaTools-Pro-slurm-cluster-blueprint-example][blueprint] example.

!!! tip "Pay Attention"
    In particular:

    - Determine whether to pass the `${PROJECT_ID}` on the command line, or set
      `vars.project_id:` directly in the blueprint.
    - Verify that the `image_family` key matches the image for ParaTools Pro
      for E4S™ from the GCP marketplace.
    - Adjust the region and zone used, if desired.
    - Set an appropriate `machine_type` and `node_count_dynamic_max` for each
      `*_nodeset` (`debug_nodeset`, `compute_nodeset`, and `h3_nodeset`).
    - The default `network` module provides IAP SSH only (which is what the
      GCP Console "SSH" button uses). To SSH directly from your workstation,
      see [Allowing direct SSH from your workstation][workstation-ssh] in the
      blueprint reference.

Once the blueprint is configured to be consistent with your GCP usage quotas
and your preferences, set deployment variables and create the deployment
folder.

!!! info "Create deployment folder"

    ``` bash
    ./gcluster create e4s-25.11-cluster-slurm-gcp-v6.yaml \
      --vars project_id=${PROJECT_ID} # (1)!
    ```

    1.  If you uncommented and updated `vars.project_id:` in the blueprint,
        you do not need to pass `--vars project_id=...` on the command line.
        If you are bringing a cluster back online that was previously deleted,
        but the blueprint has been modified and the deployment folder is
        still present, pass the `-w` flag to `gcluster create` to overwrite
        the deployment folder contents with the latest changes.

`gcluster create` produces a deployment folder named after the blueprint's
`vars.deployment_name:` field -- in this example,
`./ppro-e4s-25-11-cluster/`. The next step references that folder.

??? note inline end "Provisioning time"
    It may take a few minutes to finish provisioning your cluster.

Now the cluster can be deployed. Run the following command to deploy your
ParaTools Pro for E4S™ cluster:

!!! info "Perform the deployment"

    ``` bash
    ./gcluster deploy ppro-e4s-25-11-cluster
    ```

Review the proposed changes, then press `a` to accept.

### Connect to the Cluster

Once the cluster is deployed, SSH to the login node.

1. Go to the "Compute Engine" → "VM Instances" page.

    [GCP VM Instances](https://console.cloud.google.com/compute/instances){ .md-button .md-button--primary }

2. Click "SSH" for the login node of the cluster. You may need to approve Google authentication before the session can connect.

!!! note "SSH permission errors"
    If clicking "SSH" in the Console produces a permission error, confirm
    that your user identity holds the IAM roles listed in the OS Login
    admonition under [Grant ADC Access to Terraform](#grant-adc-access-to-terraform)
    (`roles/compute.osLogin` and `roles/iap.tunnelResourceAccessor`).

[blueprint]: ./blueprint.md#paratools-pro-for-e4stm-slurm-cluster-blueprint-example
[workstation-ssh]: ./blueprint.md#allowing-direct-ssh-from-your-workstation

### Delete the Cluster

When you are done using the cluster, you must use `gcluster` to destroy it.
If your instances were deleted in a different manner, see
[Proper Cluster Deletion on GCP](./Cluster-Deletion.md). To delete your cluster
correctly, run:

``` bash
./gcluster destroy ppro-e4s-25-11-cluster
```

Review the proposed changes, then press `a` to accept and proceed with the
deletion.
