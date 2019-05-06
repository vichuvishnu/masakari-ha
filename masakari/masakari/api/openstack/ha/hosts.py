# Copyright (c) 2016 NTT DATA
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

"""The Host API extension."""

from oslo_utils import encodeutils
from oslo_utils import strutils
from six.moves import http_client as http
from webob import exc

from masakari.api.openstack import common
from masakari.api.openstack import extensions
from masakari.api.openstack.ha.schemas import hosts as schema
from masakari.api.openstack import wsgi
from masakari.api import validation
from masakari import exception
from masakari.ha import api as host_api
from masakari.i18n import _
from masakari import objects
from masakari.policies import hosts as host_policies

ALIAS = "os-hosts"


class HostsController(wsgi.Controller):
    """The Host API controller for the OpenStack API."""

    def __init__(self):
        self.api = host_api.HostAPI()

    @extensions.expected_errors((http.BAD_REQUEST, http.FORBIDDEN,
                                 http.NOT_FOUND))
    def index(self, req, segment_id):
        """Returns a list a hosts."""
        context = req.environ['masakari.context']
        context.can(host_policies.HOSTS % 'index')

        try:
            filters = {}
            limit, marker = common.get_limit_and_marker(req)
            sort_keys, sort_dirs = common.get_sort_params(req.params)

            segment = objects.FailoverSegment.get_by_uuid(context,
                                                          segment_id)

            filters['failover_segment_id'] = segment.uuid
            if 'name' in req.params:
                filters['name'] = req.params['name']

            if 'type' in req.params:
                filters['type'] = req.params['type']

            if 'control_attributes' in req.params:
                filters['control_attributes'] = req.params[
                    'control_attributes']

            if 'on_maintenance' in req.params:
                try:
                    filters['on_maintenance'] = strutils.bool_from_string(
                        req.params['on_maintenance'], strict=True)
                except ValueError as ex:
                    msg = _("Invalid value for on_maintenance: "
                            "%s") % encodeutils.exception_to_unicode(ex)
                    raise exc.HTTPBadRequest(explanation=msg)

            if 'reserved' in req.params:
                try:
                    filters['reserved'] = strutils.bool_from_string(
                        req.params['reserved'], strict=True)
                except ValueError as ex:
                    msg = _("Invalid value for reserved: "
                            "%s") % encodeutils.exception_to_unicode(ex)
                    raise exc.HTTPBadRequest(explanation=msg)

            hosts = self.api.get_all(context, filters=filters,
                                     sort_keys=sort_keys, sort_dirs=sort_dirs,
                                     limit=limit, marker=marker)
        except exception.MarkerNotFound as ex:
            raise exc.HTTPBadRequest(explanation=ex.format_message())
        except exception.Invalid as e:
            raise exc.HTTPBadRequest(explanation=e.format_message())
        except exception.FailoverSegmentNotFound as ex:
            raise exc.HTTPNotFound(explanation=ex.format_message())

        return {'hosts': hosts}

    @wsgi.response(http.CREATED)
    @extensions.expected_errors((http.FORBIDDEN, http.NOT_FOUND,
                                 http.CONFLICT))
    @validation.schema(schema.create)
    def create(self, req, segment_id, body):
        """Creates a host."""
        context = req.environ['masakari.context']
        context.can(host_policies.HOSTS % 'create')
        host_data = body.get('host')
        try:
            host = self.api.create_host(context, segment_id, host_data)
        except exception.FailoverSegmentNotFound as e:
            raise exc.HTTPNotFound(explanation=e.format_message())
        except exception.HostExists as e:
            raise exc.HTTPConflict(explanation=e.format_message())

        return {'host': host}

    @extensions.expected_errors((http.FORBIDDEN, http.NOT_FOUND))
    def show(self, req, segment_id, id):
        """Shows the details of a host."""
        context = req.environ['masakari.context']
        context.can(host_policies.HOSTS % 'detail')
        try:
            host = self.api.get_host(context, segment_id, id)
        except exception.HostNotFound as e:
            raise exc.HTTPNotFound(explanation=e.format_message())
        except exception.FailoverSegmentNotFound as e:
            raise exc.HTTPNotFound(explanation=e.format_message())
        return {'host': host}

    @extensions.expected_errors((http.FORBIDDEN, http.NOT_FOUND,
                                 http.CONFLICT))
    @validation.schema(schema.update)
    def update(self, req, segment_id, id, body):
        """Updates the existing host."""
        context = req.environ['masakari.context']
        context.can(host_policies.HOSTS % 'update')
        host_data = body.get('host')
        try:
            host = self.api.update_host(context, segment_id, id, host_data)
        except exception.HostNotFound as e:
            raise exc.HTTPNotFound(explanation=e.format_message())
        except exception.FailoverSegmentNotFound as e:
            raise exc.HTTPNotFound(explanation=e.format_message())
        except (exception.HostExists, exception.Conflict) as e:
            raise exc.HTTPConflict(explanation=e.format_message())

        return {'host': host}

    @wsgi.response(http.NO_CONTENT)
    @extensions.expected_errors((http.FORBIDDEN, http.NOT_FOUND,
                                 http.CONFLICT))
    def delete(self, req, segment_id, id):
        """Removes a host by id."""
        context = req.environ['masakari.context']
        context.can(host_policies.HOSTS % 'delete')
        try:
            self.api.delete_host(context, segment_id, id)
        except exception.FailoverSegmentNotFound as e:
            raise exc.HTTPNotFound(explanation=e.format_message())
        except exception.HostNotFound as e:
            raise exc.HTTPNotFound(explanation=e.format_message())
        except exception.Conflict as e:
            raise exc.HTTPConflict(explanation=e.format_message())


class Hosts(extensions.V1APIExtensionBase):
    """Hosts controller"""

    name = "Hosts"
    alias = ALIAS
    version = 1

    def get_resources(self):
        parent = {'member_name': 'segment',
                  'collection_name': 'segments'}
        resources = [
            extensions.ResourceExtension(
                'hosts', HostsController(), parent=parent,
                member_name='host')]

        return resources

    def get_controller_extensions(self):
        return []
