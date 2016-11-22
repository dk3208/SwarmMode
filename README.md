# SwarmMode
Setting up a Docker Swarm mode cluster with RancherOS nodes and Docker Machine

setupswarm <number of nodes> : creates <number of nodes> RancherOS VMs and a single Swarm mode master (also based on RancherOS).
The script first downloads the RancherOS ISO, if there is not already one available, or the online version is newer.
It then creates the Swarm master, remembers the join token, then creates the required amount of worker nodes and each joins them to the Swarm master.

