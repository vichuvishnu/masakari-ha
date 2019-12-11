#!/bin/bash
rd=`tput setaf  1`
gr=`tput setaf  2`
yl=`tput setaf  3`
rs=`tput sgr0`
COLUMNS=`tput cols`
aptPackages=(python-pip python3-pip libvirt-dev python-dev python3-dev gcc make)
pipPackages=(tox oslo_policy oslo_db sqlalchemy flask_sqlalchemy Flask-SQLAlchemy oslo.service)
sizeOfAptPack=${#aptPackages[@]}
sizeOfPipPack=${#pipPackages[@]}
function drawSummary {
  size=$(((COLUMNS/2)-4))
  printf "%*s" $size| tr " " "_"
  printf " summary "
  printf "%*s" $size| tr " " "_"
}
function die {
   drawSummary
   echo "${rd} $1 package installation failed"
   echo "Installation exist :-(${rs}"
   exit 0
}
function apt-install {
  local n=0
  while [ $n -lt $sizeOfAptPack ];do
    echo "${yl}+-- Installing ${aptPackages[$n]}${rs}"
    sudo apt-get install ${aptPackages[$n]} -y ; local stat=$?
    if [ $stat -ne 0 ];then
       die ${sizeOfAptPack[$n]}
    fi
    n=` expr $n + 1 `
  done
}
function pip-install {
  local n=0
  while [ $n -lt $sizeOfPipPack ];do
    echo "${yl}+-- Installing ${pipPackages[$n]}${rs}"
    sudo pip install ${pipPackages[$n]} ; local stat=$?
    if [ $stat -ne 0 ];then
       die ${sizeOfAptPack[$n]}
    fi
    n=` expr $n + 1 `
  done
}
function installed-packages {
  drawSummary
  echo "${gr} ./requirement.sh"
  echo "Required Package Installation success :-)${rs}"
  echo "$(tput bold)${aptPackages[@]}"
  echo "${pipPackages[@]}$(tput sgr0)"
}
#main
apt-install
pip-install
installed-packages
