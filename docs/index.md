---
title: ParaTools Pro for E4S™ Documentation
description: ParaTools Pro for E4S™ - HPC documentation, tutorials, and cloud deployment guides for AWS, GCP, Azure, and Heidi
canonical_url: https://docs.paratoolspro.com/
image: assets/images/gcluster/e4s_desktop_thumb.jpg
twitter_card: summary_large_image
---

<!--- --8<-- "README.md" --->

# ParaTools Pro for E4S™

![Curated selection of AI and machine learning packages available in E4S including TensorFlow, PyTorch, and scientific computing libraries](assets/images/gcluster/python-packages-and-viz-tools.jpg){ align=right width=600 }

The Extreme-scale Scientific Software Stack [(E4S™)][1] is a broad collection of HPC focused [software packages][2]. E4S provides a unified computing environment for deployment of open-source projects. E4S includes contributions from many organizations, including national laboratories, universities, and industry. E4S packages are deployed and managed via [Spack][3]. E4S was originally developed to provide a common software environment for the exascale leadership computing systems currently being deployed at DOE National Laboratories across the U.S.

ParaTools Pro for E4S™ takes E4S and deploys it to virtual machines and containers that are hardened and optimized for use on commercial clouds. It adds additional valuable features such as enhanced MPI performance, a performant remote desktop interface, and extra, optimized software packages for a variety of AI and other HPC applications. ParaTools Pro for E4S™ also adds deployment and development support from ParaTools, Inc.

[1]: https://www.e4s.io
[2]: https://e4s-project.github.io/DocPortal.html
[3]: https://github.com/spack/spack

ParaTools Pro for E4S™ is supported by the U.S. Department of Energy's SBIR program.

## Supported Cloud Providers

ParaTools Pro for E4S™ is available on multiple cloud platforms, each with comprehensive deployment guides and documentation:

