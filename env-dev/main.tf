terraform {
  required_providers {
    google = {
      source = "hashicorp/google"    
    }
  }
}

#Compute Instance

resource "google_compute_instance" "default" {
  name         = "louzado-web-server1"
  project      = "platform-task-1"
  machine_type = "e2-micro"
  tags         = ["http-server"]
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  #Install Apache Webserver

    metadata_startup_script = <<SCRIPT
     NAME=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)
     ZONE=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | sed 's@.*/@@')
     sudo apt-get update
     sudo apt-get install -y apache2
     sudo systemctl start apache2
     cat <<EOF> /var/www/html/index.html
     <body style="font-family: sans-serif">
     <html><body><h1>Hi, My name is Will and this is my Web Server!</h1>
     <p>This web server is $NAME</p>
     <p>You are being served from the $ZONE datacenter.</p>
     <p><img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR3QPqkkg4u1VpCmaa2dxGp4qP-hC-cyz1NeeDpTIqzgyVb-yK9xmYvqd3qA2yjaKgS9g&usqp=CAU" alt="Unicorse"></p>
     </body></html>
     <EOF>
     SCRIPT 

  network_interface {
    network = "default"


    access_config {        
    }
  }
}