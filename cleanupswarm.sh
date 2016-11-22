#!/bin/bash
echo Deleting existing Docker Machines
docker-machine rm -y $(cat swarmnodes)
rm swarmnodes
rm swarmtoken
