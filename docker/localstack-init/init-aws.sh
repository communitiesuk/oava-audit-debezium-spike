#!/bin/bash

awslocal kinesis create-stream --stream-name proxy_audit_dev.proxy_application.foo --shard-count  1
awslocal kinesis create-stream --stream-name proxy_audit_dev --shard-count  1


