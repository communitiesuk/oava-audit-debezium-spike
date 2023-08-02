FROM debezium/server:2.3.0.Final
MAINTAINER DLHUC

USER root
COPY debezium-init/aws-mysql-jdbc-1.1.8.jar /debezium/lib
RUN chmod 666 /debezium/lib/aws-mysql-jdbc-1.1.8.jar