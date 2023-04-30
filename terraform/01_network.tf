# ------------------------------------------------------------#
#  VPC
# ------------------------------------------------------------#
resource "aws_vpc" "terraform_vpc"{
    cidr_block           = "${var.vpc_cidr}"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
        Name = "${var.tag_name}-vpc"
    }
}

# ------------------------------------------------------------#
#  Subnet
# ------------------------------------------------------------#
resource "aws_subnet" "terraform_public_subnet_a" {
    availability_zone = "${var.region}a"
    cidr_block        = "${var.public_subnet_a_cidr}"
    vpc_id            = aws_vpc.terraform_vpc.id
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.tag_name}-public-subnet-a"
    }
}

resource "aws_subnet" "terraform_public_subnet_c" {
    availability_zone = "${var.region}c"
    cidr_block        = "${var.public_subnet_c_cidr}"
    vpc_id            = aws_vpc.terraform_vpc.id
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.tag_name}-public-subnet-c"
    }
}

resource "aws_subnet" "terraform_private_subnet_a" {
    availability_zone = "${var.region}a"
    cidr_block        = "${var.private_subnet_a_cidr}"
    vpc_id            = aws_vpc.terraform_vpc.id
    map_public_ip_on_launch = false
    tags = {
        Name = "${var.tag_name}-private-subnet-a"
    }
}

resource "aws_subnet" "terraform_private_subnet_c" {
    availability_zone = "${var.region}c"
    cidr_block        = "${var.private_subnet_c_cidr}"
    vpc_id            = aws_vpc.terraform_vpc.id
    map_public_ip_on_launch = false
    tags = {
        Name = "${var.tag_name}-private-subnet-c"
    }
}

# ------------------------------------------------------------#
#  InternetGateway
# ------------------------------------------------------------#
resource "aws_internet_gateway" "terraform_igw" {
    vpc_id = aws_vpc.terraform_vpc.id
    tags = {
        Name = "${var.tag_name}-igw"
    }
}

# ------------------------------------------------------------#
#  RouteTable
# ------------------------------------------------------------#
# create RouteTable and Routing
resource "aws_route_table" "terraform_public_route_table" {
    vpc_id = aws_vpc.terraform_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.terraform_igw.id
    }
    tags = {
        Name = "${var.tag_name}-public-route"
    }
}

# RouteTable Associate
resource "aws_route_table_association" "terraform_public_subnet_a_route_tabel_accociation" {
    subnet_id      = aws_subnet.terraform_public_subnet_a.id
    route_table_id = aws_route_table.terraform_public_route_table.id
}

resource "aws_route_table_association" "terraform_public_subnet_c_route_tabel_accociation" {
    subnet_id      = aws_subnet.terraform_public_subnet_c.id
    route_table_id = aws_route_table.terraform_public_route_table.id
}
