#!/bin/bash
apt-packages=(python-pip python3-pip libvirt-dev python-dev python3-dev gcc make)
pip-packages=()
sizeOfAptPack=${#apt-packages[@]}
sizeOfPipPack=${#pip-packages[@]}
function apt-install {
  local n=0
  while [ $n -lt $sizeOfAptPack ];do
    echo "+-- sudo apt-get install ${sizeOfAptPack[$n]} -y"
    sudo apt-get install ${sizeOfAptPack[$n]} -y
    n=` expr $n + 1 `
  done
}
function pip-install {
  local n=0
  while [ $n -lt $sizeOfPipPack ];do
    echo "+-- sudo apt-get install ${sizeOfAptPack[$n]} -y"
    sudo apt-get install ${sizeOfAptPack[$n]} -y
    n=` expr $n + 1 `
  done
}
sudo apt install python-pip -y
sudo apt install python3-pip -y
sudo apt-get install libvirt-dev -y
sudo apt-get install libpq-dev -y
sudo apt-get install python-dev -y
sudo apt-get install gcc -y
sudo apt-get install python3-dev -y

sudo pip install tox
sudo pip3 install tox
sudo pip install oslo_policy
sudo pip install oslo_db
sudo pip install sqlalchemy
sudo pip install flask_sqlalchemy
sudo pip install Flask-SQLAlchemy
sudo pip install oslo.service

