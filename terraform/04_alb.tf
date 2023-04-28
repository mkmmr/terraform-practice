# ------------------------------------------------------------#
#  ALB
# ------------------------------------------------------------#
# create ALB
resource "aws_lb" "terraform_alb" {
    name               = "${var.tag_name}-alb"
    load_balancer_type = "application"
    internal           = false
    ip_address_type    = "ipv4"
    security_groups    = [aws_security_group.terraform_alb_sg.id]
    subnets            = [aws_subnet.terraform_public_subnet_a.id, aws_subnet.terraform_public_subnet_c.id]
    tags = {
        Name = "${var.tag_name}-alb"
    }
}

# create ALB security group
resource "aws_security_group" "terraform_alb_sg" {
    name   = "${var.tag_name}-alb-sg"
    vpc_id = aws_vpc.terraform_vpc.id
    ingress {
        from_port   = 80
        to_port     = 80
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

# create Target Group
resource "aws_lb_target_group" "terraform_alb_tg" {
    name         = "${var.tag_name}-alb-tg"
    vpc_id       = aws_vpc.terraform_vpc.id
    target_type  = "instance"
    protocol     = "HTTP"
    port         = 80
    health_check {
        protocol = "HTTP"
        path     = "/"
    }
    tags = {
        Name = "${var.tag_name}-alb-tg"
    }
}

# attach EC2 to Target Group
resource "aws_lb_target_group_attachment" "terraform-target-ec2-1" {
    target_group_arn = aws_lb_target_group.terraform_alb_tg.arn
    target_id        = aws_instance.terraform_ec2.id
}

# create Listner
resource "aws_lb_listener" "terraform_alb_listener" {
    load_balancer_arn = aws_lb.terraform_alb.arn
    default_action {
        target_group_arn = aws_lb_target_group.terraform_alb_tg.arn
        type             = "forward"
    }
    port              = "80"
    protocol          = "HTTP"
}
