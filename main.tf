
data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami


}

data "aws_vpc" "default" {
  default = true
}


module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}



resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id

  vpc_security_group_ids = [module.blog_sg.security_group_id] // Referencing to security group module (blog_sg) instead of resource(aws_security_group).
 
 
  instance_type = var.instance_type


  subnet_id = module.blog_vpc.public_subnets[0]

  tags = {
    Name = "HelloWorld"
  }
}


module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name = "blog_new"

  vpc_id = module.blog_vpc.vpc_id


  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]

}


resource "aws_security_group" "blog"{

  name        = "blog"
  description = "Inbound - HTTP/ HTTPS. Outbound = 0.0.0.0 Everything" 
  
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "blog_http_in"{
  
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id

}

resource "aws_security_group_rule" "blog_https_in"{
  
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id

}

resource "aws_security_group_rule" "outbound"{
  
  type      = "egress"
  from_port = 0 // Means any port
  to_port   = 0
  protocol  = -1 // Means all protocols applied
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id

}
