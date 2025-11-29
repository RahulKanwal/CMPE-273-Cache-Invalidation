FROM eclipse-temurin:21-jdk-jammy

WORKDIR /app

# Copy Maven files
COPY pom.xml .
COPY src ./src

# Install Maven
RUN apt-get update && apt-get install -y maven

# Build the application
RUN mvn clean package -DskipTests

# Expose port
EXPOSE 8082

# Run the application
CMD ["java", "-jar", "target/order-service-1.0.0.jar"]