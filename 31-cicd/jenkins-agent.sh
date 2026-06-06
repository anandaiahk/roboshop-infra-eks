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