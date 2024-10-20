packer {
  required_plugins {
    amazon = {
      version = "~> 1.3"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "version" {
  type    = string
  default = "0.0.0"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "s3-reader" {
  ami_name      = "s3-reader-${var.version}-${local.timestamp}"
  instance_type = "t2.micro"
  region        = var.aws_region

  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  ssh_username = "ec2-user"
}

build {
  sources = ["source.amazon-ebs.s3-reader"]

  provisioner "file" {
    # NOTE: path is relative to the root of the repository
    source      = "./infra/packer/s3-reader"
    destination = "/tmp/s3-reader"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/s3-reader /usr/local/bin/s3-reader",
      "sudo chmod +x /usr/local/bin/s3-reader",
      "sudo useradd -r -s /sbin/nologin s3-reader",
      "sudo chown s3-reader:s3-reader /usr/local/bin/s3-reader"
    ]
  }

  provisioner "file" {
    # NOTE: path is relative to the root of the repository
    source      = "./infra/packer/s3-reader.service"
    destination = "/tmp/s3-reader.service"
  }

  provisioner "shell" {
    inline = [
      "sudo touch /var/log/s3-reader.log",
      "sudo chown s3-reader:s3-reader /var/log/s3-reader.log",
      "sudo touch /etc/s3-reader.env",
      "sudo mv /tmp/s3-reader.service /etc/systemd/system/s3-reader.service",
      "sudo systemctl daemon-reload",
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm",
      "sudo yum install -y amazon-cloudwatch-agent",

      "sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null << EOT",
      "{",
      "  \"agent\": {",
      "    \"run_as_user\": \"root\"",
      "  },",
      "  \"logs\": {",
      "    \"logs_collected\": {",
      "      \"files\": {",
      "        \"collect_list\": [",
      "          {",
      "            \"file_path\": \"/var/log/s3-reader.log\",",
      "            \"log_group_name\": \"/ec2/s3-reader\",",
      "            \"log_stream_name\": \"{instance_id}\"",
      "          }",
      "        ]",
      "      }",
      "    }",
      "  }",
      "}",
      "EOT",

      "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",
      "sudo systemctl enable amazon-cloudwatch-agent",
    ]
  }
}
