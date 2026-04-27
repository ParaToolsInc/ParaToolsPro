---
title: SLURM Scheduler Cluster Blueprint for GCP
description: Example blueprint for deploying ParaTools Pro for E4S™ on GCP with HPC Toolkit
canonical_url: https://docs.paratoolspro.com/GCP/blueprint/
image: assets/images/gcluster/e4s_spack_find_thumb.jpg
twitter_card: summary_large_image
---

# SLURM Scheduler Cluster Blueprint for GCP

## General Info
Below is an example [Google Cloud Cluster Toolkit][2] blueprint for using ParaTools Pro for E4S™.
Once you have access to ParaTools Pro for E4S™ through the GCP marketplace, we recommend
following the ["Deploy an HPC cluster with Slurm" quickstart][1] from the
[Google Cloud Cluster Toolkit][2] project to get started if you are new to GCP and/or
the Cluster Toolkit.
The ParaTools Pro for E4S™ blueprint provided below can be copied with some small modifications
and used for the tutorial or in production.

Areas of the blueprint that require your attention and that may need to be
changed are highlighted and have expandable annotations offering further
guidance.

## ParaTools Pro for E4S™ Slurm Cluster Blueprint Example
``` yaml title="e4s-25.11-cluster-slurm-gcp-v6.yaml" linenums="1" hl_lines="20 25 37 49 51-54 74 75 89-110"
--8<-- "./examples/GCP/e4s-25.11-cluster-slurm-gcp-v6.yaml"
```

--8<-- "./examples/GCP/e4s-25.11-cluster-slurm-gcp-v6.annotations.md"

## Allowing direct SSH from your workstation

The default firewall rules created by [`modules/network/vpc`][vpc-module] permit SSH from
[Identity-Aware Proxy (IAP)][iap] only. The "SSH" button in the GCP Console (which uses IAP)
works without any extra configuration. If you want to SSH directly from your workstation
to the login node's public IP -- for example, to use `scp` for large file transfers, or
because you prefer a local terminal over the browser-based IAP SSH session -- you must
allow your workstation's IP address through the firewall.

There are two equivalent options:

### Option 1: add the rule to the blueprint

Edit the `network` module in your blueprint and add a `settings:` block listing the
firewall rule. Replace `203.0.113.42/32` with your workstation's public IP (find it
with `curl -s ifconfig.me`), or replace `203.0.113.0/24` with a CIDR block covering your
home or office network:

``` yaml
  - id: network
    source: modules/network/vpc
    settings:
      firewall_rules:
        - name: ssh-from-workstation
          direction: INGRESS
          ranges: [203.0.113.42/32]   # single IP -- replace with your workstation's IP
          # ranges: [203.0.113.0/24] # or a CIDR block covering your network
          allow:
            - protocol: tcp
              ports: [22]
```

Then re-run `gcluster create -w ...` and `gcluster deploy ...` to apply the change.

### Option 2: add the rule out-of-band

After the cluster is deployed, add the firewall rule with `gcloud` directly:

``` bash
# Replace YOUR_IP with your workstation's public IP, or a CIDR covering your network.
# Replace VPC_NAME with the name of the VPC created by your deployment
# (typically "${deployment_name}-net0", e.g., "ppro-e4s-25-11-cluster-net0").
gcloud compute firewall-rules create ssh-from-workstation \
    --network=VPC_NAME \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=tcp:22 \
    --source-ranges=YOUR_IP/32
```

!!! danger "Do not use `0.0.0.0/0`"
    Opening TCP port 22 to the entire internet is a serious security risk. Always restrict
    `--source-ranges` (or `ranges:`) to a single IP (`/32`) or a small CIDR block under
    your control. Prefer Console (IAP) SSH whenever possible.

[1]: https://docs.cloud.google.com/cluster-toolkit/docs/quickstarts/slurm-cluster
[2]: https://github.com/GoogleCloudPlatform/cluster-toolkit?tab=readme-ov-file#quickstart
[vpc-module]: https://github.com/GoogleCloudPlatform/cluster-toolkit/tree/main/modules/network/vpc
[iap]: https://cloud.google.com/iap
