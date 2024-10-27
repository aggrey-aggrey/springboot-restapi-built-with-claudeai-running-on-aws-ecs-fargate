FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Copy the JAR file
COPY target/*.jar app.jar

# Expose the port your application runs on
EXPOSE 8080

# Command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]