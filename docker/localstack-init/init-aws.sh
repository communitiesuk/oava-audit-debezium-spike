#!/bin/bash

awslocal kinesis create-stream --stream-name proxy_audit.proxy_application.foo --shard-count  1
awslocal kinesis create-stream --stream-name proxy_audit --shard-count  1


