##############################################################
# Creates a Virtual Machine Instance - our Domain Controller #
##############################################################

resource "google_compute_instance" "vm_dc" {
  name                    = var.vm-dc
  machine_type            = "n1-standard-2"
  depends_on              = [google_compute_router_nat.nat]
  metadata = {
    windows-startup-script-ps1 = file("dc1.ps1")
  }

  boot_disk {
    initialize_params {
      image       = "windows-cloud/windows-2019"
      size        = "100"
      type        = "pd-ssd"
    }
  }

  network_interface {
    network     = google_compute_network.vpc.self_link
    subnetwork  = google_compute_subnetwork.subnet.self_link
    network_ip  = var.ip-dc-01
  }
}
