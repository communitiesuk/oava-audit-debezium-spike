# oava-audit-debezium-spike

This project demonstrates the usage of debezium-server to capture change events from a database and push those
changes onto a AWS Kinesis stream.

## docker-compose stack

The entire stack can be started using the docker-compose.yml files supplied in the root of this project.

The stack consists of:
* LocalStack (This provides a AWS Kinesis endpoint)
* MySql (The source database)
* Debezium-Server (Provides Change Data Capture)

Note: When starting up the containers using `docker-compose up`, Debezium-Server will fail to start initially
because it needs the MySql database and the Kinesis stream to ready first. Therefore once the services have started
you can run `docker-compose up -d` in another window and it will start up Debezium-Server.

## Debezium-Server

In a nutshell we have source - our mysql database and a sink - the target system, in our case Kinesis.

Debezium can run either in embedded mode or standalone server mode. Embedded mode is where you use the debezium
dependencies directly in your application code
and handle the change processing yourself. I have opted to use the debezium server in standalone mode because it
requires no code to be written. It's all based on
configuring a docker container. You get all the source and sink integration free out of the box with just a few configuration
parameters.

## Kinesis Streams

The Kinesis streams have to be created upfront for Debezium to send data to them. This is done
[here](docker/localstack-init/init-aws.sh).
You will notice 2 streams that are set up:

* proxy_audit_dev.proxy_application.foo (This is for the changes to the foo table. We will need 1 stream per table)
* proxy_audit_dev (This is for any schema DDL changes)

I have used the `_dev` suffix so that we can create environment specific streams in AWS

The stream naming convention must follow the properties supplied to debezium-server:
`«debezium.source.database.server.name».«debezium.source.database.dbname».«tablename»`

Table name refactors will have to take these dependencies into account. However I believe there is a way where you can
have the stream name to be independent of the table name but I have not had time to look into it yet.


### Inspecting the Kinesis stream

You will need a kinesis consumer. I have found this tool the easiest to
use: https://pypi.org/project/aws-kinesis-consumer/
Once you have installed that you set up the following environment variables to point the local-stack kinesis deployment:

```shell
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
```

```shell
aws-kinesis-consumer --stream-name proxy_audit.proxy_application.foo  --endpoint http://localhost:24566 --iterator-type trim-horizon
```

We use the `--iterator-type trim-horizon` iterator type since we want to start reading from the start of the stream.

Next, you can post some database inserts, updates and deletes to the `foo` table in the database and you will see the
change events in your kinesis consumer.

### Format of change events

A change event looks something like this:

