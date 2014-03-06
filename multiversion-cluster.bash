#!/bin/bash

echo "\nStarting cluster members\n"

## This starts up a multiversion cluster with 2 shards
## NOTE this will remove the existing data directory
rm -rf /data/db/c1

mkdir /data/db/c1
mkdir /data/db/c1/mongod1
mkdir /data/db/c1/mongod2
mkdir /data/db/c1/config

mongod-2.4 --port 29001 --replSet "c1a" --dbpath /data/db/c1/mongod1 --logpath /data/db/c1/1.log --logappend &
mongod-2.6 --port 29002 --replSet "c1b" --dbpath /data/db/c1/mongod2 --logpath /data/db/c1/2.log --logappend &
mongod-2.6 --port 29003 --configsvr --dbpath /data/db/c1/config --logpath /data/db/c1/c.log --logappend &
sleep 5

## Initialize replica sets (just one member in each)
mongo --port 29001 --eval "rs.initiate({ '_id':'c1a', members:[{ '_id':0, 'host':'localhost:29001'}]});" > /dev/null
mongo --port 29002 --eval "rs.initiate({ '_id':'c1b', members:[{ '_id':1, 'host':'localhost:29002'}]});" > /dev/null
echo "Waiting for c1 replica sets to initalize"
sleep 10

## Start mongos
echo "Starting mongos"
mongos-2.6 --port 29000 --configdb "localhost:29003" --logpath /data/db/c1/s.log --logappend &
sleep 3

## Add shards, and shard one collection
echo "Adding shards"
mongo --port 29000 --eval "db.adminCommand({addShard: \"c1a/localhost:29001\"});db.adminCommand({addShard: \"c1b/localhost:29002\"});"
echo "Sharding db and collection"
mongo --port 29000 --eval "sh.enableSharding('ruby');sh.shardCollection('ruby.agg', { a:1 }, false);"


