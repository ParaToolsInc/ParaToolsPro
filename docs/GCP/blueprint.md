# SLURM Scheduler Cluster Blueprint for GCP

## General Info
Below is an example [Google HPC-Toolkit][2] bluiprint for using ParaTools Pro for E4S™.
Once you have access to ParaTools Pro for E4S™ through the GCP marketplace, we recommend
following the
["quickstart tutorial"][1] from the [Google HPC-Toolkit][2] project to get
started if you are new to GCP and/or HPC-Toolkit.
The ParaTools Pro for E4S™ blueprint provided below can be copied with some small modifications
and used for the tutorial or in production.

Areas of the blueprint that require your attention and that may need to be
changed are highlighted and have expandable annotations offering further
guidance.

## ParaTools Pro for E4S™ Slurm Cluster Blueprint Example
``` yaml title="e4s-23.11-cluster-slurm-gcp-5-9-hpc-rocky-linux-8.yaml" linenums="1" hl_lines="4 6 20 34 35 56-75"
--8<-- "./examples/GCP/e4s-23.11-cluster-slurm-gcp-5-9-hpc-rocky-linux-8.yaml"
```

--8<-- "./examples/GCP/e4s-23.11-cluster-slurm-gcp-5-9-hpc-rocky-linux-8.annotations.md"

[1]: https://cloud.google.com/hpc-toolkit/docs/quickstarts/slurm-cluster
[2]: https://github.com/GoogleCloudPlatform/hpc-toolkit?tab=readme-ov-file#quickstart
