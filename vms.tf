resource "aws_key_pair" "main" {
    key_name = "${var.key_pair_name}"
    public_key = ""
}

resource "aws_instance" "master" {
    count = "${var.num_masters}"
    lifecycle {
        prevent_destroy = true
    }
    disable_api_termination = true

    ami = "${var.ami_id}"
    instance_type = "${var.master_instance_type}"
    iam_instance_profile = "${aws_iam_instance_profile.master.name}"
    key_name = "${aws_key_pair.main.key_name}"

    tags {
        KubernetesCluster = "${var.cluster_name}"
        Name = "${var.cluster_name}-master"
        Role = "${var.cluster_name}-master"
    }

    associate_public_ip_address = true

    // Allows the VM to masquerade IPs (for pods). Otherwise, the
    // AWS runtime restricts the VM traffic to only appear as its
    // own IP.
    source_dest_check = false
    subnet_id = "${element(aws_subnet.main.*.id, count.index % var.num_azs)}"
    availability_zone = "${element(data.aws_availability_zones.available.names, count.index % var.num_azs)}"
    vpc_security_group_ids = ["${aws_security_group.masters.id}"]

    ephemeral_block_device {
        device_name = "/dev/xvdb"
        virtual_name = "ephemeral0"
    }

    ephemeral_block_device {
        device_name = "/dev/xvdc"
        virtual_name = "ephemeral1"
    }
}

resource "aws_instance" "minion" {
    count = "${var.num_minions}"
    lifecycle {
        prevent_destroy = true
    }
    disable_api_termination = true

    ami = "${var.ami_id}"
    instance_type = "${var.minion_instance_type}"
    iam_instance_profile = "${aws_iam_instance_profile.minions.name}"
    key_name = "${aws_key_pair.main.key_name}"

    tags {
        KubernetesCluster = "${var.cluster_name}"
        Name = "${var.cluster_name}-minion"
        Role = "${var.cluster_name}-minion"
    }

    associate_public_ip_address = true

    // Allows the VM to masquerade IPs (for pods). Otherwise, the
    // AWS runtime restricts the VM traffic to only appear as its
    // own IP.
    source_dest_check = false
    subnet_id = "${element(aws_subnet.main.*.id, count.index % var.num_azs)}"
    availability_zone = "${element(data.aws_availability_zones.available.names, count.index % var.num_azs)}"
    vpc_security_group_ids = ["${aws_security_group.minions.id}"]

    ephemeral_block_device {
        device_name = "/dev/xvdb"
        virtual_name = "ephemeral0"
    }

    ephemeral_block_device {
        device_name = "/dev/xvdc"
        virtual_name = "ephemeral1"
    }
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
