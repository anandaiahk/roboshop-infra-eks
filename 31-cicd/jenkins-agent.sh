#!/bin/bash

growpart /dev/nvme0n1 4
lvextend -L +10G /dev/mapper/RootVG-rootVol
lvextend -L +10G /dev/mapper/RootVG-homeVol
lvextend -L +10G /dev/mapper/RootVG-varVol

xfs_growfs /var
xfs_growfs /home
xfs_growfs /

# Java
yum install fontconfig java-21-openjdk -y

dnf module enable nodejs:20 -y
dnf install nodejs -y

# Docker
dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user