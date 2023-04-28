# ------------------------------------------------------------#
#  RDS
# ------------------------------------------------------------#
# create RDS
resource "aws_db_instance" "terraform_rds"{    
    identifier              = "${var.tag_name}-rds-mysql"
    engine                  = "mysql"
    engine_version          = "${var.mysql_version}"
    multi_az                = false
    username                = "root"
    password                = "${var.mysql_master_user_pass}"
    instance_class          = "db.t2.micro"
    storage_type            = "gp2"
    allocated_storage       = 20
    db_subnet_group_name    = aws_db_subnet_group.terraform_db_subnet_group.name
    publicly_accessible     = false
    vpc_security_group_ids  = [aws_security_group.terraform-rds-sg.id]
    availability_zone       = "${var.region}a"
    port                    = 3306
    parameter_group_name    = aws_db_parameter_group.terraform_db_parameter_group.name
    option_group_name       = aws_db_option_group.terraform_db_option_group.name
    backup_retention_period = 0
    skip_final_snapshot  = true
    auto_minor_version_upgrade = false
    tags = {
        Name = "${var.tag_name}-rds"
    }
}

# create RDS Security Group
resource "aws_security_group" "terraform-rds-sg" {
    name        = "${var.tag_name}-rds-sg"
    description = "Allow EC2 Security Group access"
    vpc_id      = aws_vpc.terraform_vpc.id
    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        security_groups = [aws_security_group.terraform_ec2_sg.id]
    }
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }
}

# create RDS Subnet Group
resource "aws_db_subnet_group" "terraform_db_subnet_group" {
    name        = "${var.tag_name}-subnet-group"
    description = "${var.tag_name} RDS SubnetGroup"
    subnet_ids  = [aws_subnet.terraform_private_subnet_a.id, aws_subnet.terraform_private_subnet_c.id]
    tags = {
        Name = "${var.tag_name}-rds-subnet-group"
    }
}

# create RDS Parameter Group
resource "aws_db_parameter_group" "terraform_db_parameter_group" {
    name        = "${var.tag_name}-mysql80"
    description = "${var.tag_name} RDS MySQL8.0 ParamaterGroup"
    family      = "${var.rds_family}"
    tags = {
        Name = "${var.tag_name}-rds-parameter-group"
    }
}

# create RDS Option Group
resource "aws_db_option_group" "terraform_db_option_group" {
    name                     = "${var.tag_name}-mysql80"
    option_group_description = "${var.tag_name}-mysql80"
    engine_name              = "mysql"
    major_engine_version     = "8.0"
    tags = {
        Name = "${var.tag_name}-rds-option-group"
    }
}
