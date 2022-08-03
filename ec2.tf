# Create Private Key
resource "tls_private_key" "terra-private-key" {
  algorithm = "RSA"
  rsa_bits  = 4096

}

# Create Keypair for EC2 instances
resource "aws_key_pair" "terra-key" {
  key_name   = "terra-key"
  public_key = tls_private_key.terra-private-key.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.terra-private-key.private_key_pem}' > ./'${self.key_name}'.pem"
  }
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "terra-amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-*-5.10-*-x86_64-gp2"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }


}

# Create Security Group for DB and EC2 instances
resource "aws_security_group" "terra-web-access" {
  name   = "terra-web-access"
  vpc_id = aws_vpc.terra-vpc.id

  tags = {
    Name = "Terra-Web-Access"
  }
}


# Create Inbound and Outbound Rules for Security Group 
resource "aws_security_group_rule" "terra-http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.terra-web-access.id
}

resource "aws_security_group_rule" "terra-https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.terra-web-access.id
}

resource "aws_security_group_rule" "terra-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.terra-web-access.id
}

resource "aws_security_group_rule" "terra-ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.terra-web-access.id
}

resource "aws_security_group" "jump-host" {
  name   = "jump-host"
  vpc_id = aws_vpc.terra-vpc.id

  tags = {
    Name = "Terra-Jump-Host"
  }
}

resource "aws_security_group_rule" "jump-ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jump-host.id
}

resource "aws_security_group_rule" "jump-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jump-host.id
}

resource "aws_security_group_rule" "jump-http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jump-host.id
}


resource "aws_security_group_rule" "terra-rds" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.terra-web-access.id

}

# Create JumpHost 
resource "aws_instance" "jump-host" {
  ami                    = data.aws_ami.terra-amazon-linux-2.id
  instance_type          = var.instance_type
  availability_zone      = aws_subnet.public-b.availability_zone
  subnet_id              = aws_subnet.public-b.id
  vpc_security_group_ids = [aws_security_group.terra-web-access.id]
  key_name               = aws_key_pair.terra-key.key_name

  tags = {
    Name = "Jump-Host"
  }
}
