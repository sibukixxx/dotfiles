# =============================================================================
# Common Naming Module
# Generates consistent resource names following naming conventions
# =============================================================================

locals {
  # Base name components
  base_name = join(var.delimiter, compact([
    var.prefix,
    var.project,
    var.environment,
  ]))

  # Full name with optional suffix
  full_name = var.suffix != null ? join(var.delimiter, [local.base_name, var.suffix]) : local.base_name

  # Generate names for common resource types
  names = {
    # General
    default = local.full_name

    # AWS specific naming patterns
    vpc              = "${local.full_name}${var.delimiter}vpc"
    subnet           = "${local.full_name}${var.delimiter}subnet"
    security_group   = "${local.full_name}${var.delimiter}sg"
    internet_gateway = "${local.full_name}${var.delimiter}igw"
    nat_gateway      = "${local.full_name}${var.delimiter}nat"
    route_table      = "${local.full_name}${var.delimiter}rt"
    eip              = "${local.full_name}${var.delimiter}eip"

    # Compute
    ec2             = "${local.full_name}${var.delimiter}ec2"
    launch_template = "${local.full_name}${var.delimiter}lt"
    asg             = "${local.full_name}${var.delimiter}asg"

    # Containers
    ecs_cluster = "${local.full_name}${var.delimiter}cluster"
    ecs_service = "${local.full_name}${var.delimiter}svc"
    ecs_task    = "${local.full_name}${var.delimiter}task"
    eks_cluster = "${local.full_name}${var.delimiter}eks"
    ecr         = "${local.full_name}${var.delimiter}ecr"

    # Load Balancing
    alb         = "${local.full_name}${var.delimiter}alb"
    nlb         = "${local.full_name}${var.delimiter}nlb"
    target_group = "${local.full_name}${var.delimiter}tg"

    # Database
    rds      = "${local.full_name}${var.delimiter}rds"
    dynamodb = "${local.full_name}${var.delimiter}ddb"
    elasticache = "${local.full_name}${var.delimiter}cache"

    # Storage
    s3     = "${local.full_name}${var.delimiter}s3"
    efs    = "${local.full_name}${var.delimiter}efs"

    # IAM
    iam_role   = "${local.full_name}${var.delimiter}role"
    iam_policy = "${local.full_name}${var.delimiter}policy"

    # Monitoring
    cloudwatch_log_group = "/aws/${var.project}/${var.environment}"
    sns_topic           = "${local.full_name}${var.delimiter}sns"
    sqs_queue           = "${local.full_name}${var.delimiter}sqs"

    # Lambda
    lambda = "${local.full_name}${var.delimiter}lambda"

    # API Gateway
    api_gateway = "${local.full_name}${var.delimiter}api"
  }

  # Standard tags
  standard_tags = merge(var.additional_tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}
