resource "aws_alb_target_group" "author-api" {
  name     = "${var.env}-author-api"
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

resource "aws_alb_listener_rule" "author-api" {
  listener_arn = "${data.aws_lb_listener.eq.id}"
  priority     = 202

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.author-api.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${aws_route53_record.author-api.name}"]
  }
}

resource "aws_route53_record" "author-api" {
  zone_id = "${data.aws_route53_zone.dns_zone.id}"
  name    = "${var.env}-author-api.${var.dns_zone_name}"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.eq.dns_name}"
    zone_id                = "${data.aws_lb.eq.zone_id}"
    evaluate_target_health = false
  }
}

data "template_file" "author-api" {
  template = "${file("${path.module}/task-definitions/author-api.json")}"

  vars {
    LOG_GROUP          = "${aws_cloudwatch_log_group.author-api.name}"
    CONTAINER_REGISTRY = "${var.docker_registry}"
    CONTAINER_TAG      = "${var.author_api_tag}"
    DB_CONNECTION_URI  = "postgres://author:${var.author_database_password}@${aws_db_instance.author_database.address}:${aws_db_instance.author_database.port}/author"
  }
}

resource "aws_ecs_task_definition" "author-api" {
  family                = "${var.env}-author-api"
  container_definitions = "${data.template_file.author-api.rendered}"
}

resource "aws_ecs_service" "author-api" {
  depends_on = [
    "aws_alb_target_group.author-api",
    "aws_alb_listener_rule.author-api",
  ]

  name            = "${var.env}-author-api"
  cluster         = "${data.aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.author-api.family}"
  desired_count   = "${var.author_api_min_tasks}"
  iam_role        = "${aws_iam_role.author-api.arn}"

  placement_strategy {
    type  = "spread"
    field = "host"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.author-api.arn}"
    container_name   = "author-api"
    container_port   = 4000
  }

  lifecycle {
    ignore_changes = ["placement_strategy", "desired_count"]
  }
}

resource "aws_iam_role" "author-api" {
  name = "${var.env}_iam_for_author_api"

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

data "aws_iam_policy_document" "author-api" {
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

resource "aws_iam_role_policy" "author-api" {
  name   = "${var.env}_iam_for_author_api"
  role   = "${aws_iam_role.author-api.id}"
  policy = "${data.aws_iam_policy_document.author-api.json}"
}

resource "aws_cloudwatch_log_group" "author-api" {
  name = "${var.env}-author-api"

  tags {
    Environment = "${var.env}"
  }
}

output "author_api_address" {
  value = "https://${aws_route53_record.author-api.fqdn}"
}
