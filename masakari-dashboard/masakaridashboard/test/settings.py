# Copyright (C) 2018 NTT DATA
# All Rights Reserved.
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

# Default to Horizons test settings to avoid any missing keys
from horizon.test.settings import *  # noqa: F403,H303
from openstack_dashboard.test.settings import *  # noqa: F403,H303

# pop these keys to avoid log warnings about deprecation
# update_dashboards will populate them anyway
HORIZON_CONFIG.pop('dashboards', None)
HORIZON_CONFIG.pop('default_dashboard', None)

# Update the dashboards with masakaridashboard
from masakaridashboard.local import enabled
import openstack_dashboard.enabled
from openstack_dashboard.utils import settings

settings.update_dashboards(
    [
        enabled,
        openstack_dashboard.enabled,
    ],
    HORIZON_CONFIG,
    INSTALLED_APPS
)

# Ensure any duplicate apps are removed after the update_dashboards call

INSTALLED_APPS = list(set(INSTALLED_APPS))
NOSE_ARGS = ['--nocapture',
             '--nologcapture',
             '--cover-package=masakaridashboard',
             '--cover-inclusive']
