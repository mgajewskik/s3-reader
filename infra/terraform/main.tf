provider "aws" {
  region = var.aws_region
}

locals {
  prefix = var.service_name
}

resource "aws_launch_template" "this" {
  name_prefix   = "${local.prefix}-launch-template"
  image_id      = data.aws_ami.service.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              cat <<EOT > /etc/s3-reader.env
              AWS_REGION=${var.aws_region}
              PORT=8080
              S3_BUCKET_NAME=${aws_s3_bucket.this.id}
              EOT

              chown s3-reader:s3-reader /etc/s3-reader.env
              systemctl enable ${var.service_name}.service
              systemctl start ${var.service_name}.service
              EOF
  )

  # NOTE required to enable for instance connect
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

resource "aws_autoscaling_group" "this" {
  name                = "${local.prefix}-asg"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.this.arn]
  health_check_type   = "ELB"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    triggers = ["tag"]

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
      auto_rollback          = true

      alarm_specification {
        alarms = [aws_cloudwatch_metric_alarm.unhealthy_hosts.id]
      }
    }
  }

  tag {
    key                 = "Name"
    value               = var.service_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Version"
    value               = var.service_version
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "target_tracking_policy" {
  name                   = "${local.prefix}-target-tracking-policy"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.this.arn_suffix}/${aws_lb_target_group.this.arn_suffix}"
    }
    target_value = 1000.0
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.this.name
  lb_target_group_arn    = aws_lb_target_group.this.arn
}
