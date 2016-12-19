#!/bin/bash
# DDC set up with Docker Machine
echo Test $0 $1 $2
if [ "$1" == "" ]; then
	echo "Usage setup.sh <number of nodes>"
	exit 1
fi

echo "Create UCP node"
#docker-machine create -d vmwarefusion --vmwarefusion-boot2docker-url ./ubuntu-16.10-desktop-amd64.iso ucp
docker-machine create -d vmwarefusion --vmwarefusion-memory-size 4096 ucp
docker-machine ssh ucp apt-get update && apt-get upgrade -y
docker-machine ssh ucp apt-get install -y curl
docker-machine ssh ucp curl -s 'https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e' | apt-key add --import
docker-machine ssh ucp apt-get update && apt-get -y install apt-transport-https
docker-machine ssh ucp apt-get install -y linux-image-extra-virtual
docker-machine ssh ucp echo "deb https://packages.docker.com/1.12/apt/repo ubuntu-xenial main" | tee /etc/apt/sources.list.d/docker.list
docker-machine ssh ucp apt-get update && apt-get install -y docker-engine
docker-machine ssh ucp usermod -a -G docker ubuntu
docker-machine ssh ucp docker run --rm --tty --name ucp -p 8080:80 -p 4443:443 -P -v /var/run/docker.sock:/var/run/docker.sock docker/ucp install --host-address 192.168.33.10 --admin-username 'moby' --admin-password 'd!ck1234' --swarm-port 2378

echo "Get Swarm token and create vizualiser"
docker-machine ssh ucp docker swarm join-token -q worker > swarmtoken
docker-machine ssh ucp docker service create \
  --name=viz \
  --publish=8080:8080/tcp \
  --constraint=node.role==manager \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  manomarks/visualizer

echo "Create DTR node"
docker-machine create -d vmwarefusion --vmwarefusion-memory-size 3072 dtr
docker-machine ssh dtr apt-get update && apt-get upgrade -y
docker-machine ssh dtr apt-get install -y curl
docker-machine ssh dtr curl -s 'https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e' | apt-key add --import
docker-machine ssh dtr apt-get update && apt-get -y install apt-transport-https
docker-machine ssh dtr apt-get install -y linux-image-extra-virtual
docker-machine ssh dtr echo "deb https://packages.docker.com/1.12/apt/repo ubuntu-xenial main" | tee /etc/apt/sources.list.d/docker.list
docker-machine ssh dtr apt-get update && apt-get install -y docker-engine
docker-machine ssh dtr usermod -a -G docker ubuntu
docker-machine ssh dtr docker run --rm --tty --name dtr -p 80:80 -p 443:443 -P -v /var/run/docker.sock:/var/run/docker.sock docker/dtr install --ucp-url https://$(docker-machine ip ucp) --dtr-external-url https://$(docker-machine ip dtr)  --ucp-node dtr --ucp-username 'moby' --ucp-password 'd!ck1234' --ucp-insecure-tls

echo "Joining $1 nodes to Swarm cluster"
#COUNT = 0
for (( COUNT=0; COUNT < $1; COUNT++))
do
	echo "Creating node$COUNT"
	docker-machine create -d vmwarefusion --engine-label environment=ACC node$COUNT  && echo node$COUNT >> swarmnodes && docker-machine ssh node$COUNT docker swarm join --token $(cat swarmtoken) $(docker-machine ip nodemaster)
done