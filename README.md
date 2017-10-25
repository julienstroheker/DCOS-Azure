Deploy DC/OS 1.9 running CoreOS on Microsoft Azure using Terraform
==================

![](./resources/imgs/ninjaterracat.png)

This script allow you to deploy a DC/OS cluster in best practices on Microsoft Azure.

A Section about Packer is in progress

You can watch [this online meetup](https://youtu.be/ifNitKh-L0o?t=2231) about Terraform and DC/OS in general where I presented this project.

# Terraform Usage #

#### WARNING: Be sure that you are not overriding existing Azure resources that are in use. This Terraform process will create a resource group to contain all dependent resources within. This makes it easy to cleanup.

#### NOTE: This deployment is not meant to obviate the need to understand the install process or read the docs. Please spend some time to understand both [DC/OS](https://docs.mesosphere.com/1.9/overview/) and the [install process](https://docs.mesosphere.com/1.9/administration/installing/).

## Preperation Steps ##

* It is assumed that you have a functioning Azure client installed. You can do so [here](https://github.com/Azure/azure-cli)

* Install [Terraform](https://www.terraform.io/downloads.html) and create credentials for Terraform to access Azure. To do so, you will need to following environment variables:

  * ARM_SUBSCRIPTION_ID=<subscription id>
  * ARM_CLIENT_ID=<client id>
  * ARM_CLIENT_SECRET=<cient secret>
  * ARM_TENANT_ID=<tenant id>

* The values for the above environment variables can be obtained through the Azure CLI commands below.

*NOTE: A more detailed overview can be found on the [Terraform Site](https://www.terraform.io/docs/providers/azurerm/index.html)*

```bash
$ az login
```

* Run the following commands. This will print 2 lines, the first is the tenant ID and the second is the subscription ID.

```bash
$ az account show

{
  "environmentName": "AzureCloud",
  "id": "a97d7ca2-18ca-426f-b7c4-1a2cdaa4d9d1",
  "isDefault": true,
  "name": "My_Azure_Subscription",
  "state": "Enabled",
  "tenantId": "34a934ff-86a1-34af-34cd-2d7cd0134bd34",
  "user": {
    "name": "juliens@microsoft.com",
    "type": "user"
  }
}

export ARM_SUBSCRIPTION_ID=`az account show --output tsv | cut -f2`
```

* Create an Azure application 

```bash
$ export PASSWORD=`openssl rand -base64 24`

$ az ad app create --display-name dcosterraform --identifier-uris http://docs.mesosphere.com --homepage http://www.mesosphere.com --password $PASSWORD

$ unset PASSWORD
```

* Create A Service Principal

```bash
$ APPID=`az ad app list --display-name dcosterraform -o tsv --out tsv | grep dcos | cut -f1`

$ az ad sp create --id $APPID
```

* Grant Permissions To Your Application

```bash
$ az role assignment create --assignee http://docs.mesosphere.com --role "Owner" --scope /subscriptions/$ARM_SUBSCRIPTION_ID

```

* Print the Client ID

```bash
$ az ad app list --display-name dcosterraform
```

*NOTE: A more detailed overview can be found on the [Terraform Site](https://www.terraform.io/docs/providers/azurerm/index.html)*

## Deploy the Azure infrastructure and DC/OS ##

* First, review the default configuratiion. Most common options are available in `terraform/dcos/terraform.tfvars`. The full list of available options are in `terraform/dcos/variables.tf`. CoreOS is the default as it has pre-requirements built in.

* Update `dcos/terraform.tfvars` with the path to your passwordless SSH public and private keys.

* Change `resource_suffix` (and optionally `resource_base_name`) to something unique

* Make sure that the `bootstrap_script_url`, `install_script_url` and `dcos_download_url` variables are updated with the correct public URL that you want to use.

* Optionally, customize the `agent_private_count` (default 10), the `agent_public_count` (default 1) and `master_count` for master (default 3), the agents size is Standard_D2_V2 per default, but you can change it for your need in  `dcos/variables.tf`.

* Create the DC/OS cluster by executing:
```bash
$ EXPORT ARM_SUBSCRIPTION_ID=<your subscription id>
$ EXPORT ARM_CLIENT_ID=<your client id>
$ EXPORT ARM_CLIENT_SECRET=<your cient secret>
$ EXPORT ARM_TENANT_ID=<your tenant id>

$ cd <repo>/terraform && terraform apply
```
### Connection to the cluster

* Initiate a SSH tunnel to `<masterVIP>.<location>.cloudapp.azure.com` and you should be able to reach the DC/OS UI.
```bash
$ sudo ssh core@<masterVIP>.<location>.cloudapp.azure.com -p 2200 -L 8080:localhost:443 -k <sshPrivateKey>
```
* The default username/password is `admin/Passw0rd`.

## ADDITIONAL ##

### Customize DC/OS Install ###

#### Default Security & Telemetry ####

Is off by default, that can be changed by modifying the `dcos/files/bootstrap.sh` file and following the install docs [here](https://docs.mesosphere.com/1.9/administration/installing/custom/advanced/)

### Cleanup ###

To restart and cleanup the Azure assets run the following commands from the <repo>/terraform directory

```bash
$ az group delete dcosterraform
info:    Executing command group delete
Delete resource group dcosterraform? [y/n] y
+ Deleting resource group dcosterraform                                        
info:    group delete command OK

$ cd <repo>/terraform && rm ./*/*terraform.tfstate && rm -rf ./*/.terraform*

```

### Troubleshooting ###

If the deployment gets in an inconsistent state (repeated `terraform apply` commands fail, or output references to leases that no longer exist), you may need to manually reconcile. Destroy the `<dcosterrform>` resource group, run `terraform remote config -disable` and delete all `terraform.tfstate*` files from `dcos`, follow the above instructions again.


# Baked your base image with Packer and Ansible

More to come
