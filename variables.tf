######################################################
# Creates all Variables for CIDR Subnets and Project #
######################################################

variable "gcp_project" {
        default = "gcp-n4k-lab-v03"
    }

variable "region" {
        default = "europe-west1"
    }

variable "zone" {
        default = "europe-west1-d"
    }

variable "vm-mdt" {
        default = "vsgcp-mdt-01"
    }

variable "vm-dc" {
        default = "vsgcp-dc-01"
    }

variable "yourpublicip" {
        default = "1.2.3.4"
    }

variable "sharedsecret" {
        default = "2342635463fgsrrt45634564536"
    }

variable "cidr-gcp" {
        type    = string
        default = "172.21.2.0/24"
    }

variable "cidr-local" {
        type    = string
        default = "192.168.1.0/24"
    }

variable "cidr-gcp-list" {
        type = list
        default = ["172.21.2.0/24"]
    }

variable "cidr-local-list" {
        type = list
        default = ["192.168.1.0/24"]
    }

variable "ip-mdt-01" {
        default = "172.21.2.11"
    }

variable "ip-dc-01" {
        default = "172.21.2.12"
    }  