| Cloud Provider | ParaTools Pro for E4S™ Marketplace Image | Documentation |
|----------------|------------------------------------------|---------------|
| **Amazon Web Services (AWS)** | [AWS Parallel Cluster](https://aws.amazon.com/marketplace/pp/prodview-xprkx44kyqgp6) | [Getting Started: AWS Parallel Cluster](AWS/getting-started-AWS.md) |
|  | [AWS Parallel Computing Service (PCS)](https://aws.amazon.com/marketplace/pp/prodview-xprkx44kyqgp6) | [Getting Started: AWS PCS](AWS/getting-started-AWS-PCS.md) |
| **Google Cloud Platform (GCP)** | [Google Cluster Toolkit](https://console.cloud.google.com/marketplace/product/paratools-public/paratools-pro-for-e4s-on-googleclustertoolkit-amd64) | [Getting Started: Google Cluster Toolkit](GCP/getting-started-GCP.md) |
| **Microsoft Azure** | Azure HPC | [Getting Started](Azure/getting-started-Azure.md) |
| **[Heidi][heidi]** | Adaptive Computing AI Supercomputing | [Getting Started](Heidi/getting-started-Heidi.md) |

[heidi]: https://adaptivecomputing.com/heidi-ai-supercomputing/

Each platform provides optimized configurations for high-performance computing workloads with E4S software packages.

## Gallery

Browse screenshots showcasing the features and capabilities of ParaTools Pro for E4S™. Click on any thumbnail to view the full-resolution image.

### ParaTools Pro for E4S™ Heidi variant on GCP

<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; margin: 20px 0;">

<div style="text-align: center; border: 1px solid #ddd; padding: 10px; border-radius: 5px;">
  <a href="assets/images/gcluster/e4s_gui_visit_paraview.jpg" target="_blank">
    <img src="assets/images/gcluster/e4s_gui_visit_paraview_thumb.jpg" alt="VisIt and ParaView" style="max-width: 100%; height: auto; cursor: pointer;">
  </a>
  <p><strong>Visualization Tools</strong></p>
  <p style="font-size: 0.9em; color: #666;">VisIt and ParaView for scientific visualization</p>
</div>

<div style="text-align: center; border: 1px solid #ddd; padding: 10px; border-radius: 5px;">
  <a href="assets/images/gcluster/e4s_marimo.jpg" target="_blank">
    <img src="assets/images/gcluster/e4s_marimo_thumb.jpg" alt="Marimo Notebook" style="max-width: 100%; height: auto; cursor: pointer;">
  </a>
  <p><strong>Marimo Interactive Notebooks</strong></p>
  <p style="font-size: 0.9em; color: #666;">Reactive Python notebooks for data science</p>
</div>

<div style="text-align: center; border: 1px solid #ddd; padding: 10px; border-radius: 5px;">
  <a href="assets/images/gcluster/e4s_bionemo.jpg" target="_blank">
    <img src="assets/images/gcluster/e4s_bionemo_thumb.jpg" alt="BioNeMo AI Framework" style="max-width: 100%; height: auto; cursor: pointer;">
  </a>
  <p><strong>BioNeMo AI Framework</strong></p>
  <p style="font-size: 0.9em; color: #666;">Drug discovery and biomolecular simulation</p>
</div>

<div style="text-align: center; border: 1px solid #ddd; padding: 10px; border-radius: 5px;">
  <a href="assets/images/gcluster/e4s_desktop.jpg" target="_blank">
    <img src="assets/images/gcluster/e4s_desktop_thumb.jpg" alt="E4S Desktop" style="max-width: 100%; height: auto; cursor: pointer;">
  </a>
  <p><strong>E4S Desktop Environment</strong></p>
  <p style="font-size: 0.9em; color: #666;">Remote desktop interface with VNC</p>
</div>

<div style="text-align: center; border: 1px solid #ddd; padding: 10px; border-radius: 5px;">
  <a href="assets/images/gcluster/e4s_spack_find.jpg" target="_blank">
    <img src="assets/images/gcluster/e4s_spack_find_thumb.jpg" alt="Spack Package Listing" style="max-width: 100%; height: auto; cursor: pointer;">
  </a>
  <p><strong>Spack Package Listing</strong></p>
  <p style="font-size: 0.9em; color: #666;">Available E4S software packages</p>
</div>

<div style="text-align: center; border: 1px solid #ddd; padding: 10px; border-radius: 5px;">
  <a href="assets/images/gcluster/e4s_slurm.jpg" target="_blank">
    <img src="assets/images/gcluster/e4s_slurm_thumb.jpg" alt="Slurm Workload Manager" style="max-width: 100%; height: auto; cursor: pointer;">
  </a>
  <p><strong>Slurm Workload Manager</strong></p>
  <p style="font-size: 0.9em; color: #666;">Job scheduling and resource management</p>
</div>

<div style="text-align: center; border: 1px solid #ddd; padding: 10px; border-radius: 5px;">
  <a href="assets/images/gcluster/e4s_thirdparty_lmstudio.jpg" target="_blank">
    <img src="assets/images/gcluster/e4s_thirdparty_lmstudio_thumb.jpg" alt="LM Studio" style="max-width: 100%; height: auto; cursor: pointer;">
  </a>
  <p><strong>LM Studio Integration</strong></p>
  <p style="font-size: 0.9em; color: #666;">Local LLM deployment and testing</p>
</div>

<div style="text-align: center; border: 1px solid #ddd; padding: 10px; border-radius: 5px;">
  <a href="assets/images/gcluster/e4s_thirdparty_claude.jpg" target="_blank">
    <img src="assets/images/gcluster/e4s_thirdparty_claude_thumb.jpg" alt="Claude AI Integration" style="max-width: 100%; height: auto; cursor: pointer;">
  </a>
  <p><strong>AI Assistant Integration</strong></p>
  <p style="font-size: 0.9em; color: #666;">Third-party AI tools and services</p>
</div>

<div style="text-align: center; border: 1px solid #ddd; padding: 10px; border-radius: 5px;">
  <a href="assets/images/gcluster/e4s_heidi_infra.jpg" target="_blank">
    <img src="assets/images/gcluster/e4s_heidi_infra_thumb.jpg" alt="Heidi Infrastructure" style="max-width: 100%; height: auto; cursor: pointer;">
  </a>
  <p><strong>Heidi Infrastructure Setup</strong></p>
  <p style="font-size: 0.9em; color: #666;">Cloud infrastructure configuration</p>
</div>

<div style="text-align: center; border: 1px solid #ddd; padding: 10px; border-radius: 5px;">
  <a href="assets/images/gcluster/e4s_heidi_provision.jpg" target="_blank">
    <img src="assets/images/gcluster/e4s_heidi_provision_thumb.jpg" alt="Heidi Provisioning" style="max-width: 100%; height: auto; cursor: pointer;">
  </a>
  <p><strong>Heidi Cluster Provisioning</strong></p>
  <p style="font-size: 0.9em; color: #666;">Automated cluster deployment</p>
</div>

<div style="text-align: center; border: 1px solid #ddd; padding: 10px; border-radius: 5px;">
  <a href="assets/images/gcluster/e4s_25_11_packages.jpg" target="_blank">
    <img src="assets/images/gcluster/e4s_25_11_packages_thumb.jpg" alt="AI/ML Packages" style="max-width: 100%; height: auto; cursor: pointer;">
  </a>
  <p><strong>AI/ML Package Library</strong></p>
  <p style="font-size: 0.9em; color: #666;">Select (not exhaustive) listing of AI and machine learning packages</p>
</div>

</div>
