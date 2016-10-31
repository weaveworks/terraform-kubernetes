variable cluster_name {
    description = "The name of the cluster; will be used to tag objects in AWS.  Each cluster should have a different name to allow multiple clusters to exist in the same AWS region / account."
}

variable vpc_cidr_block {
    default = "172.20.0.0/16"
}

variable hosts_cidr_block {
    default = "172.20.0.0/24"
}

variable container_cidr_block {
    default = "10.244.0.0/16"
}

variable ami_id {
    // default AMI is k8s-1.3-debian-jessie, the default from kube-up
    // See https://cloud-images.ubuntu.com/locator/ec2/ for others.
    // HVM, ebs-root only please.
    default = "ami-08ee2f65"
}

variable master_instance_type {
    default = "m3.xlarge"
}

variable minion_instance_type {
    default = "c3.4xlarge"
}

variable availability_zone {
    default = "us-east-1a"
}

variable key_pair_name {
    default = "kubernetes-key-pair"
}

variable iam_suffix {
	default = ""
}

variable num_masters {
    default = 1
}

variable num_minions {
    default = 3
}

variable autoscaling_group_suffix {
    default = ""
}

output "minion_security_group_id" {
    value = "${aws_security_group.minions.id}"
}

output "subnet_id" {
    value = "${aws_subnet.main.id}"
}
