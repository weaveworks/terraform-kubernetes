resource "aws_key_pair" "main" {
    key_name = "${var.key_pair_name}"
    public_key = ""
}

resource "aws_instance" "master" {
    ami = "${var.ami_id}"
    instance_type = "${var.master_instance_type}"
    iam_instance_profile = "${aws_iam_instance_profile.master.name}"

    tags {
        KubernetesCluster = "${var.cluster_name}"
        Name = "${var.cluster_name}-master"
        Role = "${var.cluster_name}-master"
    }

    associate_public_ip_address = true
    availability_zone = "${var.availability_zone}"
    subnet_id = "${aws_subnet.main.id}"
    key_name = "${aws_key_pair.main.key_name}"
    vpc_security_group_ids = ["${aws_security_group.masters.id}"]
}

resource "aws_launch_configuration" "minions" {
    name_prefix = "${var.cluster_name}-minion-group-${var.availability_zone}-${var.minion_instance_type}"
    image_id = "${var.ami_id}"
    instance_type = "${var.minion_instance_type}"

    associate_public_ip_address = true

    ephemeral_block_device {
        virtual_name = "ephemeral0"
        device_name = "/dev/sdc"
    }

    ephemeral_block_device {
        virtual_name = "ephemeral1"
        device_name = "/dev/sdd"
    }

    ephemeral_block_device {
        virtual_name = "ephemeral2"
        device_name = "/dev/sde"
    }

    ephemeral_block_device {
        virtual_name = "ephemeral3"
        device_name = "/dev/sdf"
    }

    iam_instance_profile = "${aws_iam_instance_profile.minions.name}"
    security_groups = ["${aws_security_group.minions.id}"]

    key_name = "${aws_key_pair.main.key_name}"

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "minions" {
    name = "${var.cluster_name}-minion-group-${var.availability_zone}"
    launch_configuration = "${aws_launch_configuration.minions.name}"

    tag {
        key = "Name"
        value = "${var.cluster_name}-minion"
        propagate_at_launch = true
    }

    tag {
        key = "Role"
        value = "${var.cluster_name}-minion"
        propagate_at_launch = true
    }

    tag {
        key = "KubernetesCluster"
        value = "${var.cluster_name}"
        propagate_at_launch = true
    }

    max_size = "${var.num_minions}"
    min_size = "${var.num_minions}"

    availability_zones = ["${var.availability_zone}"]
    vpc_zone_identifier  = ["${aws_subnet.main.id}"]

    health_check_grace_period = "0"
    metrics_granularity = ""

    force_delete = "false"
}

resource "aws_iam_instance_profile" "minions" {
    name = "kubernetes-minion${var.iam_suffix}"
    roles = ["${aws_iam_role.minion.name}"]
}

resource "aws_iam_instance_profile" "master" {
    name = "kubernetes-master${var.iam_suffix}"
    roles = ["${aws_iam_role.master.name}"]
}

resource "aws_iam_role" "minion" {
    name = "kubernetes-minion${var.iam_suffix}"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "master" {
    name = "kubernetes-master${var.iam_suffix}"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "minion" {
    name = "kubernetes-minion"
    role = "${aws_iam_role.minion.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::kubernetes-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "ec2:Describe*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:AttachVolume",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:DetachVolume",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "master" {
    name = "kubernetes-master"
    role = "${aws_iam_role.master.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": ["elasticloadbalancing:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::kubernetes-*"
      ]
    }
  ]
}
EOF
}
