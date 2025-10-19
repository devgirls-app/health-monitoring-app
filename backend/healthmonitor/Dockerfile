# Use a standard Temurin JDK 17 image (works on ARM & x86)
FROM eclipse-temurin:21-jdk

# Set working directory
WORKDIR /app

# Copy built jar into the container
COPY target/healthmonitor-0.0.1-SNAPSHOT.jar app.jar

# Expose the port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java","-jar","app.jar"]
