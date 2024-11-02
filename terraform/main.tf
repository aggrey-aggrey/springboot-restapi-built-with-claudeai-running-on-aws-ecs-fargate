# terraform/main.tf

# VPC Configuration (existing)
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.app_name}-vpc-${var.environment}"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = var.environment == "dev"

  tags = merge(var.tags, {
    Environment = var.environment
    Name        = "${var.app_name}-vpc-${var.environment}"
  })
}


# RDS Instance
resource "aws_db_instance" "main" {
  identifier        = "${var.app_name}-db-${var.environment}"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = var.db_backup_retention_period
  skip_final_snapshot    = var.environment == "dev"
  final_snapshot_identifier = var.environment == "prod" ? "${var.app_name}-db-${var.environment}-final-${formatdate("YYYYMMDD-hhmmss", timestamp())}" : null

  # Enhanced monitoring - Fixed count reference
  monitoring_interval = var.environment == "prod" ? 30 : 0
  monitoring_role_arn = var.environment == "prod" ? aws_iam_role.rds_monitoring[0].arn : null

  # Performance Insights
  performance_insights_enabled = var.environment == "prod"
  performance_insights_retention_period = var.environment == "prod" ? 7 : 0

  # Maintenance window
  maintenance_window = "Mon:03:00-Mon:04:00"
  backup_window      = "02:00-03:00"

  # Storage configuration
  storage_type          = "gp3"
  storage_encrypted     = true
  iops                  = var.environment == "prod" ? 3000 : null

  # Network configuration
  multi_az             = var.environment == "prod"
  publicly_accessible  = false
  deletion_protection  = var.environment == "prod"

  tags = merge(var.tags, {
    Environment = var.environment
    Name        = "${var.app_name}-db-${var.environment}"
  })
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "${var.app_name}-rds-${var.environment}"
  description = "Security group for RDS instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "MySQL from ECS tasks"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = merge(var.tags, {
    Environment = var.environment
    Name        = "${var.app_name}-rds-sg-${var.environment}"
  })
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name        = "${var.app_name}-${var.environment}"
  description = "Database subnet group for ${var.app_name} ${var.environment}"
  subnet_ids  = module.vpc.private_subnets

  tags = merge(var.tags, {
    Environment = var.environment
    Name        = "${var.app_name}-subnet-group-${var.environment}"
  })
}

# IAM role for RDS monitoring (used in prod)
resource "aws_iam_role" "rds_monitoring" {
  count = var.environment == "prod" ? 1 : 0
  name  = "${var.app_name}-rds-monitoring-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# Fixed reference to count for policy attachment
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.environment == "prod" ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}


# ECR Repository
resource "aws_ecr_repository" "app" {
  name = "${var.app_name}-${var.environment}"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = var.environment == "prod" ? "enabled" : "disabled"
  }

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-task-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.container_cpu
  memory                  = var.container_memory
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "app"
      image = "${aws_ecr_repository.app.repository_url}:latest"

      environment = [
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = var.environment
        },
        {
          name  = "SPRING_DATASOURCE_URL"
          value = "jdbc:mysql://${aws_db_instance.main.endpoint}/${var.db_name}"
        },
        {
          name  = "SPRING_DATASOURCE_USERNAME"
          value = var.db_username
        }
      ]

      secrets = [
        {
          name      = "SPRING_DATASOURCE_PASSWORD"
          valueFrom = aws_ssm_parameter.db_password.arn
        }
      ]

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "${var.app_name}-service-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.environment == "prod" ? 2 : 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.app_name}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = module.vpc.public_subnets

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# ALB Target Group
resource "aws_lb_target_group" "app" {
  name        = "${var.app_name}-tg-${var.environment}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval           = "30"
    protocol           = "HTTP"
    matcher            = "200"
    timeout            = "3"
    path               = var.health_check_path
    unhealthy_threshold = "2"
  }

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "${var.app_name}-alb-${var.environment}"
  description = "ALB Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

resource "aws_security_group" "ecs" {
  name        = "${var.app_name}-ecs-${var.environment}"
  description = "ECS Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 8080
    to_port         = 8080
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.app_name}-${var.environment}"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# SSM Parameter for DB Password
resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.environment}/${var.app_name}/db-password"
  description = "Database password for ${var.app_name} ${var.environment}"
  type        = "SecureString"
  value       = var.db_password

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# IAM Roles
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.app_name}-execution-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.app_name}-task-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# Add SSM Parameter access to execution role
resource "aws_iam_role_policy" "ssm_access" {
  name = "ssm-access"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_ssm_parameter.db_password.arn
        ]
      }
    ]
  })
}