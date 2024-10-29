# Author-Book API Project Documentation

## Project Overview
A Spring Boot application for managing authors and books with AWS infrastructure using Terraform.

## Project Structure
```
author-book-api-project/
├── .gitignore
├── README.md
├── scripts/
│   ├── deploy.sh
│   ├── update-db-config.sh
│   ├── check-resources.sh
│   └── verify-destruction.sh
├── spring-boot-api/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/
│   │   │   │   └── com/
│   │   │   │       └── example/
│   │   │   │           └── api/
│   │   │   │               ├── AuthorBookApplication.java
│   │   │   │               ├── controller/
│   │   │   │               ├── model/
│   │   │   │               ├── repository/
│   │   │   │               ├── service/
│   │   │   │               └── config/
│   │   │   └── resources/
│   │   └── test/
│   ├── Dockerfile
│   └── pom.xml
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── backend.tf
    ├── environments/
    │   ├── dev/
    │   │   ├── terraform.tfvars
    │   │   ├── backend.tfvars
    │   │   └── secrets.tfvars
    │   └── prod/
    │       ├── terraform.tfvars
    │       ├── backend.tfvars
    │       └── secrets.tfvars
    └── modules/
```

## Key Models

### Author Model
```java
@Entity
@Table(name = "authors")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Author {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long authorId;
    @Column(nullable = false)
    private String firstName;
    @Column(nullable = false)
    private String lastName;
    private LocalDate birthDate;
    private String nationality;
    private LocalDateTime createdAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
```

### Book Model
```java
@Entity
@Table(name = "books")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Book {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long bookId;
    @Column(nullable = false)
    private String title;
    @Column(unique = true)
    private String isbn;
    private Integer publicationYear;
    private String genre;
    @Column(columnDefinition = "TEXT")
    private String description;
    private BigDecimal price;
    @ManyToMany
    @JoinTable(
        name = "book_authors",
        joinColumns = @JoinColumn(name = "book_id"),
        inverseJoinColumns = @JoinColumn(name = "author_id")
    )
    private Set authors = new HashSet<>();
}
```

## Common Operations

### Deploy Infrastructure
```bash
# Development
mvn initialize generate-resources -Pdev

# Production
mvn initialize generate-resources -Pprod
```

### Run Application
```bash
# Development
mvn spring-boot:run -Pdev

# Production
mvn spring-boot:run -Pprod \
    -Ddb.host=$DB_HOST \
    -Ddb.port=$DB_PORT \
    -Ddb.name=$DB_NAME \
    -Ddb.username=$DB_USERNAME \
    -Ddb.password=$DB_PASSWORD
```

### Destroy Infrastructure
```bash
# Development with confirmation
mvn clean -Pdev,terraform-destroy

# Force destroy (skip confirmation)
mvn clean -Pdev,terraform-destroy -Dskip.confirmation=true

# Production destroy
mvn clean -Pprod,terraform-destroy
```

## Important Notes

### Resource Management
- Always destroy development resources when not in use to reduce costs
- Verify resource destruction using the verification script
- Check AWS Console for any lingering resources

### Security
- Never commit secrets.tfvars files
- Use environment variables for sensitive data
- Keep different AWS accounts for dev and prod

### Database
- Development uses local database by default
- Production requires explicit database credentials
- Database migrations handled by JPA/Hibernate

## Infrastructure Components
- RDS MySQL database
- ECS Fargate cluster
- Application Load Balancer
- VPC with public/private subnets
- ECR repository

## Cost Management
- Resources tagged by environment
- Cost alerts enabled
- Automatic cleanup of unused resources
- Spot instances used where possible

## Useful Commands

### Check Resources
```bash
./scripts/check-resources.sh dev us-west-2
```

### Verify Destruction
```bash
./scripts/verify-destruction.sh dev us-west-2
```

### Update Database Config
```bash
./scripts/update-db-config.sh dev
```