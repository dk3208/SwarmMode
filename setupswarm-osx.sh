#!/bin/bash
echo Test $0 $1 $2
if [ "$1" == "" ]; then
	echo "Usage setup.sh <number of nodes>"
	exit 1
fi

#echo Downloading RancherOS ISO
# TODO: check whether curl or wget is available
#wget -N https://releases.rancher.com/os/latest/rancheros.iso
curl -O https://releases.rancher.com/os/latest/rancheros.iso
echo "Creating Master and $1 nodes"
docker-machine create -d virtualbox --virtualbox-boot2docker-url ./rancheros.iso nodemaster && echo nodemaster >> swarmnodes

echo Set up Master
docker-machine ssh nodemaster docker swarm init --advertise-addr $(docker-machine ip nodemaster)
echo "Getting swarm token"
docker-machine ssh nodemaster docker swarm join-token -q worker > swarmtoken

echo "Start Visualizer @ nodemaster"
docker-machine ssh nodemaster docker service create \
  --name=viz \
  --publish=8090:8080/tcp \
  --constraint=node.role==manager \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  manomarks/visualizer

echo "Joining $1 nodes to Swarm cluster"
#COUNT = 0
for (( COUNT=0; COUNT < $1; COUNT++))
do
	echo "Creating node$COUNT"
	docker-machine create -d virtualbox --virtualbox-boot2docker-url ./rancheros.iso node$COUNT  && echo node$COUNT >> swarmnodes && docker-machine ssh node$COUNT docker swarm join --token $(cat swarmtoken) $(docker-machine ip nodemaster)
done

echo "All set"
docker-machine ssh nodemaster docker node ls
