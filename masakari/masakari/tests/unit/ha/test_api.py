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

"""Tests for the failover segment api."""

import copy
import mock
from oslo_utils import timeutils

from masakari.engine import rpcapi as engine_rpcapi
from masakari import exception
from masakari.ha import api as ha_api
from masakari.objects import base as obj_base
from masakari.objects import host as host_obj
from masakari.objects import notification as notification_obj
from masakari.objects import segment as segment_obj
from masakari import test
from masakari.tests.unit.api.openstack import fakes
from masakari.tests.unit import fakes as fakes_data
from masakari.tests import uuidsentinel

NOW = timeutils.utcnow().replace(microsecond=0)


def _make_segment_obj(segment_dict):
    return segment_obj.FailoverSegment(**segment_dict)


def _make_host_obj(host_dict):
    return host_obj.Host(**host_dict)


def _make_notification_obj(notification_dict):
    return notification_obj.Notification(**notification_dict)


class FailoverSegmentAPITestCase(test.NoDBTestCase):
    """Test Case for failover segment api."""

    def setUp(self):
        super(FailoverSegmentAPITestCase, self).setUp()
        self.segment_api = ha_api.FailoverSegmentAPI()
        self.req = fakes.HTTPRequest.blank('/v1/segments',
                                           use_admin_context=True)
        self.context = self.req.environ['masakari.context']
        self.failover_segment = fakes_data.create_fake_failover_segment(
            name="segment1", id=1, description="something",
            service_type="COMPUTE", recovery_method="auto",
            uuid=uuidsentinel.fake_segment
        )

    def _assert_segment_data(self, expected, actual):
        self.assertTrue(obj_base.obj_equal_prims(expected, actual),
                        "The failover segment objects were not equal")

    @mock.patch.object(segment_obj.FailoverSegmentList, 'get_all')
    def test_get_all(self, mock_get_all):
        fake_failover_segment = fakes_data.create_fake_failover_segment(
            name="segment2", id=2, description="something",
            service_type="COMPUTE", recovery_method="auto",
            uuid=uuidsentinel.fake_segment_2
        )
        fake_failover_segment_list = [self.failover_segment,
                                     fake_failover_segment]
        mock_get_all.return_value = fake_failover_segment_list
        result = self.segment_api.get_all(self.context, filters=None,
                                          sort_keys=None,
                                          sort_dirs=None, limit=None,
                                          marker=None)
        for i in range(len(result)):
            self._assert_segment_data(fake_failover_segment_list[i],
                                      _make_segment_obj(result[i]))

    @mock.patch.object(segment_obj.FailoverSegmentList, 'get_all')
    def test_get_all_marker_not_found(self, mock_get_all):

        mock_get_all.side_effect = exception.MarkerNotFound(marker='123')

        self.assertRaises(exception.MarkerNotFound, self.segment_api.get_all,
                          self.context, filters=None, sort_keys=None,
                          sort_dirs=None, limit=None, marker='123')

    @mock.patch.object(segment_obj.FailoverSegmentList, 'get_all')
    def test_get_all_by_recovery_method(self, mock_get_all):
        filters = {'recovery_method': 'auto'}
        self.segment_api.get_all(self.context, filters=filters,
                                 sort_keys=None, sort_dirs=None,
                                 limit=None, marker=None)
        mock_get_all.assert_called_once_with(self.context, filters=filters,
                                             sort_keys=None, sort_dirs=None,
                                             limit=None, marker=None)

    @mock.patch.object(segment_obj.FailoverSegmentList, 'get_all')
    def test_get_all_invalid_sort_dir(self, mock_get_all):

        mock_get_all.side_effect = exception.InvalidInput(
            reason="Unknown sort direction, must be 'asc' or 'desc'")
        self.assertRaises(exception.InvalidInput, self.segment_api.get_all,
                          self.context, filters=None, sort_keys=None,
                          sort_dirs=['abcd'], limit=None, marker=None)

    @mock.patch.object(segment_obj, 'FailoverSegment')
    @mock.patch.object(segment_obj.FailoverSegment, 'create')
    def test_create(self, mock_segment_create, mock_segment_obj):
        segment_data = {"name": "segment1",
                        "service_type": "COMPUTE",
                        "recovery_method": "auto",
                        "description": "something"}
        mock_segment_obj.return_value = self.failover_segment
        mock_segment_obj.create = mock.Mock()
        result = self.segment_api.create_segment(self.context, segment_data)
        self._assert_segment_data(
            self.failover_segment, _make_segment_obj(result))

    @mock.patch.object(segment_obj.FailoverSegment, 'get_by_uuid')
    def test_get_segment(self, mock_get_segment):

        mock_get_segment.return_value = self.failover_segment

        result = self.segment_api.get_segment(self.context,
                                              uuidsentinel.fake_segment)
        self._assert_segment_data(self.failover_segment, result)

    @mock.patch.object(segment_obj.FailoverSegment, 'get_by_uuid')
    def test_get_segment_not_found(self, mock_get_segment):

        self.assertRaises(exception.FailoverSegmentNotFound,
                          self.segment_api.get_segment, self.context, '123')

    @mock.patch.object(segment_obj.FailoverSegment,
                       'is_under_recovery')
    @mock.patch.object(segment_obj, 'FailoverSegment')
    @mock.patch.object(segment_obj.FailoverSegment, 'save')
    @mock.patch.object(segment_obj.FailoverSegment, 'get_by_uuid')
    def test_update(self, mock_get, mock_update, mock_segment_obj,
                    mock_is_under_recovery):
        segment_data = {"name": "segment1"}
        mock_get.return_value = self.failover_segment
        mock_segment_obj.return_value = self.failover_segment
        mock_segment_obj.update = mock.Mock()
        mock_is_under_recovery.return_value = False
        result = self.segment_api.update_segment(self.context,
                                                 uuidsentinel.fake_segment,
                                                 segment_data)
        self._assert_segment_data(self.failover_segment, result)

    @mock.patch.object(segment_obj.FailoverSegment,
                       'is_under_recovery')
    @mock.patch.object(segment_obj, 'FailoverSegment')
    @mock.patch.object(segment_obj.FailoverSegment, 'get_by_uuid')
    def test_update_segment_under_recovery(self, mock_get, mock_segment_obj,
                    mock_is_under_recovery):
        segment_data = {"name": "segment1"}
        mock_get.return_value = self.failover_segment
        mock_segment_obj.return_value = self.failover_segment
        mock_is_under_recovery.return_value = True
        self.assertRaises(exception.FailoverSegmentInUse,
                          self.segment_api.update_segment,
                          self.context, uuidsentinel.fake_segment,
                          segment_data)


