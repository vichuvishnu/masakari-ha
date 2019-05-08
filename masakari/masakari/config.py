# Copyright 2016 NTT DATA
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
from oslo_log import log

from masakari.common import config
import masakari.conf
from masakari.db.sqlalchemy import api as sqlalchemy_api
from masakari import rpc
from masakari import version


CONF = masakari.conf.CONF


def parse_args(argv, default_config_files=None, configure_db=True,
               init_rpc=True):
    log.register_options(CONF)
    # We use the oslo.log default log levels which includes suds=INFO
    # and add only the extra levels that Masakari needs
    log.set_defaults(default_log_levels=log.get_default_log_levels())
    rpc.set_defaults(control_exchange='masakari')
    config.set_middleware_defaults()

    CONF(argv[1:],
         project='masakari',
         version=version.version_string(),
         default_config_files=default_config_files)

    if init_rpc:
        rpc.init(CONF)

    if configure_db:
        sqlalchemy_api.configure(CONF)
