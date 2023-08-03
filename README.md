# oava-audit-debezium-spike

This project demonstrates the usage of debezium-server to capture change events from a database and push those
changes onto a AWS Kinesis stream.

## docker-compose stack

The entire stack can be started using the docker-compose.yml files supplied in the root of this project.

The stack consists of:
* LocalStack (This provides a AWS Kinesis endpoint)
* MySql (The source database)
* Debezium-Server (Provides Change Data Capture)


You will need to build the debezium image first (use `docker-compose build debezium`) because I have customised the Dockerfile to include the AWS Aurora driver.
This doesn't actually get picked up at the moment until we can specify the driver class name as an environment variable.
I have currently got a PR with the Debezium project to address this: https://github.com/debezium/debezium/pull/4713

## Debezium-Server

In a nutshell we have source - our mysql database and a sink - the target system, in our case Kinesis.

Debezium can run either in embedded mode or standalone server mode. Embedded mode is where you use the debezium
dependencies directly in your application code
and handle the change processing yourself. I have opted to use the debezium server in standalone mode because it
requires no code to be written. It's all based on
configuring a docker container. You get all the source and sink integration free out of the box with just a few configuration
parameters.

## Kinesis Streams

The Kinesis streams have to be created upfront for Debezium to send data to them. This is done through an environment
variable in the localstack container.

* dev_all_proxy_db_changes
* By default debezium requires a stream to publish schema DDL changes to. I have disabled this through the environment variable `DEBEZIUM_SOURCE_INCLUDE_SCHEMA_CHANGES=false`
I have used the `_dev` suffix so that we can create environment specific streams in AWS

By default, the stream naming convention must follow the properties supplied to debezium-server:
`«debezium.source.database.server.name».«debezium.source.database.dbname».«tablename»`
However, you will see I have added configuration in the docker container to use a logical mapping so that all table changes can be streamed to the same kinesis destination:

```yaml
      - DEBEZIUM_TRANSFORMS=topic.select
      - DEBEZIUM_TRANSFORMS_TOPIC_SELECT_TYPE=io.debezium.transforms.ByLogicalTableRouter
      - DEBEZIUM_TRANSFORMS_TOPIC_SELECT_TOPIC_REGEX=.*
      - DEBEZIUM_TRANSFORMS_TOPIC_SELECT_TOPIC_REPLACEMENT=dev_all_proxy_db_changes
```


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
aws-kinesis-consumer --stream-name proxy_audit_dev.proxy_application.foo  --endpoint http://localhost:24566 --iterator-type trim-horizon
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
This satisfies the day-zero requirement. When deploying against a database in the cloud e.g. RDS Aurora, Debezium needs a table level lock
on the source tables it is reading from in order to take a snapshot. Therefore it's probably best to do this out of hours.

Note: MySql server purges older binlog files and the connectors last position may be lost and it will perform another day-zero
load. Therefore we need to ensure the MySql binlog file has a high enough retention period. 

## Debezium Health
Debezium uses Quarkus and then health endpoint can be reached using http://localhost:8080/q/health

## Enable binary logging on the database
At the time of writing I have confirmed binary logging is switched off for our Aurora database in AWS. We need to enable this in order for Debezium to work.
I have confirmed this via:
```sql
SELECT variable_value as "BINARY LOGGING STATUS (log-bin) ::"
FROM performance_schema.global_variables WHERE variable_name='log_bin'
```
We would also need to think about how long we want this binary log to grow for. This is controlled by `expire_logs_days` variable in the performance_schema
above.

## Decision between Kafka and Kinesis

At the time of writing I have never used Kinesis before. My background is Kafka.
However, for this spike I decided to use Kinesis mainly because of the learning curve developers would have
to follow in order to understand kafka.

Please see more analysis here: https://www.softkraft.co/aws-kinesis-vs-kafka-comparison/#summary---which-is-right-for-you