class HostAPITestCase(test.NoDBTestCase):
    """Test Case for host api."""

    def setUp(self):
        super(HostAPITestCase, self).setUp()
        self.host_api = ha_api.HostAPI()
        self.req = fakes.HTTPRequest.blank(
            '/v1/segments/%s/hosts' % uuidsentinel.fake_segment,
            use_admin_context=True)
        self.context = self.req.environ['masakari.context']
        self.failover_segment = fakes_data.create_fake_failover_segment(
            name="segment1", id=1, description="something",
            service_type="COMPUTE", recovery_method="auto",
            uuid=uuidsentinel.fake_segment
        )
        self.host = fakes_data.create_fake_host(
            name="host_1", id=1, reserved=False, on_maintenance=False,
            type="fake", control_attributes="fake-control_attributes",
            uuid=uuidsentinel.fake_host_1,
            failover_segment_id=uuidsentinel.fake_segment1
        )

    def _assert_host_data(self, expected, actual):
        self.assertTrue(obj_base.obj_equal_prims(expected, actual),
                        "The host objects were not equal")

    @mock.patch.object(host_obj.HostList, 'get_all')
    @mock.patch.object(segment_obj.FailoverSegment, 'get_by_uuid')
    def test_get_all(self, mock_get, mock_get_all):
        mock_get.return_value = self.failover_segment
        fake_host = fakes_data.create_fake_host(
            name="host_2", id=2, reserved=False, on_maintenance=False,
            type="fake", control_attributes="fake-control_attributes",
            uuid=uuidsentinel.fake_host_2,
            failover_segment_id=uuidsentinel.fake_segment1
        )
        fake_host_list = [self.host, fake_host]
        mock_get_all.return_value = fake_host_list

        result = self.host_api.get_all(self.context,
                                       filters=None, sort_keys=['created_at'],
                                       sort_dirs=['desc'], limit=None,
                                       marker=None)
        for i in range(len(result)):
            self._assert_host_data(
                fake_host_list[i], _make_host_obj(result[i]))

    @mock.patch.object(host_obj.HostList, 'get_all')
    @mock.patch.object(segment_obj.FailoverSegment, 'get_by_uuid')
    def test_get_all_marker_not_found(self, mock_get, mock_get_all):
        mock_get.return_value = self.failover_segment
        mock_get_all.side_effect = exception.MarkerNotFound(marker="1234")

        self.assertRaises(exception.MarkerNotFound, self.host_api.get_all,
                          self.context, filters=None, sort_keys=['created_at'],
                          sort_dirs=['desc'], limit=None,
                          marker="1234")

    @mock.patch.object(host_obj.HostList, 'get_all')
    def test_get_all_by_type(self, mock_get):
        filters = {'type': 'SSH',
                   'failover_segment_id': uuidsentinel.fake_segment}
        self.host_api.get_all(self.context, filters, sort_keys='created_at',
                              sort_dirs='desc', limit=None, marker=None)
        mock_get.assert_called_once_with(self.context, filters=filters,
                                         sort_keys='created_at',
                                         sort_dirs='desc',
                                         limit=None, marker=None)

    @mock.patch.object(host_obj.HostList, 'get_all')
    def test_get_all_invalid_sort_dir(self, mock_get):

        mock_get.side_effect = exception.InvalidInput(
            reason="Unknown sort direction, must be 'asc' or 'desc'")

        self.assertRaises(exception.InvalidInput, self.host_api.get_all,
                          self.context, filters=None, sort_keys=None,
                          sort_dirs=['abcd'], limit=None,
                          marker=None)

    @mock.patch.object(host_obj, 'Host')
    @mock.patch.object(host_obj.Host, 'create')
    @mock.patch.object(segment_obj.FailoverSegment, 'get_by_uuid')
    def test_create(self, mock_get, mock_host_create, mock_host_obj):
        mock_get.return_value = self.failover_segment
        host_data = {
            "name": "host-1", "type": "fake-type",
            "reserved": False,
            "on_maintenance": False,
            "control_attributes": "fake-control_attributes"
        }
        mock_host_obj.return_value = self.host
        mock_host_obj.create = mock.Mock()
        result = self.host_api.create_host(self.context,
                                           uuidsentinel.fake_segment1,
                                           host_data)
        self._assert_host_data(self.host, _make_host_obj(result))

    @mock.patch('oslo_utils.uuidutils.generate_uuid')
    @mock.patch('masakari.db.host_create')
    @mock.patch.object(host_obj.Host, '_from_db_object')
    @mock.patch.object(segment_obj.FailoverSegment, 'get_by_uuid')
    def test_create_convert_boolean_attributes(self, mock_get_segment,
                                               mock__from_db_object,
                                               mock_host_create,
                                               mock_generate_uuid):
        host_data = {
            "name": "host-1", "type": "fake-type",
            "reserved": 'On',
            "on_maintenance": '0',
            "control_attributes": "fake-control_attributes"
        }

        expected_data = {
            'reserved': True, 'name': 'host-1',
            'control_attributes': 'fake-control_attributes',
            'on_maintenance': False,
            'uuid': uuidsentinel.fake_uuid,
            'failover_segment_id': uuidsentinel.fake_segment,
            'type': 'fake-type'
        }
        mock_host_create.create = mock.Mock()
        mock_get_segment.return_value = self.failover_segment
        mock_generate_uuid.return_value = uuidsentinel.fake_uuid
        self.host_api.create_host(self.context,
                                  uuidsentinel.fake_segment1,
                                  host_data)
        mock_host_create.assert_called_with(self.context, expected_data)

    @mock.patch.object(host_obj.Host, 'get_by_uuid')
    @mock.patch.object(segment_obj.FailoverSegment, 'get_by_uuid')
    def test_get_host(self, mock_get, mock_get_host):
        mock_get_host.return_value = self.host
        mock_get.return_value = self.failover_segment
        result = self.host_api.get_host(self.context,
                                        uuidsentinel.fake_segment,
                                        uuidsentinel.fake_host_1)
        self._assert_host_data(self.host, result)

    @mock.patch.object(host_obj.Host, 'get_by_uuid')
    @mock.patch.object(segment_obj.FailoverSegment, 'get_by_uuid')
    def test_get_host_not_found(self, mock_get, mock_get_host):
        self.assertRaises(exception.HostNotFound,
                          self.host_api.get_host, self.context,
                          uuidsentinel.fake_segment,
                          "123")

    @mock.patch.object(segment_obj.FailoverSegment,
                       'is_under_recovery')
    @mock.patch.object(host_obj, 'Host')
    @mock.patch.object(host_obj.Host, 'save')
    @mock.patch.object(host_obj.Host, 'get_by_uuid')
    @mock.patch.object(segment_obj.FailoverSegment, 'get_by_uuid')
    def test_update(self, mock_segment_get, mock_get,
                    mock_update, mock_host_obj,
                    mock_is_under_recovery):
        mock_segment_get.return_value = self.failover_segment
        host_data = {"name": "host_1"}
        mock_get.return_value = self.host
        mock_host_obj.return_value = self.host
        mock_host_obj.update = mock.Mock()
        mock_is_under_recovery.return_value = False
        result = self.host_api.update_host(self.context,
                                           uuidsentinel.fake_segment,
                                           uuidsentinel.fake_host_1,
                                           host_data)
        self._assert_host_data(self.host, result)

    @mock.patch.object(segment_obj.FailoverSegment,
                       'is_under_recovery')
    @mock.patch.object(host_obj, 'Host')
    @mock.patch.object(host_obj.Host, 'get_by_uuid')
    @mock.patch.object(segment_obj.FailoverSegment, 'get_by_uuid')
    def test_update_host_under_recovery(self, mock_segment_get, mock_get,
                    mock_host_obj,
                    mock_is_under_recovery):
        mock_segment_get.return_value = self.failover_segment
        host_data = {"name": "host_1"}
        mock_get.return_value = self.host
        mock_host_obj.return_value = self.host
        mock_is_under_recovery.return_value = True
        self.assertRaises(exception.HostInUse, self.host_api.update_host,
                          self.context, uuidsentinel.fake_segment,
                          uuidsentinel.fake_host_1, host_data)

    @mock.patch.object(segment_obj.FailoverSegment,
                       'is_under_recovery')
    @mock.patch.object(host_obj.Host, '_from_db_object')
    @mock.patch.object(host_obj.Host, 'get_by_uuid')
    @mock.patch('masakari.db.host_update')
    @mock.patch.object(segment_obj.FailoverSegment, 'get_by_uuid')
    def test_update_convert_boolean_attributes(
        self, mock_segment, mock_host_update, mock_host_object,
            mock__from_db_object, mock_is_under_recovery):
        host_data = {
            "reserved": 'Off',
            "on_maintenance": 'True',
        }

        expected_data = {
            'name': 'host_1', 'uuid': uuidsentinel.fake_host_1,
            'on_maintenance': True,
            'failover_segment_id': uuidsentinel.fake_segment1,
            'reserved': False, 'type': 'fake',
            'control_attributes': 'fake-control_attributes'
        }

        mock_segment.return_value = self.failover_segment
        mock_host_object.return_value = self.host
        self.host._context = self.context
        mock_is_under_recovery.return_value = False
        self.host_api.update_host(self.context,
                                  uuidsentinel.fake_segment1,
                                  uuidsentinel.fake_host_1,
                                  host_data)
        mock_host_update.assert_called_with(self.context,
                                            uuidsentinel.fake_host_1,
                                            expected_data)

    @mock.patch.object(segment_obj.FailoverSegment,
                       'is_under_recovery')
    @mock.patch.object(host_obj, 'Host')
    @mock.patch.object(host_obj.Host, 'get_by_uuid')
    @mock.patch.object(segment_obj.FailoverSegment, 'get_by_uuid')
    def test_delete_host_under_recovery(self, mock_segment_get, mock_get,
                    mock_host_obj,
                    mock_is_under_recovery):
        mock_segment_get.return_value = self.failover_segment
        mock_get.return_value = self.host
        mock_is_under_recovery.return_value = True
        self.assertRaises(exception.HostInUse, self.host_api.delete_host,
                          self.context, uuidsentinel.fake_segment,
                          uuidsentinel.fake_host_1)


