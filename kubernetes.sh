#!/bin/bash

#This script installs Docker and Kubernetes for master and agents
#Ubuntu 18.04 Bionic Beaver LTS
#-m: master node - no options for agents

while [ True ]; do
if [ "$1" = "--master" -o "$1" = "-m" ]; then
    MASTER=1
    shift 1
else
    break
fi
done


###Docker installation###

#Add the Docker repository GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

#Add the Docker repository
sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable"

#Reload the apt source list
sudo apt-get update

#Install Docker
sudo apt-get install -y docker-ce=18.06.1~ce~3-0~ubuntu

#Prevent auto-updates for the Docker package
sudo apt-mark hold docker-ce

###Kubernetes installation###
##Kubeadm: this tool automates a large portion of the process of setting up a cluster.
##Kubelet: the essential component of Kubernetes that handles running containers on a node. Every server that will be running containers needs kubelet.
##Kubectl: Command-line tool for interacting with the cluster once it is up.

#Add the Kubernetes repository GPG key
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

#Add the Kubernetes repository
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

#Reload the apt sources list
sudo apt-get update

#Install packages
sudo apt-get install -y kubelet=1.15.7-00 kubeadm=1.15.7-00 kubectl=1.15.7-00

#Prevent auto-updates for the kube packages
sudo apt-mark hold kubelet kubeadm kubectl

###Bootstrap the cluster###
#Initialize the cluter on the master only
if [MASTER=1]
then
    #Initialize the cluster on the Kube Master server
    #The special pod network CIDR is a setting that will be needed later for flannel networking plugin
	sudo kubeadm init --pod-network-cidr=10.244.0.0/16

    #Setup kubeconfig for the local user on the Kube Master server. This will allow to use the Kubectl when logged in to the master,
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    #Configuring networking with flannel

    #Get join
    #kubeadm token create --print-join-command
fi

#Configuring networking with flannel
#Turn on net.bridge-nf-call-iptables in all nodes
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

#Install flannel in the master
if[MASTER=1]
then
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
fi
echo "-----------DONE-----------"