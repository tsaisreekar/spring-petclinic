# multi-stage build
FROM maven:3.8.7-eclipse-temurin-17 as builder
WORKDIR /workspace
COPY pom.xml .
COPY src ./src
RUN mvn -B -DskipTests clean package

FROM eclipse-temurin:17-jre
ARG JAR_FILE=target/*.jar
COPY --from=builder /workspace/${JAR_FILE} /app/app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
