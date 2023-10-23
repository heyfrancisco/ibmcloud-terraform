provider "ibm" {
  generation = 2
}

resource "ibm_is_vpc" "vpc" {
  name           = var.vpc_name
  resource_group = var.resource_group
}

resource "ibm_is_subnet" "subnet_01" {
  name                     = "sn-01-madrid"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "eu-es-1"
  total_ipv4_address_count = 256
}

resource "ibm_is_subnet" "subnet_02" {
  name                     = "sn-02-madrid"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "eu-es-2"
  total_ipv4_address_count = 256
}

resource "ibm_is_subnet" "subnet_03" {
  name                     = "sn-03-madrid"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "eu-es-3"
  total_ipv4_address_count = 256
}

