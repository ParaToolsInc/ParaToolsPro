# E4S Pro Getting Started with Heidi

## General Background Information

[Heidi][heidi] is Adaptive Computing's AI supercomputing platform that provides on-demand access to high-performance computing resources.

In this tutorial we will show you how to launch an HPC cluster on Heidi using the Heidi web interface.

This tutorial assumes you have access to a functioning Heidi server, installed and configured as described in the [Heidi Documentation][1].

[heidi]: https://adaptivecomputing.com/heidi-ai-supercomputing/

## Tutorial

### Log In

Enter the URL for your Heidi web portal instance in a web browser and log in with the credentials you created during configuration.

### Create/Launch Cluster

Mouse over the menu on the left and select [Cluster Manager][2].

You can create or import a new cluster using the '+' button in the upper right. Once your cluster is configured hit the ellipsis '...' on the right side of your cluster entry and select the deploy option. The portal will display the progress of the cluster initialization and let you know when the cluster is available.

### Launch Jobs

Once your cluster has been launched you can create and issue jobs from the Job Manager, available via the menu on the right.

### SSH To Cluster

To log into the cluster you can find the cluster's public IP address at the end of the startup log, available from the cluster's ellipsis menu while the cluster is active. 

Alternatively you can ssh to the Heidi server and use the Heidi CLI to log in. To do this you must first configure a VPN to access the Heidi server. We recommend [WireGuard][3]. Once WireGuard is installed and configured with your authentication credentials and the address of the Heidi server you can ssh to the server. From the Heidi server you can log in to your cluster like `oddc cluster:ssh <cluster-name>` Add the `--admin` flag for access to sudo privileges on the cluster.

### Cleanup

When you are finished de-allocate the cluster by entering its ellipsis menu and selecting destroy. The portal will show the destruction's progress and indicate when it is complete. Once the cluster has been deactivate it may be deleted entirely via the delete option in the ellipsis menu or kept in your cluster list for a new instance to be initialized later.

[1]: https://support.adaptivecomputing.com/wp-content/uploads/2024/06/HPCCloudOnDemandDataCenterUserGuide771.pdf
[2]: https://support.adaptivecomputing.com/wp-content/uploads/2024/06/HPCCloudOnDemandDataCenterUserGuide771.pdf#%5B%7B%22num%22%3A28%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C88.5%2C669.75%2C0%5D
[3]: https://www.wireguard.com/