```json
{
  "schema": {
    "type": "struct",
    "fields": [
      {
        "type": "struct",
        "fields": [
          {
            "type": "string",
            "optional": false,
            "field": "id"
          },
          {
            "type": "string",
            "optional": false,
            "field": "first_name"
          }
        ],
        "optional": true,
        "name": "proxy_audit.proxy_application.foo.Value",
        "field": "before"
      },
      {
        "type": "struct",
        "fields": [
          {
            "type": "string",
            "optional": false,
            "field": "id"
          },
          {
            "type": "string",
            "optional": false,
            "field": "first_name"
          }
        ],
        "optional": true,
        "name": "proxy_audit.proxy_application.foo.Value",
        "field": "after"
      },
      {
        "type": "struct",
        "fields": [
          {
            "type": "string",
            "optional": false,
            "field": "version"
          },
          {
            "type": "string",
            "optional": false,
            "field": "connector"
          },
          {
            "type": "string",
            "optional": false,
            "field": "name"
          },
          {
            "type": "int64",
            "optional": false,
            "field": "ts_ms"
          },
          {
            "type": "string",
            "optional": true,
            "name": "io.debezium.data.Enum",
            "version": 1,
            "parameters": {
              "allowed": "true,last,false,incremental"
            },
            "default": "false",
            "field": "snapshot"
          },
          {
            "type": "string",
            "optional": false,
            "field": "db"
          },
          {
            "type": "string",
            "optional": true,
            "field": "sequence"
          },
          {
            "type": "string",
            "optional": true,
            "field": "table"
          },
          {
            "type": "int64",
            "optional": false,
            "field": "server_id"
          },
          {
            "type": "string",
            "optional": true,
            "field": "gtid"
          },
          {
            "type": "string",
            "optional": false,
            "field": "file"
          },
          {
            "type": "int64",
            "optional": false,
            "field": "pos"
          },
          {
            "type": "int32",
            "optional": false,
            "field": "row"
          },
          {
            "type": "int64",
            "optional": true,
            "field": "thread"
          },
          {
            "type": "string",
            "optional": true,
            "field": "query"
          }
        ],
        "optional": false,
        "name": "io.debezium.connector.mysql.Source",
        "field": "source"
      },
      {
        "type": "string",
        "optional": false,
        "field": "op"
      },
      {
        "type": "int64",
        "optional": true,
        "field": "ts_ms"
      },
      {
        "type": "struct",
        "fields": [
          {
            "type": "string",
            "optional": false,
            "field": "id"
          },
          {
            "type": "int64",
            "optional": false,
            "field": "total_order"
          },
          {
            "type": "int64",
            "optional": false,
            "field": "data_collection_order"
          }
        ],
        "optional": true,
        "name": "event.block",
        "version": 1,
        "field": "transaction"
      }
    ],
    "optional": false,
    "name": "proxy_audit.proxy_application.foo.Envelope",
    "version": 1
  },
  "payload": {
    "before": null,
    "after": {
      "id": "267b492c-6040-4b6e-8b59-8f59b3e16f67",
      "first_name": "bar"
    },
    "source": {
      "version": "2.3.0.Final",
      "connector": "mysql",
      "name": "proxy_audit",
      "ts_ms": 1689941576000,
      "snapshot": "last",
      "db": "proxy_application",
      "sequence": null,
      "table": "foo",
      "server_id": 0,
      "gtid": null,
      "file": "binlog.000002",
      "pos": 501,
      "row": 0,
      "thread": null,
      "query": null
    },
    "op": "r",
    "ts_ms": 1689941576609,
    "transaction": null
  }
}
```

There are 2 sections - schema and payload. the Payload section is the part that tells you what the value of the database
row as before and after. In the example above this was a read operation as indicated by `"op": "r"`. This represents the
initial
read debezium did of the database and found 1 pre-existing row which it read.

## Offset and history files

Debezium maintains a offset i.e a pointer in the database log that lets it track what change events it has already
processed.
When you deploy Debezium against a new database, this offset does not exist so it reads everything and then marks its
offset after all events are processed.

Debezium also maintains a log of schema history. Both offset and history information needs to be persistent

In this POC I have used a file based storage mechanism. You will see the offset and history dat files mounted in a
docker volume [here](docker/volumes/debezium/data)

The following options are available for storage:

|         | File | Kafka | Azure blob | Redis | S3  | JDBC | Rocket MQ |
|---------|------|-------|------------|-------|-----|------|-----------|
| Offset  | YES  | YES   | NO         | YES   | NO  | YES  | NO        |
| History | YES  | YES   | YES        | YES   | YES | YES  | YES       |

If using a File based storage mechanism, we could store the file in an EFS volume.

## Initial snapshot
When Debezium starts up and has never committed an offset, it will read all data from the database and commit a new offset.
This satisfies the day-zero requirement.

Note: MySql server purges older binlog files and the connectors last position may be lost and it will perform another day-zero
load. Therefore we need to ensure the MySql binlog file has a high enough retention period. 

## Decision between Kafka and Kinesis

At the time of writing I have never used Kinesis before. My background is Kafka.
However, for this spike I decided to use Kinesis mainly because of the learning curve developers would have
to follow in order to understand kafka.

Please see more analysis here: https://www.softkraft.co/aws-kinesis-vs-kafka-comparison/#summary---which-is-right-for-you