class NotificationAPITestCase(test.NoDBTestCase):
    """Test Case for notification api."""

    @mock.patch.object(engine_rpcapi, 'EngineAPI')
    def setUp(self, mock_rpc):
        super(NotificationAPITestCase, self).setUp()
        self.notification_api = ha_api.NotificationAPI()
        self.req = fakes.HTTPRequest.blank('/v1/notifications',
                                           use_admin_context=True)
        self.context = self.req.environ['masakari.context']
        self.host = fakes_data.create_fake_host(
            name="host_1", id=1, reserved=False, on_maintenance=False,
            type="fake", control_attributes="fake-control_attributes",
            uuid=uuidsentinel.fake_host_1,
            failover_segment_id=uuidsentinel.fake_segment1
        )
        self.notification = fakes_data.create_fake_notification(
            type="VM", id=1, payload={
                'event': 'STOPPED', 'host_status': 'NORMAL',
                'cluster_status': 'ONLINE'
            },
            source_host_uuid=uuidsentinel.fake_host, generated_time=NOW,
            status="running",
            notification_uuid=uuidsentinel.fake_notification
        )

    def _assert_notification_data(self, expected, actual):
        self.assertTrue(obj_base.obj_equal_prims(expected, actual),
                        "The notification objects were not equal")

    @mock.patch.object(notification_obj.NotificationList, 'get_all')
    @mock.patch.object(notification_obj, 'Notification')
    @mock.patch.object(notification_obj.Notification, 'create')
    @mock.patch.object(host_obj.Host, 'get_by_name')
    def test_create(self, mock_host_obj, mock_create, mock_notification_obj,
                    mock_get_all):
        fake_notification = fakes_data.create_fake_notification(
            type="COMPUTE_HOST", id=2, payload={
                'event': 'STARTED', 'host_status': 'NORMAL',
                'cluster_status': 'ONLINE'
            },
            source_host_uuid=uuidsentinel.fake_host, generated_time=NOW,
            status="running",
            notification_uuid=uuidsentinel.fake_notification_2
        )
        fake_notification_list = [self.notification, fake_notification]
        mock_get_all.return_value = fake_notification_list
        notification_data = {"hostname": "fake_host",
                             "payload": {"event": "STARTED",
                                         "host_status": "NORMAL",
                                         "cluster_status": "OFFLINE"},
                             "type": "VM",
                             "generated_time": "2016-10-13T09:11:21.656788"}
        mock_host_obj.return_value = self.host
        mock_notification_obj.return_value = self.notification

        result = (self.notification_api.
                  create_notification(self.context, notification_data))

        self._assert_notification_data(
            self.notification, _make_notification_obj(result))

    @mock.patch.object(host_obj.Host, 'get_by_name')
    def test_create_host_on_maintenance(self, mock_host):
        self.host.on_maintenance = True
        mock_host.return_value = self.host
        notification_data = {"hostname": "host_1",
                             "payload": {"event": "STOPPED",
                                         "host_status": "NORMAL",
                                         "cluster_status": "ONLINE"},
                             "type": "COMPUTE_HOST",
                             "generated_time": str(NOW)}

        self.assertRaises(exception.HostOnMaintenanceError,
                          self.notification_api.create_notification,
                          self.context, notification_data)

    @mock.patch.object(host_obj.Host, 'get_by_name')
    def test_create_duplicate_notification(self, mock_host):
        mock_host.return_value = self.host
        self.notification_api._is_duplicate_notification = mock.Mock(
            return_value=True)
        notification_data = {"hostname": "host_1",
                             "payload": {'event': 'STOPPED',
                                         'host_status': 'NORMAL',
                                         'cluster_status': 'ONLINE'},
                             "type": "COMPUTE_HOST",
                             "generated_time": str(NOW)}

        self.assertRaises(exception.DuplicateNotification,
                          self.notification_api.create_notification,
                          self.context, notification_data)

    @mock.patch.object(notification_obj.NotificationList, 'get_all')
    def test_create_is_duplicate_true(self, mock_get_all):
        mock_get_all.return_value = [self.notification, ]

        self.assertTrue(self.notification_api._is_duplicate_notification(
            self.context, self.notification))

    @mock.patch.object(notification_obj.NotificationList, 'get_all')
    def test_create_is_duplicate_false(self, mock_get_all):
        mock_get_all.return_value = [self.notification, ]
        FAKE_NOTIFICATION = copy.deepcopy(self.notification)
        FAKE_NOTIFICATION.payload = {'event': 'STOPPED',
                                     'host_status': 'UNKNOWN',
                                     'cluster_status': 'OFFLINE'}
        self.assertFalse(self.notification_api._is_duplicate_notification(
            self.context, FAKE_NOTIFICATION))

    @mock.patch.object(notification_obj.Notification, 'get_by_uuid')
    def test_get_notification(self, mock_get_notification):

        mock_get_notification.return_value = self.notification

        result = (self.notification_api.
                  get_notification(self.context,
                                   uuidsentinel.fake_notification))
        self._assert_notification_data(self.notification, result)

    @mock.patch.object(notification_obj.Notification, 'get_by_uuid')
    def test_get_notification_not_found(self, mock_get_notification):

        self.assertRaises(exception.NotificationNotFound,
                          self.notification_api.get_notification,
                          self.context, '123')

    @mock.patch.object(notification_obj.NotificationList, 'get_all')
    def test_get_all(self, mock_get_all):
        fake_notification = fakes_data.create_fake_notification(
            type="VM", id=2, payload={
                'event': 'STOPPED', 'host_status': 'NORMAL',
                'cluster_status': 'ONLINE'
            },
            source_host_uuid=uuidsentinel.fake_host, generated_time=NOW,
            status="running",
            notification_uuid=uuidsentinel.fake_notification_2
        )
        fake_notification_list = [self.notification, fake_notification]
        mock_get_all.return_value = fake_notification_list

        result = self.notification_api.get_all(self.context, self.req)
        for i in range(len(result)):
            self._assert_notification_data(
                fake_notification_list[i], result[i])

    @mock.patch.object(notification_obj.NotificationList, 'get_all')
    def test_get_all_marker_not_found(self, mock_get_all):

        mock_get_all.side_effect = exception.MarkerNotFound(marker="100")
        self.req = fakes.HTTPRequest.blank('/v1/notifications?marker=100',
                                           use_admin_context=True)
        self.assertRaises(exception.MarkerNotFound,
                          self.notification_api.get_all,
                          self.context, self.req)

    @mock.patch.object(notification_obj.NotificationList, 'get_all')
    def test_get_all_by_status(self, mock_get_all):
        self.req = fakes.HTTPRequest.blank('/v1/notifications?status=new',
                                           use_admin_context=True)
        self.notification_api.get_all(self.context, filters={'status': 'new'},
                                      sort_keys='generated_time',
                                      sort_dirs='asc', limit=1000, marker=None)
        mock_get_all.assert_called_once_with(self.context, {'status': 'new'},
                                             'generated_time', 'asc',
                                             1000, None)

    @mock.patch.object(notification_obj.NotificationList, 'get_all')
    def test_get_all_invalid_sort_dir(self, mock_get_all):

        mock_get_all.side_effect = exception.InvalidInput(
            reason="Unknown sort direction, must be 'asc' or 'desc'")
        self.req = fakes.HTTPRequest.blank('/v1/notifications?sort_dir=abcd',
                                           use_admin_context=True)
        self.assertRaises(exception.InvalidInput,
                          self.notification_api.get_all,
                          self.context, self.req)
