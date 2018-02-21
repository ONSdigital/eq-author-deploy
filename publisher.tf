resource "aws_alb_target_group" "publisher" {
  name     = "${var.env}-publisher"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check = {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
    timeout             = 2
    path                = "/status"
  }

  tags {
    Environment = "${var.env}"
  }
}

resource "aws_alb_listener_rule" "publisher" {
  listener_arn = "${data.aws_lb_listener.eq.id}"
  priority     = 203

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.publisher.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${aws_route53_record.publisher.name}"]
  }
}

resource "aws_route53_record" "publisher" {
  zone_id = "${data.aws_route53_zone.dns_zone.id}"
  name    = "${var.env}-publisher.${var.dns_zone_name}"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.eq.dns_name}"
    zone_id                = "${data.aws_lb.eq.zone_id}"
    evaluate_target_health = false
  }
}

data "template_file" "publisher" {
  template = "${file("${path.module}/task-definitions/publisher.json")}"

  vars {
    LOG_GROUP            = "${aws_cloudwatch_log_group.publisher.name}"
    CONTAINER_REGISTRY   = "${var.docker_registry}"
    CONTAINER_TAG        = "${var.publisher_tag}"
    AUTHOR_API           = "https://${aws_route53_record.author-api.fqdn}"
    SCHEMA_VALIDATOR_URL = "${var.schema_validator_url}"
  }
}

resource "aws_ecs_task_definition" "publisher" {
  family                = "${var.env}-publisher"
  container_definitions = "${data.template_file.publisher.rendered}"
}

resource "aws_ecs_service" "publisher" {
  depends_on = [
    "aws_alb_target_group.publisher",
    "aws_alb_listener_rule.publisher",
  ]

  name            = "${var.env}-publisher"
  cluster         = "${data.aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.publisher.family}"
  desired_count   = "${var.publisher_min_tasks}"
  iam_role        = "${aws_iam_role.publisher.arn}"

  placement_strategy {
    type  = "spread"
    field = "host"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.publisher.arn}"
    container_name   = "publisher"
    container_port   = 9000
  }

  lifecycle {
    ignore_changes = ["placement_strategy", "desired_count"]
  }
}

resource "aws_iam_role" "publisher" {
  name = "${var.env}_iam_for_publisher"

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

data "aws_iam_policy_document" "publisher" {
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

resource "aws_iam_role_policy" "publisher" {
  name   = "${var.env}_iam_for_publisher"
  role   = "${aws_iam_role.publisher.id}"
  policy = "${data.aws_iam_policy_document.publisher.json}"
}

resource "aws_cloudwatch_log_group" "publisher" {
  name = "${var.env}-publisher"

  tags {
    Environment = "${var.env}"
  }
}

output "publisher_address" {
  value = "https://${aws_route53_record.publisher.fqdn}"
}
