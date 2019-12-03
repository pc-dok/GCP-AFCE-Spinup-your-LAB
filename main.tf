#######################################################################
# Creates all GCP resources that are defined under each module folder #
#######################################################################

# provider for google - you must first create a Project on GCP and a Service Account
provider "google" {
  credentials = file("account.json")
  project     = var.gcp_project
  region      = var.region
  zone        = var.zone
}

#######################################################
# Creates a VPC and custom Subnet                     #
#######################################################

resource "google_compute_network" "vpc" {
  name = "${var.gcp_project}-net-01"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name            = "${var.gcp_project}-subnet-01"
  network         = google_compute_network.vpc.self_link
  ip_cidr_range   = var.cidr-gcp
  region          = var.region
}

###################################################################################
# Creates a GCP Cloud NAT for having Internet available on all VM Instances later #
###################################################################################

resource "google_compute_router" "router" {
  name    = "${var.gcp_project}-router-01"
  region  = google_compute_subnetwork.subnet.region
  network = google_compute_network.vpc.self_link

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.gcp_project}-router-nat-01"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

#######################################################
# Creates a Virtual Machine Instance - our MDT Server #
#######################################################

resource "google_compute_instance" "vm_mdt" {
  name                    = var.vm-mdt
  machine_type            = "n1-standard-2"
  depends_on              = [google_compute_router_nat.nat]
  metadata = {
    windows-startup-script-ps1 = file("cloud.ps1")
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
    network_ip  = var.ip-mdt-01
  }
}

##################################################
# Creates a Firewall Rule for IAP @ GCP          #
##################################################

# allow rdp traffic over IAP
resource "google_compute_firewall" "allow-rdp" {
  name        = "${var.gcp_project}-fwrule-rdp-01"
  network     = google_compute_network.vpc.self_link
  description = "Allow RDP over IAP Management"
  priority    = "1010"
  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol  = "tcp"
    ports     = ["3389"]
  }
}

##################################################
# Creates a VPN Tunnel from GCP tp pfSense @home #
##################################################

# Attach a VPN gateway to each network.
resource "google_compute_vpn_gateway" "target_gateway1" {
  name        = "vpn1"
  network     = google_compute_network.vpc.self_link
  region      = var.region
  depends_on  = [google_compute_router_nat.nat]
}

# Create an outward facing static IP for each VPN that will be used by the
# other VPN to connect.
resource "google_compute_address" "vpn_static_ip1" {
  name   = "vpn-static-ip1"
  region = var.region
}

# Forward IPSec traffic coming into our static IP to our VPN gateway.
resource "google_compute_forwarding_rule" "fr1_esp" {
  name        = "fr1-esp"
  region      = var.region
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_static_ip1.address
  target      = google_compute_vpn_gateway.target_gateway1.self_link
}

# The following two sets of forwarding rules are used as a part of the IPSec
# protocol
resource "google_compute_forwarding_rule" "fr1_udp500" {
  name        = "fr1-udp500"
  region      = var.region
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.vpn_static_ip1.address
  target      = google_compute_vpn_gateway.target_gateway1.self_link
}

resource "google_compute_forwarding_rule" "fr1_udp4500" {
  name        = "fr1-udp4500"
  region      = var.region
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.vpn_static_ip1.address
  target      = google_compute_vpn_gateway.target_gateway1.self_link
}

# Each tunnel is responsible for encrypting and decrypting traffic exiting
# and leaving its associated gateway
resource "google_compute_vpn_tunnel" "tunnel1" {
  name               = "tunnel1"
  region             = var.region
  peer_ip            = var.yourpublicip
  shared_secret      = var.sharedsecret
  target_vpn_gateway = google_compute_vpn_gateway.target_gateway1.self_link
  remote_traffic_selector = var.cidr-local-list
  local_traffic_selector  = var.cidr-gcp-list
  depends_on = [
    google_compute_forwarding_rule.fr1_udp500,
    google_compute_forwarding_rule.fr1_udp4500,
    google_compute_forwarding_rule.fr1_esp,
  ]
}

# Each route tells the associated network to send all traffic in the dest_range
# through the VPN tunnel
resource "google_compute_route" "route1" {
  name                = "route-to-private-network-vpn"
  description         = "Default local route to the subnetwork 192.168.1.0/24"
  network             = google_compute_network.vpc.name
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel1.self_link
  dest_range          = var.cidr-local
  priority            = 1000
}

########################################################################
# Creates a Firewall Rule for the internal Traffic over the VPN Tunnel #
########################################################################

# allow all internal traffic over VPN to GCP
resource "google_compute_firewall" "allow-internal-vpn" {
 name        = "${var.gcp_project}-fwrule-vpn-01"
 network     = google_compute_network.vpc.self_link
 description = "Allow all internal Traffic from VPN to GCP"
 priority    = "1020"
 source_ranges = var.cidr-local-list
 allow {
   protocol   = "tcp"
   ports      = ["0-65535"]
  }
  allow {
   protocol   = "udp"
   ports      = ["0-65535"]
  }
  allow {
   protocol   = "icmp"
 }
}

#####################################################
# Creates a Firewall Rule for the internal Traffic  #
#####################################################

# allow all internal traffic over VPN to GCP
resource "google_compute_firewall" "allow-internal-gcp" {
 name        = "${var.gcp_project}-fwrule-int-01"
 network     = google_compute_network.vpc.self_link
 description = "Allow all internal Traffic from internal GCP"
 priority    = "1030"
 source_ranges = var.cidr-gcp-list
 allow {
   protocol   = "tcp"
   ports      = ["0-65535"]
  }
  allow {
   protocol   = "udp"
   ports      = ["0-65535"]
  }
  allow {
   protocol   = "icmp"
 }
}
