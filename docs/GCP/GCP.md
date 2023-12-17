# GCP Getting Started

## General Background Information

In the following tutorial, we roughly follow the same steps as the
["quickstart tutorial"][1] from the [Google HPC-Toolkit][2] project.
For the purposes of this tutorial, we make the following assumptions:

- You have [created a Google Cloud account][3].
- You have [created a Google Cloud project][4] appropriate for this tutorial
  and it is [selected][15].
- You have [setup billing for your Google Cloud Project][5].
- You have [enabled the Compute Engine API][6].
- You have [enabled the Filestore API][7].
- You have [enabled the Cloud Storage API][8]
- You have [enabled the Sevice Usage API][9].
- You have [enabled the Secret Manager API][10].
- You are aware of [the costs for running instances on GCP Compute Engine][11] and
  of the costs of using the E4S Pro GCP marketplace VM image. <!-- FIXME: these need links when marketplace goes live -->
- You are comfortable using the [GCP Cloud Shell][12], or are running locally
    (which will match this tutorial) and are familiar with SSH, a terminal and have
    [installed][13] and [initialized the gcloud CLI][14]

[1]: https://cloud.google.com/hpc-toolkit/docs/quickstarts/slurm-cluster
[2]: https://github.com/GoogleCloudPlatform/hpc-toolkit?tab=readme-ov-file#quickstart
[3]: https://console.cloud.google.com/freetrial
[4]: https://cloud.google.com/resource-manager/docs/creating-managing-projects
[5]: https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#console
[6]: https://console.cloud.google.com/apis/api/compute.googleapis.com/overview
[7]: https://console.cloud.google.com/apis/api/file.googleapis.com/overview
[8]: https://console.cloud.google.com/apis/api/storage.googleapis.com/overview
[9]: https://console.cloud.google.com/apis/api/serviceusage.googleapis.com/overview
[10]: https://console.cloud.google.com/apis/api/secretmanager.googleapis.com/overview
[11]: https://cloud.google.com/hpc-toolkit/docs/quickstarts/slurm-cluster#costs
[12]: https://cloud.google.com/hpc-toolkit/docs/quickstarts/slurm-cluster#launch
[13]: https://cloud.google.com/sdk/docs/install
[14]: https://cloud.google.com/sdk/docs/initializing
[15]: https://console.cloud.google.com/projectselector2/home/dashboard

## Tutorial

### Getting Set Up

First, let's grab your `PROJECT_ID` and `PROJECT_NUMBER`.
Navigate to the [GCP project selector][15] and select the project that you'll be using for this tutorial.
Take note of the `PROJECT_ID` and `PROJECT_NUMBER`
Open your local shell or the [GCP Cloud Shell][12], and run the following commands:
``` bash linenums="1"
export PROJECT_ID=<enter your project ID here>
export PROJECT_NUMBER=<enter your project number here>
```

Next, nsure that the default Compute Engine service account is enabled:
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

Clone the [Google Cloud HPC-Toolkit][2] and change directories to the cloned repository:
``` bash linenums="1"
git clone https://github.com/GoogleCloudPlatform/hpc-toolkit.git
cd hpc-toolkit/
```
Next build the HPC-Toolkit and verify the version and that it built correctly.
``` bash
make
./ghpc --version
```

### Deploy the Cluster
