resource "aws_vpc" "main" {
    cidr_block = "${var.vpc_cidr_block}"
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

resource "aws_security_group_rule" "masters-allow-minions" {
    security_group_id = "${aws_security_group.masters.id}"

    type = "ingress"
    source_security_group_id = "${aws_security_group.minions.id}"
    from_port = 0
    to_port = 0
    protocol = "-1"
}

resource "aws_security_group_rule" "masters-allow-masters" {
    security_group_id = "${aws_security_group.masters.id}"

    type = "ingress"
    self = true
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

resource "aws_security_group_rule" "masters-allow-egress" {
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

resource "aws_security_group_rule" "minions-allow-minions" {
    security_group_id = "${aws_security_group.minions.id}"

    type = "ingress"
    self = true
    from_port = 0
    to_port = 0
    protocol = "-1"
}

resource "aws_security_group_rule" "minions-allow-masters" {
    security_group_id = "${aws_security_group.minions.id}"

    type = "ingress"
    source_security_group_id = "${aws_security_group.masters.id}"
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

resource "aws_security_group_rule" "minions-allow-egress" {
    security_group_id = "${aws_security_group.minions.id}"

    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "minions-allow-http" {
    security_group_id = "${aws_security_group.minions.id}"

    type = "ingress"
    from_port = 30080  // Defined in default/frontend-svc.yaml
    to_port = 30080
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "minions-allow-https" {
    security_group_id = "${aws_security_group.minions.id}"

    type = "ingress"
    from_port = 30443 // Defined in default/frontend-svc.yaml
    to_port = 30443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.main.id}"
}

resource "aws_subnet" "main" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.hosts_cidr_block}"
    availability_zone = "${var.availability_zone}"

    tags {
        KubernetesCluster = "${var.cluster_name}"
    }
}

resource "aws_route_table" "main" {
    vpc_id = "${aws_vpc.main.id}"

    tags {
        KubernetesCluster = "${var.cluster_name}"
    }
}

resource "aws_route_table_association" "main" {
    subnet_id = "${aws_subnet.main.id}"
    route_table_id = "${aws_route_table.main.id}"
}

resource "aws_route" "internet-route" {
    route_table_id = "${aws_route_table.main.id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
    depends_on = ["aws_route_table.main"]
}

resource "aws_route" "master-route" {
    count = "${var.num_masters}"
    route_table_id = "${aws_route_table.main.id}"

    destination_cidr_block = "${cidrsubnet(var.container_cidr_block, 8, 100 + count.index)}"
    instance_id = "${element(aws_instance.master.*.id, count.index)}"
}

resource "aws_route" "minion-route" {
    count = "${var.num_minions}"
    route_table_id = "${aws_route_table.main.id}"

    destination_cidr_block = "${cidrsubnet(var.container_cidr_block, 8, 254 - count.index)}"
    instance_id = "${element(aws_instance.minion.*.id, count.index)}"
}
