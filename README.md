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

## Deployment

1. Configure AWS credentials:
```bash
aws configure
```

2. Deploy to development:
```bash
./scripts/deploy.sh dev
```

3. Deploy to production:
```bash
./scripts/deploy.sh prod
```

## Infrastructure

The infrastructure includes:
- RDS MySQL database
- ECS Fargate cluster
- Application Load Balancer
- VPC with public/private subnets
- ECR repository

## Testing

Run tests:
```bash
cd spring-boot-api
mvn test
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
Last edited 5 hours ago