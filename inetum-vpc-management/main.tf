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
  resource_group   = "inetum-cleava-rg"
}


#####################
## Local Variables ##
#####################
/*
To use a local variable: ${local.<VAR_NAME>}
*/
locals {
  BASENAME       = "management"
  REGION         = "eu-de"
  VPCNAME        = "vpc-${local.BASENAME}"
  CLUSTERNAME    = "cluster-${local.BASENAME}"
  KUBEVERSION    = "4.6.23_openshift"
  NODEFLAVOR     = "bx2.4x16"
  NUMNODES       = 1
  RESOURCE_GROUP = "inetum-cleva-rg"
}

####################
## Resource Group ##
####################
data "ibm_resource_group" "group" {
  name = "inetum-cleva-rg"
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

###########################
## Create Address Prefix ##
###########################
resource "ibm_is_vpc_address_prefix" "addr-prefix" {
  name = "${local.BASENAME}-address-prefix"
  zone = "${local.REGION}-1"
  vpc  = ibm_is_vpc.vpc.id
  cidr = "10.100.200.128/26"
}

###################
## Create Subnet ##
###################
resource "ibm_is_subnet" "subnet1" {
  depends_on = [ // Only runs if prefix was created
    ibm_is_vpc_address_prefix.addr-prefix
  ]
  name            = "${local.BASENAME}-sn-01"
  vpc             = ibm_is_vpc.vpc.id
  zone            = "${local.REGION}-1"
  ipv4_cidr_block = "10.100.200.128/26"
  resource_group  = data.ibm_resource_group.group.id
  // public_gateway           = ibm_is_public_gateway.pgw1.id
  // network_acl          = ibm_is_network_acl.network_acl.id
}

####################
## Define SSH key ##
####################
data "ibm_is_ssh_key" "ssh_key_id" {
  name = "shareable-ssh-key"
}

########################
## Create VPN Gateway ##
########################
resource "ibm_is_vpn_gateway" "vpn-gtw" {
  mode           = "policy"
  name           = "${local.BASENAME}-vpn-gateway"
  resource_group = data.ibm_resource_group.group.id
  subnet         = ibm_is_subnet.subnet1.id
}
