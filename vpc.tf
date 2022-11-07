
resource "aws_vpc" "terraform-vpc" {
  cidr_block = var.aws_region["cidr"]

  tags = {
    Name = "terraform-vpc"
  }
}


resource "aws_subnet" "public" {
  for_each                = var.public_subnet
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = each.value["cidr"]
  map_public_ip_on_launch = "true" # enable public ip allocation for instance 
  availability_zone       = each.value["az"]
  tags = {
    Name = "terraform-public-${each.key}"
  }
  depends_on = [ aws_vpc.terraform-vpc ]
}


resource "aws_subnet" "private" {
  for_each                = var.private_subnet
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = each.value["cidr"]
  map_public_ip_on_launch = "true" # enable public ip allocation for instance
  availability_zone       = each.value["az"]
  tags = {
    Name = "terraform-private-${each.key}"
  }
  depends_on = [ aws_subnet.public ]
}


resource "aws_internet_gateway" "terraform-igw" {
  vpc_id = aws_vpc.terraform-vpc.id
  tags = {
    Name = "terraform-igw"
  }
#  depends_on = [ aws_eks_node_group.worker-node-group ]
}


resource "aws_route_table" "public-RT" {
  vpc_id = aws_vpc.terraform-vpc.id
  route {
    cidr_block = var.igw_cider
    gateway_id = aws_internet_gateway.terraform-igw.id
  }

  tags = {
    Name = "terraform-public"
  }
  depends_on = [aws_internet_gateway.terraform-igw]
}


resource "aws_route_table_association" "public_RT_association" {
  count          = 2
  subnet_id      = aws_subnet.public["AZ${count.index + 1}"].id
  route_table_id = aws_route_table.public-RT.id

  depends_on = [aws_route_table.public-RT]
}


resource "aws_eip" "nat_eip" {
  count = length(var.private_subnet)
  vpc   = true
  tags = {
    Name = "terraform_eip_AZ${count.index + 1}"
  }
}


resource "aws_nat_gateway" "public-nat" {
  count             = length(var.public_subnet)
  connectivity_type = "public"
  allocation_id     = aws_eip.nat_eip[count.index].id
  subnet_id         = aws_subnet.public["AZ${count.index + 1}"].id
  tags = {
    Name = "terraform-public-nat-AZ${count.index + 1}"
  }
  depends_on = [aws_eip.nat_eip,
		aws_internet_gateway.terraform-igw]
}


resource "aws_route_table" "private-RT" {
  count  = length(var.private_subnet)
  vpc_id = aws_vpc.terraform-vpc.id
  route {
    cidr_block     = var.nat_cider
    nat_gateway_id = aws_nat_gateway.public-nat[count.index].id
  }

  tags = {
    Name = "terraform-private_AZ${count.index + 1}"
  }
  depends_on = [aws_nat_gateway.public-nat]
}


resource "aws_route_table_association" "private_RT_association" {
  count          = 2
  subnet_id      = aws_subnet.private["AZ${count.index + 1}"].id
  route_table_id = aws_route_table.private-RT[count.index].id

  depends_on = [aws_route_table.private-RT]
}


resource "aws_security_group" "security-group" {
  vpc_id = aws_vpc.terraform-vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "terraform-security-group"
  }
}


resource "aws_lb" "load_balancer" {
  name                       = "terraform-loadb-alancer"
  internal                   = false
  load_balancer_type         = "application"
  enable_deletion_protection = false
  security_groups            = [aws_security_group.security-group.id]
  subnets                    = [aws_subnet.private["AZ1"].id, aws_subnet.private["AZ2"].id]

  depends_on = [
    aws_security_group.security-group,
    aws_subnet.private
  ]
}
