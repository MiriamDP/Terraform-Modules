# VPC Resources

data "aws_availability_zones" "available" {
  state = "available"
}

# NETWORKING #
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.prefix}-vpc"
  cidr = var.vpc_address_range

  azs             = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  public_subnets  = var.vpc_public_subnet_ranges

  enable_nat_gateway = false
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  map_public_ip_on_launch = true

}