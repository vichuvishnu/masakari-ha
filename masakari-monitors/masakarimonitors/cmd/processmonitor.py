# Copyright(c) 2016 Nippon Telegraph and Telephone Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Starter script for Masakari Process Monitor."""

import sys

from oslo_log import log as logging

import masakarimonitors.conf
from masakarimonitors import config
from masakarimonitors import service
from masakarimonitors import utils


CONF = masakarimonitors.conf.CONF


def main():
    config.parse_args(sys.argv)
    logging.setup(CONF, "masakarimonitors")
    utils.monkey_patch()

    server = service.Service.create(binary='masakarimonitors-processmonitor')
    service.serve(server)
    service.wait()
