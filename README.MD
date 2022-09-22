<div id="header" align="center">
  <img src="https://www.freecodecamp.org/news/content/images/2020/10/gcp.png" width="400"/>
</div>

# **Task 1**

> Create and configure a web server on GCP.
Can be done anyway using the console, Google cloud SDK Terraform etc, preferably using a Linux distro OS with any preferred web server software (Apache, Nginx etc). Play this back to us, Talk us through what you did to get it working. What you struggle with, and what you did to overcome any challenges. What services and steps did you take? Share with ut the tutorials or resources you used for reference.

> Stretch goal - make it scalable!

## Getting it working

First, a Virtual Machine (VM) instance is needed running on Google Cloud for the web server to be created on to meet the tasks. 

Accomplished by navigating to the Menu in Google Cloud and looking for 'Compute Engine' and then 'VM Instances' where VMs can be created.

Once in VM Instances, I click 'Create Instance' and configure the VM.

I went with a configuration that met the requirements with cost optimisation in mind. A predefined E2 series, micro type for this proof of concept. 

The task asked for a linux distribution OS so for the boot disk, I went with Debian.

Ensure to enable 'http access' or add the 'http-server' tag under networking. This would allow you to view the web server is running in a browser window after installation.

I confirmed the instance is running by viewing the Instances area of VM Instances.

![vm](images/vm.png)

The next step is to install a web server on the VM using SSH.

After logging in, I run the following in the CLI

> sudo apt-get update #resync package index files from sources
> sudo apt-get install apache2 -y  #Install apache web server. -y for assume yes
> sudo apache2 -v #verify apache2 is installed.


After exit out of the SSH and click the external IP to test the web server is running.


![SDK deployment](images/gui-confirmation.png)


## Deploying using SDK

The above can be accomplished by using the CLI.

> gcloud config set compute/zone us-east1-a
#Default zone setting

I then run the following

> gcloud compute instances create "louzado-web-server1" \
> --machine-type "e2-micro" \
> --image-project "debian-cloud" \
> --image-family "debian-10" \
> --subnet "default"
> --tags=http-server

You will be prompted to authorize a call to the compute engine api
Confirm VM instance is running by running 

> gcloud compute instances describe louzado-web-server1

SSH into the VM

> gcloud compute ssh --zone "us-central1-a" "louzado-web-server1"  --project "project_id"
#project_id will need to enter actual project id

Install apache 2

> sudo apt-get update #resync package index files from sources
> sudo apt-get install apache2 -y  #Install apache web server. -y for assume yes
> sudo apache2 -v #verify apache2 is installed.

## Deploying using terraform

Folder - env/test/louzado-web-server1

Please note I have left the instances to accept connections from any source ip for the purposes of this demo only.


## Make it scalable (Optional)

To ensure my application has high availability, I will be scaling the application using managed instance groups and a load balancer.

To automate the installation of the web server on each instance, I will be running the below script on startup of the the VM with a custom welcome page. This welcome page will also allow me to hop between instances to ensure the MIG is up and running and also installs the stress tool.


    #! /bin/bash
    NAME=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)
    ZONE=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | sed 's@.*/@@')
    sudo apt-get update
    sudo apt-get install -y stress apache2
    sudo systemctl start apache2
    cat <<EOF> /var/www/html/index.html
    <body style="font-family: sans-serif">
    <html><body><h1>Hi, My name is Will and this is my Web Server!</h1>
    <p>You  is $NAME</p>
    <p>It is a pleasure to serve you from the $ZONE datacenter.</p>
    <p><img> src="https://shorturl.at/LTYZ3" alt="Unicorse"></p>
    </body></html>
    EOF

This will be deployed via terraform but the high level steps are described below.

1) Create an Instance Template
2) Create an Instance Group
3) Create health checks
4) Firewall configuration
4) Create Load Balancer with a new backend 
5) Verify instances are working by using load balancer external IP.
6) Stress test the application to ensure it scales out and in depending on load.




