terraform {
 backend "gcs" {
   bucket  = "louzado-bucket-tfstate"
   prefix  = "terraform/state"
 }
}