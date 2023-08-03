FROM debezium/server:2.4.0.Alpha1
MAINTAINER DLHUC

ARG DRIVER_ARTEFACT=aws-mysql-jdbc
ARG DRIVER_VERSION=1.1.9

USER root
RUN cd /debezium/lib && curl -O -J https://repo1.maven.org/maven2/software/aws/rds/aws-mysql-jdbc/$DRIVER_VERSION/$DRIVER_ARTEFACT-$DRIVER_VERSION.jar && \
    chmod 666 $DRIVER_ARTEFACT-$DRIVER_VERSION.jar