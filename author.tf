resource "aws_alb_target_group" "author" {
  name     = "${var.env}-author"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${data.aws_alb.eq.vpc_id}"

  health_check = {
    healthy_threshold   = 2
    unhealthy_threshold = 30
    interval            = 5
    timeout             = 2
    path                = "/"
  }

  tags {
    Environment = "${var.env}"
  }
}

resource "aws_alb_listener_rule" "author" {
  listener_arn = "${var.aws_alb_listener_arn}"
  priority     = 201

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.author.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${aws_route53_record.author.name}"]
  }
}

resource "aws_route53_record" "author" {
  zone_id = "${data.aws_route53_zone.dns_zone.id}"
  name    = "${var.env}-author.${var.dns_zone_name}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${data.aws_alb.eq.dns_name}"]
}

data "template_file" "author" {
  template = "${file("${path.module}/task-definitions/author.json")}"

  vars {
    LOG_GROUP                            = "${aws_cloudwatch_log_group.author.name}"
    CONTAINER_REGISTRY                   = "${var.docker_registry}"
    CONTAINER_TAG                        = "${var.author_tag}"
  }
}

resource "aws_ecs_task_definition" "author" {
  family                = "${var.env}-author"
  container_definitions = "${data.template_file.author.rendered}"
}

resource "aws_ecs_service" "author" {
  depends_on = [
    "aws_alb_target_group.author",
    "aws_alb_listener_rule.author",
  ]

  name            = "${var.env}-author"
  cluster         = "${data.aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.author.family}"
  desired_count   = "1"
  iam_role        = "${aws_iam_role.author.arn}"

  placement_strategy {
    type  = "spread"
    field = "host"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.author.arn}"
    container_name   = "author"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = ["placement_strategy"]
  }
}

resource "aws_iam_role" "author" {
  name = "${var.env}_iam_for_author"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "author" {
  "statement" = {
    "effect" = "Allow"

    "actions" = [
      "elasticloadbalancing:*",
    ]

    "resources" = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "author" {
  name   = "${var.env}_iam_for_author"
  role   = "${aws_iam_role.author.id}"
  policy = "${data.aws_iam_policy_document.author.json}"
}

resource "aws_cloudwatch_log_group" "author" {
  name = "${var.env}-author"

  tags {
    Environment = "${var.env}"
  }
}

output "author_address" {
  value = "https://${aws_route53_record.author.fqdn}"
}
