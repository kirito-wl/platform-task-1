
#Instance Template creation

resource "google_compute_instance_template" "louzado-template" {
  can_ip_forward = "false"

  confidential_instance_config {
    enable_confidential_compute = "false"
  }

  disk {
    auto_delete  = "true"
    boot         = "true"
    device_name  = "louzado-template"
    disk_size_gb = "10"
    disk_type    = "pd-balanced"
    mode         = "READ_WRITE"
    source_image = "projects/debian-cloud/global/images/debian-11-bullseye-v20220822"
    type         = "PERSISTENT"
  }

  labels = {
    env = "dev"
  }

  machine_type = "f1-micro"
  tags         = ["http-server"]

  metadata = {
    startup-script = "#! /bin/bash\nNAME=$(curl -H \"Metadata-Flavor: Google\" http://metadata.google.internal/computeMetadata/v1/instance/name)\nZONE=$(curl -H \"Metadata-Flavor: Google\" http://metadata.google.internal/computeMetadata/v1/instance/zone | sed 's@.*/@@')\nsudo apt-get update\nsudo apt-get install -y stress apache2\nsudo systemctl start apache2\ncat <<EOF> /var/www/html/index.html\n<body style=\"font-family: sans-serif\">\n<html><body><h1>Hi, My name is Will and this is my Web Server!</h1>\n<p>This web server is $NAME</p>\n<p>You are being served from the $ZONE datacenter.</p>\n<p><img src=\"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR3QPqkkg4u1VpCmaa2dxGp4qP-hC-cyz1NeeDpTIqzgyVb-yK9xmYvqd3qA2yjaKgS9g\u0026usqp=CAU\" alt=\"Unicorse\"></p>\n</body></html>\nEOF"
  }

  name = "louzado-template"

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    network     = "default"
    stack_type  = "IPV4_ONLY"
  }

  project = "platform-task-1"
  region  = "us-east1"

  reservation_affinity {
    type = "ANY_RESERVATION"
  }

  scheduling {
    automatic_restart   = "true"
    min_node_cpus       = "0"
    on_host_maintenance = "MIGRATE"
    preemptible         = "false"
  }
}

#Create Health check
resource "google_compute_health_check" "autohealing" {
  name                = "louzado-health-check"
  description         = "Health check of managed instance group"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
  project             = "platform-task-1"

  log_config {
    enable = "false"
  }
  tcp_health_check {
    port         = "80"
  }
}

#Firewall rule to allow google health check to query the instances
resource "google_compute_firewall" "allow-healthcheck" {
  allow {
    ports    = ["80"]
    protocol = "tcp"
  }

  description   = "allow-healthcheck"
  direction     = "INGRESS"
  disabled      = "false"
  name          = "allow-healthcheck"
  network       = "default"
  priority      = "1000"
  project       = "platform-task-1"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

#Create Instance Group from Template

module "mig1" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  instance_template = "louzado-template"
  region            = "us-east1"
  hostname          = "default"
  target_size       = 3
  named_ports = [{
    name = "http",
    port = 80
  }]
  network    = "default"
  }
  

resource "google_compute_region_instance_group_manager" "louzado-group" {
  name               = "louzado-group"
  base_instance_name = "web-server" 
  region             = "us-east1"

  version {
    instance_template  = google_compute_instance_template.louzado-template.id
    }
  
  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }
  
  target_size  = 3
}

resource "google_compute_region_autoscaler" "autoscaler" {
  name   = "louzado-autoscaler"
  region = "us-east1"
  target = google_compute_region_instance_group_manager.louzado-group.id

  autoscaling_policy {
    max_replicas    = 6
    min_replicas    = 3
    cooldown_period = 60

    cpu_utilization {
      target = 0.6
    }
  }
}