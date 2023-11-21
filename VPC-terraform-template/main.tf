terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.12.0"
    }
  }
}

########################
## IBM Cloud Provider ##
########################
provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = "eu-de"
  resource_group   = "fro-rg"
}


#####################
## Local Variables ##
#####################
/*
To use a local variable: ${local.<VAR_NAME>}
*/
locals {
  BASENAME    = "fro-testing"
  REGION      = "eu-de"
  VPCNAME     = "${local.BASENAME}-vpc"
  CLUSTERNAME = "${local.BASENAME}-cluster"
  KUBEVERSION = "4.6.23_openshift"
  NODEFLAVOR  = "bx2.4x16"
  NUMNODES    = 1
}

####################
## Resource Group ##
####################
data "ibm_resource_group" "group" {
  name = "fro-rg"
}

################
## Create VPC ##
################
resource "ibm_is_vpc" "vpc" {
  name                        = local.VPCNAME
  resource_group              = data.ibm_resource_group.group.id
  default_network_acl_name    = "${local.VPCNAME}-default-acl"
  default_security_group_name = "${local.VPCNAME}-default-sg"
  default_routing_table_name  = "${local.VPCNAME}-default-rt"
}

/* 
#############################
## Create custom ACL rules ##
## with all access open    ##
#############################
resource "ibm_is_network_acl" "network_acl" {
  name = "${local.BASENAME}-acl1"
  vpc  = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
  rules {
    name        = "outbound"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "outbound"
  }
  rules {
    name        = "inbound"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
  }
}
*/

################
## Create PGW ##
################
resource "ibm_is_public_gateway" "pgw1" {
  name           = "${local.BASENAME}-public-gtw-01"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${local.REGION}-1"
  resource_group = data.ibm_resource_group.group.id
}

###################
## Create Subnet ##
###################
resource "ibm_is_subnet" "subnet1" {
  name                     = "${local.BASENAME}-sn-01"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${local.REGION}-1"
  total_ipv4_address_count = 256
  resource_group           = data.ibm_resource_group.group.id
  public_gateway           = ibm_is_public_gateway.pgw1.id
  //  network_acl          = ibm_is_network_acl.network_acl.id
}

/*
resource "ibm_is_public_gateway" "pgw2" {
  name           = "${local.BASENAME}-public-gtw-02"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${local.REGION}-1-2"
  resource_group = data.ibm_resource_group.group.id
}
*/

/*
resource "ibm_is_subnet" "subnet2" {
  name                     = "${local.BASENAME}-sn-02"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${local.REGION}-2"
  total_ipv4_address_count = 256
  resource_group           = data.ibm_resource_group.group.id
  public_gateway           = ibm_is_public_gateway.pgw1.id
  ## network_acl              = ibm_is_network_acl.network_acl.id
}
*/

/*
resource "ibm_is_public_gateway" "pgw3" {
  name           = "${local.BASENAME}-public-gtw-03"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${local.REGION}-3"
  resource_group = data.ibm_resource_group.group.id
}
*/

/*
resource "ibm_is_subnet" "subnet3" {
  name                     = "${local.BASENAME}-sn-03"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${local.REGION}-3"
  total_ipv4_address_count = 256
  resource_group           = data.ibm_resource_group.group.id
  public_gateway           = ibm_is_public_gateway.pgw1.id
  ## network_acl           = ibm_is_network_acl.network_acl.id
}
*/

####################
## Define SSH key ##
####################
data "ibm_is_ssh_key" "ssh_key_id" {
  name = "shareable-ssh-key"
}


###############
## VSI Image ##
###############
data "ibm_is_image" "ubuntu" {
  name = "ibm-ubuntu-22-04-3-minimal-amd64-1"
}

################
## Create VSI ##
################
resource "ibm_is_instance" "vsi1" {
  name           = "${local.BASENAME}-vsi-testing-01"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${local.REGION}-1"
  keys           = [data.ibm_is_ssh_key.ssh_key_id.id]
  image          = data.ibm_is_image.ubuntu.id
  profile        = "bx2-2x8"
  resource_group = data.ibm_resource_group.group.id

  primary_network_interface {
    subnet = ibm_is_subnet.subnet1.id
  }
}



