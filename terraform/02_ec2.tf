# ------------------------------------------------------------#
#  EC2
# ------------------------------------------------------------#
# create EC2
resource "aws_instance" "terraform_ec2"{
    ami                         = "ami-078296f82eb463377"
    instance_type               = "t2.micro"
    key_name                    = "circleci-ec2-key"
    availability_zone           = "${var.region}a"
    vpc_security_group_ids      = [aws_security_group.terraform_ec2_sg.id]
    subnet_id                   = aws_subnet.terraform_public_subnet_a.id
    associate_public_ip_address = true
    tags = {
        Name = "${var.tag_name}-ec2"
    }
}

# create EC2 Security Group
resource "aws_security_group" "terraform_ec2_sg" {
    name   = "${var.tag_name}-ec2-sg"
    vpc_id = aws_vpc.terraform_vpc.id
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 3000
        to_port     = 3000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }
}
