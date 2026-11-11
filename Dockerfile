FROM maven:3.9.12-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY . .
ENV MAVEN_OPTS="-Xmx256m"
RUN mvn -B -DskipTests package
ARG SERVICE
RUN cp "${SERVICE}/target/${SERVICE}-"*.jar /app.jar

FROM eclipse-temurin:21-jre-jammy
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 10001 app \
    && useradd -u 10001 -g app app
WORKDIR /app
COPY --from=build /app.jar app.jar
RUN mkdir -p /app/data/auth-keys && chown -R app:app /app
USER app
ENTRYPOINT ["java", "-jar", "app.jar"]
