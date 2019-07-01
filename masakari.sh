#!/bin/bash
#
# Copyright 2019 vishnu <vishnukb@acceleronlabs.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
# Author: vishnu
# 
# openstack masakari installation script
# usage ./masakari.sh
#
# Version
version=16.00

# Keep track of the mdcMasakari directory
TOP_DIR=$(cd $(dirname "$0") && pwd)

# Keep track to the modules directory
MODULES="$TOP_DIR/modules"

# Including the necessary scripts
source $MODULES/run

#main routine
result=0

#VERSION_CHECK $version
# Starts the installation...
START

# Script run state 1
RUN_STATE 1

# Script run state 2
RUN_STATE 2

# Script run state 3
RUN_STATE 3

# End the installation...
END

#end
# new version
