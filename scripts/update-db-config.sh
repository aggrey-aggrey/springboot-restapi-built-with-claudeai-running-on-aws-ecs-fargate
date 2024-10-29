# Get database endpoint from Terraform output
DB_ENDPOINT=$(terraform -chdir=terraform output -raw rds_endpoint)
DB_NAME=$(terraform -chdir=terraform output -raw db_name)

# Create application.properties with the correct database URL
cat > spring-boot-api/src/main/resources/application.properties << EOF
# Database Configuration
spring.datasource.url=jdbc:mysql://${DB_ENDPOINT}/${DB_NAME}?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}

# JPA/Hibernate Configuration
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQL8Dialect

# Server Configuration
server.port=8080

# Logging
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.type.descriptor.sql.BasicBinder=TRACE
EOF

echo "Application.properties updated with database endpoint: ${DB_ENDPOINT}"