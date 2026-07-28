# Multi-stage build: compile with Maven, ship only the built jar + a slim JRE.
# Works identically on Render, Cloud Run, or any other Docker-based host.

FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
# Cache dependencies in their own layer — only re-downloads when pom.xml changes.
RUN mvn -B dependency:go-offline
COPY src ./src
RUN mvn -B -q package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

# Render (and most PaaS hosts) inject PORT at runtime; application.yml already
# reads server.port from ${SERVER_PORT:8080}, so this covers both.
ENV SERVER_PORT=8080
EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java -jar app.jar --server.port=${PORT:-$SERVER_PORT}"]
