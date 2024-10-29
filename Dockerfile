# Build stage
FROM maven:3.8.4-openjdk-17-slim AS build
WORKDIR /app
COPY pom.xml .
# Download dependencies
RUN mvn dependency:go-offline

COPY src/ /app/src/
RUN mvn clean package -DskipTests

# Runtime stage
FROM openjdk:17-slim
WORKDIR /app

# Add non-root user
RUN addgroup --system springboot && adduser --system springboot --ingroup springboot
USER springboot:springboot

# Copy built artifact from build stage
COPY --from=build /app/target/*.jar app.jar

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Container configuration
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]