# Create a VPC
resource "aws_vpc" "terra-vpc" {
  cidr_block = var.cidr_block

  tags = {
    Name = "Terra"
  }
}

# Create Subnets
resource "aws_subnet" "public-a" {
  vpc_id                  = aws_vpc.terra-vpc.id
  cidr_block              = "192.168.0.0/20"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-a"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id            = aws_vpc.terra-vpc.id
  cidr_block        = "192.168.16.0/20"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "Private-a"
  }
}

resource "aws_subnet" "public-b" {
  vpc_id                  = aws_vpc.terra-vpc.id
  cidr_block              = "192.168.32.0/20"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-2b"
  tags = {
    Name = "Public-b"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id            = aws_vpc.terra-vpc.id
  cidr_block        = "192.168.48.0/20"
  availability_zone = "eu-west-2b"

  tags = {
    Name = "Private-b"
  }
}

# Create internet Gateway
resource "aws_internet_gateway" "terra-igw" {
  vpc_id = aws_vpc.terra-vpc.id

  tags = {
    Name = "Terra-IGW"
  }
}

# Create NAT Gateways for Private Subnets
resource "aws_nat_gateway" "natgw-1a" {
  allocation_id = aws_eip.eip-nat-1.id
  subnet_id     = aws_subnet.public-a.id

  tags = {
    Name = "Terra-NATGW-1a"
  }
  depends_on = [aws_internet_gateway.terra-igw]

}
resource "aws_nat_gateway" "natgw-1b" {
  allocation_id = aws_eip.eip-nat-2.id
  subnet_id     = aws_subnet.public-b.id

  tags = {
    Name = "Terra-NATGW-1b"
  }
  depends_on = [aws_internet_gateway.terra-igw]
}

# Create Elastic IPs for NAT Gateways
resource "aws_eip" "eip-nat-1" {
  vpc = true
  tags = {
    Name = "Terra-Eip-1"
  }
  depends_on = [aws_internet_gateway.terra-igw]
}

resource "aws_eip" "eip-nat-2" {
  vpc = true
  tags = {
    Name = "Terra-Eip-2"
  }
  depends_on = [aws_internet_gateway.terra-igw]
}

#Create Route Table
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.terra-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terra-igw.id
  }

  tags = {
    Name = "Public-RT"
  }
}

resource "aws_route_table" "private-rt-a" {
  vpc_id = aws_vpc.terra-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw-1a.id
  }

  tags = {
    Name = "Private-RT-A"
  }
}

resource "aws_route_table" "private-rt-b" {
  vpc_id = aws_vpc.terra-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw-1b.id
  }


  tags = {
    Name = "Private-RT-B"
  }
}

# Associate Subnets to Route Tables
resource "aws_route_table_association" "private-a" {
  subnet_id      = aws_subnet.private-a.id
  route_table_id = aws_route_table.private-rt-a.id
}

resource "aws_route_table_association" "public-a" {
  subnet_id      = aws_subnet.public-a.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "private-b" {
  subnet_id      = aws_subnet.private-b.id
  route_table_id = aws_route_table.private-rt-b.id
}

resource "aws_route_table_association" "public-b" {
  subnet_id      = aws_subnet.public-b.id
  route_table_id = aws_route_table.public-rt.id
}

# Print Output
output "nat_gateway-1a" {
  value = aws_nat_gateway.natgw-1a.public_ip
}

output "nat_gateway-1b" {
  value = aws_nat_gateway.natgw-1b.public_ip
}

output "eip-1" {
  value = aws_eip.eip-nat-1.public_ip
}


output "eip-2" {
  value = aws_eip.eip-nat-2.public_ip
}
