# Copyright 2016 NTT DATA
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

"""Starter script for Masakari API.

"""
import os
import sys

from oslo_log import log as logging
from oslo_service import _options as service_opts
from paste import deploy
import six

from masakari.common import config
import masakari.conf
from masakari import config as api_config
from masakari import exception
from masakari import objects
from masakari import rpc
from masakari import service
from masakari import version


CONFIG_FILES = ['api-paste.ini', 'masakari.conf']
CONF = masakari.conf.CONF


def _get_config_files(env=None):
    if env is None:
        env = os.environ
    dirname = env.get('OS_MASAKARI_CONFIG_DIR', '/etc/masakari').strip()
    return [os.path.join(dirname, config_file)
            for config_file in CONFIG_FILES]


def main():
    api_config.parse_args(sys.argv)
    logging.setup(CONF, "masakari")
    log = logging.getLogger(__name__)
    objects.register_all()

    launcher = service.process_launcher()
    started = 0
    try:
        server = service.WSGIService("masakari_api", use_ssl=CONF.use_ssl)
        launcher.launch_service(server, workers=server.workers or 1)
        started += 1
    except exception.PasteAppNotFound as ex:
        log.warning("%s. ``enabled_apis`` includes bad values. "
                "Fix to remove this warning.", six.text_type(ex))

    if started == 0:
        log.error('No APIs were started. '
                  'Check the enabled_apis config option.')
        sys.exit(1)

    launcher.wait()


def initialize_application():
    conf_files = _get_config_files()
    api_config.parse_args([], default_config_files=conf_files)
    logging.setup(CONF, "masakari")

    objects.register_all()
    CONF(sys.argv[1:], project='masakari', version=version.version_string())

    # NOTE: Dump conf at debug (log_options option comes from oslo.service)
    # This is gross but we don't have a public hook into oslo.service to
    # register these options, so we are doing it manually for now;
    # remove this when we have a hook method into oslo.service.
    CONF.register_opts(service_opts.service_opts)
    if CONF.log_options:
        CONF.log_opt_values(logging.getLogger(__name__), logging.DEBUG)

    config.set_middleware_defaults()
    rpc.init(CONF)
    conf = conf_files[0]

    return deploy.loadapp('config:%s' % conf, name="masakari_api")
