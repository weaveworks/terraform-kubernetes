
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