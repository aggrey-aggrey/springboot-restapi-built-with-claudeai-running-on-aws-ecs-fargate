# Author Book API Project

A Spring Boot application for managing authors and books with AWS infrastructure using Terraform.

## Project Structure

The project is organized into three main components:
- Spring Boot API
- Terraform Infrastructure
- Deployment Scripts

## Prerequisites

- Java 17
- Maven 3.8+
- Docker
- AWS CLI
- Terraform 1.0+
- MySQL (for local development)

## Local Development

1. Start local MySQL:
```bash
docker run --name mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=authordb -p 3306:3306 -d mysql:8
```

2. Run the application:
```bash
cd spring-boot-api
mvn spring-boot:run -Pdev
```

## 3. Infrastructure Deployment

```bash
# Setup AWS backend infrastructure (S3 bucket and DynamoDB for state)
./scripts/setup-aws.sh dev

# Initialize Terraform with backend
./scripts/tf.sh dev init

# Plan infrastructure changes
./scripts/tf.sh dev plan

# Apply infrastructure
./scripts/tf.sh dev apply
```

## 4. Application Deployment
```bash
# Build and push Docker image to ECR
./scripts/docker-build-push.sh dev

# Verify ECS deployment
./scripts/troubleshooting-ecs.sh
```

## 5. Verification
```bash
# Test API endpoints
./scripts/test-api.sh dev
```

## Common Operations

### Update Application
```bash
# Build and deploy new version
./scripts/docker-build-push.sh dev

# Verify deployment
./scripts/troubleshooting-ecs.sh
```

### Infrastructure Changes
```bash
# Plan changes
./scripts/tf.sh dev plan

# Apply changes
./scripts/tf.sh dev apply
```

### Resource Cleanup
```bash
# Remove all infrastructure (except RDS)
./scripts/cleanup.sh dev
```

## Environment-Specific Deployments

### Development Environment
```bash
# Deploy to dev
./scripts/tf.sh dev init
./scripts/tf.sh dev plan
./scripts/tf.sh dev apply
./scripts/docker-build-push.sh dev
```

### Production Environment
```bash
# Deploy to prod
./scripts/tf.sh prod init
./scripts/tf.sh prod plan
./scripts/tf.sh prod apply
./scripts/docker-build-push.sh prod
```

## Troubleshooting Steps

### Application Issues
```bash
# Check ECS service status
./scripts/troubleshooting-ecs.sh

# View application logs
aws logs tail /ecs/author-books-api-dev --follow
```

### Infrastructure Issues
```bash
# Verify current state
./scripts/tf.sh dev plan

# Apply fixes if needed
./scripts/tf.sh dev apply
```
## Important Notes

1. **Database Management**
   - Database is managed manually through AWS Console
   - Keep database credentials secure
   - Update application properties if database details change

2. **Order of Operations**
   - Database must be created and configured before application deployment
   - Infrastructure must be deployed before application
   - Always verify database connectivity before deploying application

3. **Security Considerations**
   - Keep secrets.tfvars files secure and never commit to version control
   - Regularly rotate database passwords
   - Monitor security group rules

4. **Backup Considerations**
   - Setup database backups in AWS Console
   - Consider taking snapshots before major changes

## Complete Deployment Example
```bash
# 1. Initial setup
chmod +x scripts/*

# 2. Create and configure database in AWS Console
# (Manual step using AWS Console and MySQL client)

# 3. Update environment files with database details
# Edit: environments/dev/terraform.tfvars
# Edit: environments/dev/secrets.tfvars

# 4. Deploy infrastructure
./scripts/setup-aws.sh dev
./scripts/tf.sh dev init
./scripts/tf.sh dev plan
./scripts/tf.sh dev apply

# 5. Deploy application
./scripts/docker-build-push.sh dev
./scripts/troubleshooting-ecs.sh

# 6. Verify deployment
./scripts/test-api.sh dev
```

## Infrastructure

The infrastructure includes:
- RDS MySQL database
- ECS Fargate cluster
- Application Load Balancer
- VPC with public/private subnets
- ECR repository
- S3
- Dyanamo DB

## Testing

Run tests:
```bash
cd spring-boot-api
mvn test
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
Last edited 5 hours ago
