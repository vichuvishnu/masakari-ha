#!/bin/bash
apt-packages=(python-pip python3-pip libvirt-dev python-dev python3-dev gcc make)
pip-packages=(tox oslo_policy oslo_db sqlalchemy flask_sqlalchemy Flask-SQLAlchemy oslo.service)
sizeOfAptPack=${#apt-packages[@]}
sizeOfPipPack=${#pip-packages[@]}
function apt-install {
  local n=0
  while [ $n -lt $sizeOfAptPack ];do
    echo "+-- sudo apt-get install ${apt-packages[$n]} -y"
    sudo apt-get install ${sizeOfAptPack[$n]} -y
    n=` expr $n + 1 `
  done
}
function pip-install {
  local n=0
  while [ $n -lt $sizeOfPipPack ];do
    echo "+-- sudo pip install ${pip-packages[$n]}"
    sudo pip install ${pip-packages[$n]}
    n=` expr $n + 1 `
  done
}
function installed-packages {
  echo "${apt-packages}"
  echo "${pip-packages}"
}

apt-install

pip-install

installed-packages
