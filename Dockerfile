FROM openjdk:8u131-jre-alpine

EXPOSE 9324

COPY custom.conf /
ADD https://s3-eu-west-1.amazonaws.com/softwaremill-public/elasticmq-server-0.13.8.jar /

CMD ["/usr/bin/java", "-Dconfig.file=custom.conf", "-jar", "/elasticmq-server-0.13.8.jar"]
