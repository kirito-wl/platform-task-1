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

The next step is to install a web server on the VM using SSH.

After logging in, I run the following in the CLI

> sudo apt-get update #resync package index files from sources
> sudo apt-get install apache2 -y  #Install apache web server. -y for assume yes
> sudo apache2 -v #verify apache2 is installed.

SSH into the external IP to test the web server is running.

#Explore adding Service account created individually away from the default compute service account

## Deploying using SDK

The above can be accomplished by using the CLI.

> gcloud config set compute/zone us-east1-a

Then run the following

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

Install apache2

> sudo apt-get update #resync package index files from sources
> sudo apt-get install apache2 -y  #Install apache web server. -y for assume yes
> sudo apache2 -v #verify apache2 is installed.

## Deploying using terraform

Folder - env/dev/task1

Please note I have left the instances to accept connections from any source ip for the purposes of this demo only.


## Make it scalable (Optional)

To ensure my application has high availability, I will be scaling the application using managed instance groups and a load balancer.

To automate the installation of the web server on each instance, I will be running the below script on startup of the the VM with a custom welcome page. This welcome page will also allow me to hop between instances to ensure the MIG is up and running and also installs the stress tool which will allow us to check it can scale up or down.

         #! /bin/bash
         NAME=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)
         ZONE=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | sed 's@.*/@@')
         sudo apt-get update
         sudo apt-get install -y stress apache2
         sudo systemctl start apache2
         cat <<EOF> /var/www/html/index.html
         <body style="font-family: sans-serif">
        <html><body><h1>Hi, My name is Will and this is my Web Server!</h1>
        <p>This web server is $NAME</p>
        <p>You are being served from the $ZONE datacenter.</p>
        <p><img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR3QPqkkg4u1VpCmaa2dxGp4qP-hC-cyz1NeeDpTIqzgyVb-yK9xmYvqd3qA2yjaKgS9g&usqp=CAU" alt="Unicorse"></p>
        </body></html>
         EOF

Numbers 1-4 will be deployed via terraform with the Load Balancer and subsequent testing being done using the console as a live demo.

1) Create an Instance Template
2) Create an Instance Group
3) Create health checks
4) Firewall configuration
--------------------------
5) Create Load Balancer with a new backend
5) Verify instances are working by using load balancer external IP.
6) Stress test the application to ensure it scales out and in depending on load

Please note I have left the instances to accept connections from any source ip for  ssh forthe purposes of this demo only.

Now that the load balancer is created I want to check each of the instances created are working by visiting the load balancer external IP.

Pick an instance to SSH into and run the following script
> stress --cpu 2 --io 1 --vm --vm-bytes 128M --timeout 30s

Refresh VM Instances to see if new VMs are being created as a result of stress. Visit external IPs and refresh to see if variable instance name and zone name changes.

# **Task 2**

> We’d like you to investigate hosting a static content website on GCP using a service other than GCP Compute Engine. A design spike is an investigation piece of work where you try and come up with a proof of concept or a structured approach to solving a particular problem, task or issue. In this spike, we would like you to find 2 different ways of hosting a static content website in GCP using a service that is not GCP Compute engine. Document both methods and pick which method you would use, play this back to us why you would use this and why not the other method. You do not need to have this created and running to show us, just your documentation, thoughts and design on the 2 methods and why you picked 1 over the other.

Approach

1) Googling to understand key terms
2) Think of a basic use case with assumptions for the above
3) Think/Research GCP solutions that meet the need
4) Design/Sketch the solutions out
5) Pros/Cons of each solution
6) Decision and justification.

Static content is a file that remains constant every time it is served or delivered to users. For example, a menu for a restaurant or a blog.
A static website is composed of simple HTML, CSS, images or Javascript files, not php.

Assumptions

- Above is needed to showcase a basic web presence for proof of concept
- Scaling not needed as do not expect a lot of traffic for this demo but showcase a scalable scenario if traffic increases
- Static content is non-confidential and publicly available i.e. Menu, public blog
- Proof of concept only so no additional network/firewall configuration
- In all cases, a domain must be purchased to make visible. This can be done on Google Domains. 

# Option 1 - Cloud Storage Bucket

Identified Google Cloud Storage and buckets as a solution. 
As a static website can be composed of simple html, css and JS files, they can be stored in a bucket and made publicly available.
Low cost
Fast spin up time

--Easy and very unsecure option for Proof of concept--

Create Storage Bucket
Set fine-grained access control
Upload HTML file
Make HTML file public
Visit Public URL of file

![easy-unsecure](env/images/simple-poc-proof.png)
![poc-unsecure](env/images/diagram-simple-poc.png)

--Commercial proof of concept--

Pre-requisites

Familiarity with CNAME, A records and DNS
Domain name the business or individual owns or manages i.e. www.louzado-cafe.co.uk or www.creedthoughts.gov
(www.creedthoughts.gov.www\creedthoughts is not a domain)

For this proof of concept, ill use louzado-cafe.co.uk as an example domain
Steps: 

1) Connect domain owned to Cloud Storage by creating a CNAME record that points to c.storage.googleapis.com
#CNAME record directs traffic from my domain to the resources in the bucket. 

2) Verify ownership of the domain with Google. This will generate a key to use to configure the CloudDNS service that will allow your domain to connect to a domain named bucket where the static content will be hosted.

2) Create storage bucket with the same name as the domain. i.e. wwwlouzado-cafeco.uk

For high availability, select a multi-regional zone and the location closes to the audience. For this example - EU.
Standard as the default storage class and uniform access control with public access prevention disabled.

3) Upload static content to be hosted in the bucket.
4) Select the bucket and change the permissions, adding an allUsers member and setting the role of Storage Object Viewer.
5) Add a main index and 404 page i.e. index.html and 404.html using the settings icon on buckets.
5) Test the website URL in a browser

Diagram

![cloudDNS-poc](env-dev/images/diagram-dev-poc.png)



