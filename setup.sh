#!/bin/bash
echo Downloading RancherOS ISO
wget -N https://releases.rancher.com/os/latest/rancheros.iso
echo Creating Master and 6 nodes
docker-machine create -d virtualbox --virtualbox-boot2docker-url ./rancheros.iso ranchermaster && echo ranchermaster >> swarmnodes
docker-machine create -d virtualbox --virtualbox-boot2docker-url ./rancheros.iso ranchernode0  && echo ranchernode0 >> swarmnodes
docker-machine create -d virtualbox --virtualbox-boot2docker-url ./rancheros.iso ranchernode1  && echo ranchernode1 >> swarmnodes
docker-machine create -d virtualbox --virtualbox-boot2docker-url ./rancheros.iso ranchernode2  && echo ranchernode2 >> swarmnodes
docker-machine create -d virtualbox --virtualbox-boot2docker-url ./rancheros.iso ranchernode3  && echo ranchernode3 >> swarmnodes
docker-machine create -d virtualbox --virtualbox-boot2docker-url ./rancheros.iso ranchernode4  && echo ranchernode4 >> swarmnodes
docker-machine create -d virtualbox --virtualbox-boot2docker-url ./rancheros.iso ranchernode5  && echo ranchernode5 >> swarmnodes

echo Set up Master
docker-machine ssh ranchermaster docker swarm init --advertise-addr $(docker-machine ip ranchermaster)
echo Getting swarm token
docker-machine ssh ranchermaster docker swarm join-token -q worker > swarmtoken

echo Joining nodes to Swarm cluster
docker-machine ssh ranchernode0 docker swarm join --token $(cat swarmtoken) $(docker-machine ip ranchermaster)
docker-machine ssh ranchernode1 docker swarm join --token $(cat swarmtoken) $(docker-machine ip ranchermaster)
docker-machine ssh ranchernode2 docker swarm join --token $(cat swarmtoken) $(docker-machine ip ranchermaster)
docker-machine ssh ranchernode3 docker swarm join --token $(cat swarmtoken) $(docker-machine ip ranchermaster)
docker-machine ssh ranchernode4 docker swarm join --token $(cat swarmtoken) $(docker-machine ip ranchermaster)
docker-machine ssh ranchernode5 docker swarm join --token $(cat swarmtoken) $(docker-machine ip ranchermaster)

echo All set
docker-machine ssh ranchermaster docker node ls
