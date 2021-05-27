terraform {
  required_version = "~> 0.14.4" 
  
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 3.27"
    }
  }
}

provider "aws" {
    region = "ap-northeast-1"
}

module "vpc-10-sg-all-all" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "vpc-10-all-all"
  vpc_id      = module.vpc-10.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp", "ssh-tcp"]
  egress_rules        = ["all-all"]
}

module "vpc-20-sg-all-all" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "vpc-20-all-all"
  vpc_id      = module.vpc-20.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp", "ssh-tcp"]
  egress_rules        = ["all-all"]
}

module "vpc-30-sg-all-all" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "vpc-30-all-all"
  vpc_id      = module.vpc-30.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp", "ssh-tcp"]
  egress_rules        = ["all-all"]
}

module "tester-vpc-10" {
    source = "terraform-aws-modules/ec2-instance/aws"
    name = "tester-vpc-10"

    count = 1
    ami = "ami-06098fd00463352b6"
    instance_type = "t2.micro"

    key_name = "macbook"
    vpc_security_group_ids = [module.vpc-10-sg-all-all.security_group_id]
    subnet_id = module.vpc-10.private_subnets[0]
}

module "tester-vpc-20" {
    source = "terraform-aws-modules/ec2-instance/aws"
    name = "tester-vpc-20"

    count = 1
    ami = "ami-06098fd00463352b6"
    instance_type = "t2.micro"

    key_name = "macbook"
    vpc_security_group_ids = [module.vpc-20-sg-all-all.security_group_id]
    subnet_id = module.vpc-20.private_subnets[0]
}

module "tester-vpc-30" {
    source = "terraform-aws-modules/ec2-instance/aws"
    name = "tester-vpc-30"

    count = 1
    ami = "ami-06098fd00463352b6"
    instance_type = "t2.micro"

    key_name = "macbook"
    vpc_security_group_ids = [module.vpc-30-sg-all-all.security_group_id]
    subnet_id = module.vpc-30.private_subnets[0]
}

resource "aws_route" "vpc-10-private-subnet-to-tgw" {
  route_table_id              = module.vpc-10.private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id      = module.tgw.ec2_transit_gateway_id
}

resource "aws_route" "vpc-20-private-subnet-to-tgw" {
  route_table_id              = module.vpc-20.private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id      = module.tgw.ec2_transit_gateway_id
}

resource "aws_route" "vpc-30-private-subnet-to-tgw" {
  route_table_id              = module.vpc-30.private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id      = module.tgw.ec2_transit_gateway_id
}

module "vpc-10" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"

  name = "vpc-10"
  cidr = "10.10.0.0/16"

  azs = ["ap-northeast-1a"]
  private_subnets = ["10.10.1.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
      Terraform = "true"
  }
}

module "vpc-20" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"

  name = "vpc-20"
  cidr = "10.20.0.0/16"

  azs = ["ap-northeast-1c"]
  private_subnets = ["10.20.1.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
      Terraform = "true"
  }
}

module "vpc-30" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"

  name = "vpc-30"
  cidr = "10.30.0.0/16"

  azs = ["ap-northeast-1d"]
  private_subnets = ["10.30.1.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
      Terraform = "true"
  }
}

module "tgw" {
    source = "terraform-aws-modules/transit-gateway/aws"

    name = "test-tgw"
    enable_auto_accept_shared_attachments = true

    vpc_attachments = {
        vpc-10 = {
            vpc_id = module.vpc-10.vpc_id
            subnet_ids = module.vpc-10.private_subnets
            dns_support = true
            tgw_routes = [
                {
                    destination_cidr_block = "10.10.0.0/16"
                },
                {
                    destination_cidr_block = "0.0.0.0/0"
                    blackhole   = true
                }
            ]
        }, 
        vpc-20 = {
            vpc_id = module.vpc-20.vpc_id
            subnet_ids = module.vpc-20.private_subnets
            dns_support = true
            tgw_routes = [
                {
                    destination_cidr_block = "10.20.0.0/16"
                }
                # {
                #     # destination_cidr_block = "0.0.0.0/0"
                #     # blackhole   = true
                # }
            ]
        },
        vpc-30 = {
            vpc_id = module.vpc-30.vpc_id
            subnet_ids = module.vpc-30.private_subnets
            dns_support = true
            tgw_routes = [
                {
                    destination_cidr_block = "10.30.0.0/16"
                }
                # {
                #     destination_cidr_block = "0.0.0.0/0"
                #     blackhole   = true
                # }
            ]
        }
    }
}

resource "aws_vpn_connection" "connection-to-on-prem" {
    customer_gateway_id = aws_customer_gateway.cgw-on-prem.id
    transit_gateway_id = module.tgw.ec2_transit_gateway_id
    type = aws_customer_gateway.cgw-on-prem.type
}

resource "aws_customer_gateway" "cgw-on-prem" {
    bgp_asn = 65000
    ip_address = module.on-prem.on_prem_public_ip
    type = "ipsec.1"
}

module "on-prem" {
  source = "turelljj/simulated_on_prem_with_ipsec_and_bgp/aws"
  AWS_SECRET_ID = var.AWS_SECRET_ID
  AWS_KEY_ID = var.AWS_KEY_ID
  tunnel1_public_ip = aws_vpn_connection.connection-to-on-prem.tunnel1_address
  tunnel1_shared_key = aws_vpn_connection.connection-to-on-prem.tunnel1_preshared_key
  aws_tunnel_1_insde_ip = aws_vpn_connection.connection-to-on-prem.tunnel1_vgw_inside_address
  on_prem_tunnel_1_inside_ip = aws_vpn_connection.connection-to-on-prem.tunnel1_cgw_inside_address
  tunnel2_public_ip = aws_vpn_connection.connection-to-on-prem.tunnel2_address
  tunnel2_shared_key = aws_vpn_connection.connection-to-on-prem.tunnel2_preshared_key
  aws_tunnel_2_insde_ip = aws_vpn_connection.connection-to-on-prem.tunnel2_vgw_inside_address
  on_prem_tunnel_2_inside_ip = aws_vpn_connection.connection-to-on-prem.tunnel2_cgw_inside_address
}
