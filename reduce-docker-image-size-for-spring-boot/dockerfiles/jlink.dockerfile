FROM adoptopenjdk/openjdk16:alpine as build

# Build JDK with less modules
RUN $JAVA_HOME/bin/jlink \
    --compress=2 \
    --module-path $JAVA_HOME/jmods \
    --add-modules java.base,java.logging,java.xml,jdk.unsupported,java.sql,java.naming,java.desktop,java.management,java.security.jgss,java.instrument \
    --output /jdk-minimal

# Fetching maven dependencies
WORKDIR /build
COPY .mvn .mvn
COPY pom.xml mvnw ./
RUN ./mvnw dependency:go-offline

# Build maven application
COPY src src
RUN ./mvnw clean package

#---------------------------------
FROM alpine:3.14.0

# Set language
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# Get result from build stage
COPY --from=build /build/target/*.jar /app.jar
COPY --from=build /jdk-minimal /opt/jdk/

# Set envs
ENV JAVA_HOME /opt/jdk/
ENV JAVA_OPTS "-Xms256m -Xmx521m"

# Run application
VOLUME /tmp
ENTRYPOINT echo "JAVA OPTS > " $JAVA_OPTS && \
    $JAVA_HOME/bin/java $JAVA_OTS \
    "-XX:+UseContainerSupport" "-XX:MaxRAMPercentage=75.0" "-XX:MinRAMPercentage=10.0" \
    "-jar" "/app.jar"

USER 65532