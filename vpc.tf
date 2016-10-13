variable "cidr_block" {
    default = "172.20.0.0/16"
}

variable "cluster_name" {
}

resource "aws_vpc" "main" {
    cidr_block = "${var.cidr_block}"
    enable_dns_hostnames = true

    tags {
        Name = "kubernetes-vpc"
        KubernetesCluster = "${var.cluster_name}"
    }
}

resource "aws_vpc_dhcp_options" "main" {
    domain_name = "ec2.internal"
    domain_name_servers = ["AmazonProvidedDNS"]

    tags {
        Name = "kubernetes-dhcp-option-set"
        KubernetesCluster = "${var.cluster_name}"
    }
}

// TODO: we can seem to import this
// resource "aws_vpc_dhcp_options_association" "main" {
//     vpc_id = "${aws_vpc.main.id}"
//     dhcp_options_id = "${aws_vpc_dhcp_options.main.id}"
// }

resource "aws_network_acl" "main" {
    vpc_id = "${aws_vpc.main.id}"

    ingress {
        protocol   = -1
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }

    egress {
        protocol   = -1
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }
}

resource "aws_security_group" "masters" {
    vpc_id = "${aws_vpc.main.id}"
    name = "kubernetes-master-${var.cluster_name}"
    description = "Kubernetes security group applied to master nodes"

    tags {
        KubernetesCluster = "${var.cluster_name}"
    }
}

resource "aws_security_group_rule" "masters-disallow-ingress" {
    security_group_id = "${aws_security_group.masters.id}"

    type = "ingress"
    from_port = 0
    to_port = 0
    protocol = "-1"
}

resource "aws_security_group_rule" "masters-allow-ssh" {
    security_group_id = "${aws_security_group.masters.id}"

    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "masters-allow-https" {
    security_group_id = "${aws_security_group.masters.id}"

    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "masters-disallow-egress" {
    security_group_id = "${aws_security_group.masters.id}"

    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "minions" {
    vpc_id = "${aws_vpc.main.id}"
    name = "kubernetes-minion-${var.cluster_name}"
    description = "Kubernetes security group applied to minion nodes"

    tags {
        KubernetesCluster = "${var.cluster_name}"
    }
}

resource "aws_security_group_rule" "minions-disallow-ingress" {
    security_group_id = "${aws_security_group.minions.id}"

    type = "ingress"
    from_port = 0
    to_port = 0
    protocol = "-1"
}

resource "aws_security_group_rule" "minions-allow-ssh" {
    security_group_id = "${aws_security_group.minions.id}"

    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "minions-disallow-egress" {
    security_group_id = "${aws_security_group.minions.id}"

    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.main.id}"
}

resource "aws_subnet" "main" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "172.20.0.0/24"

    tags {
        KubernetesCluster = "${var.cluster_name}"
    }
}

