# eq-author-deploy

This repository holds the code that is responsible for deploying [Author](https://github.com/ONSdigital/eq-author) [Author API](https://github.com/ONSdigital/eq-author-api) and [Publisher](https://github.com/ONSdigital/eq-publisher)

These terraform scripts are used to deploy the Author Docker images to an AWS ECS cluster.

To deploy Author, add the following module to your terraform scripts

```
module "author" {
  source                  = "github.com/ONSdigital/eq-author-deploy"
  env                     = "${var.env}"
  aws_access_key          = "${var.aws_access_key}"
  aws_secret_key          = "${var.aws_secret_key}"
  dns_zone_name           = "${var.dns_zone_name}"
  ecs_cluster_name        = "${module.eq-ecs.ecs_cluster_name}"
  aws_alb_listener_arn    = "${module.eq-ecs.aws_alb_listener_arn}"
  application_cidrs       = "${var.application_cidrs}"
  survey_launcher_url     = "${module.survey-launcher-for-ecs.survey_runner_launcher_address}"
  schema_validator_url    = "${module.schema-validator-for-ecs.schema_validator_address}"
}
```
