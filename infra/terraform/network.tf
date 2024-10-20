resource "aws_lb" "this" {
  name               = "${local.prefix}-application-lb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.lb.id]
  subnets         = data.aws_subnets.default.ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "this" {
  name     = "${local.prefix}-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.this.arn
#   port              = "443"
#   protocol          = "HTTPS"
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.this.arn
#   }
#
#   lifecycle {
#     create_before_destroy = true
#   }
# }

resource "aws_security_group" "ec2" {
  name        = "${local.prefix}-ec2-sg"
  description = "Security group for EC2 instances."
  vpc_id      = data.aws_vpc.default.id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Allow inbound traffic from the load balancer."
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  # TODO set up SSM rules
  # ingress {
  #   description = "Allow inbound traffic from SSM."
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    description = "Allow inbound traffic from EC2 Instance Connect."
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # IP address for eu-west-1
    cidr_blocks = ["18.202.216.48/29"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "lb" {
  name        = "${local.prefix}-lb-sg"
  description = "Security group for Application LB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP inbound traffic from the internet."
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS inbound traffic from the internet."
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
