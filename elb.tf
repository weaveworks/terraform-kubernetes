// ELB for the k8s API
resource "aws_elb" "master" {
    name = "${var.elb_name}"
    subnets = ["${aws_subnet.main.*.id}"]
    security_groups = ["${aws_security_group.master-elb.id}"]

    tags {
        KubernetesCluster = "${var.cluster_name}"
    }

    listener {
        instance_port = 443
        instance_protocol = "tcp"
        lb_port = 443
        lb_protocol = "tcp"
    }

    health_check {
       // The number of checks before the instance is declared healthy.
       healthy_threshold = 2

       // The number of checks before the instance is declared unhealthy.
       unhealthy_threshold = 6

       // In seconds
       timeout = 5

       // In seconds
       interval = 10

       target = "TCP:443"
    }

    instances = ["${aws_instance.master.*.id}"]
}
