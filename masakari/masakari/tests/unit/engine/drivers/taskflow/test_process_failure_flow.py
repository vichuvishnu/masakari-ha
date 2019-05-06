# Copyright 2016 NTT DATA
# All Rights Reserved.

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

"""
Unit Tests for process failure TaskFlow
"""

import mock

from masakari.compute import nova
from masakari import context
from masakari.engine.drivers.taskflow import process_failure
from masakari import exception
from masakari import test
from masakari.tests.unit import fakes


class ProcessFailureTestCase(test.TestCase):

    def setUp(self):
        super(ProcessFailureTestCase, self).setUp()
        self.ctxt = context.get_admin_context()
        self.process_name = "nova-compute"
        self.service_host = "fake-host"
        self.novaclient = nova.API()
        self.fake_client = fakes.FakeNovaClient()
        # overriding 'wait_period_after_service_update' to 2 seconds
        # to reduce the wait period.
        self.override_config('wait_period_after_service_update', 2)

    @mock.patch('masakari.compute.nova.novaclient')
    def test_compute_process_failure_flow(self, _mock_novaclient):
        _mock_novaclient.return_value = self.fake_client

        # create test data
        self.fake_client.services.create("1", host=self.service_host,
                                         binary="nova-compute",
                                         status="enabled")

        # test DisableComputeNodeTask
        task = process_failure.DisableComputeNodeTask(self.novaclient)
        task.execute(self.ctxt, self.process_name, self.service_host)

        # test ConfirmComputeNodeDisabledTask
        task = process_failure.ConfirmComputeNodeDisabledTask(self.novaclient)
        task.execute(self.ctxt, self.process_name, self.service_host)

        # verify service is disabled
        self.assertTrue(self.novaclient.is_service_down(self.ctxt,
                                                        self.service_host,
                                                        self.process_name))

    @mock.patch('masakari.compute.nova.novaclient')
    def test_compute_process_failure_flow_disabled_process(self,
                                                           _mock_novaclient):
        _mock_novaclient.return_value = self.fake_client

        # create test data
        self.fake_client.services.create("1", host=self.service_host,
                                         binary="nova-compute",
                                         status="disabled")

        # test DisableComputeNodeTask
        task = process_failure.DisableComputeNodeTask(self.novaclient)
        with mock.patch.object(
            self.novaclient,
            'enable_disable_service') as mock_enable_disabled:
            task.execute(self.ctxt, self.process_name, self.service_host)

        # ensure that enable_disable_service method is not called
        self.assertEqual(0, mock_enable_disabled.call_count)

    @mock.patch('masakari.compute.nova.novaclient')
    def test_compute_process_failure_flow_compute_service_disabled_failed(
        self, _mock_novaclient):
        _mock_novaclient.return_value = self.fake_client

        # create test data
        self.fake_client.services.create("1", host=self.service_host,
                                         binary="nova-compute",
                                         status="enabled")

        def fake_is_service_down(context, host_name, binary):
            # assume that service is not disabled
            return False

        # test DisableComputeNodeTask
        task = process_failure.DisableComputeNodeTask(self.novaclient)
        task.execute(self.ctxt, self.process_name, self.service_host)

        with mock.patch.object(self.novaclient, 'is_service_down',
                               fake_is_service_down):
            # test ConfirmComputeNodeDisabledTask
            task = process_failure.ConfirmComputeNodeDisabledTask(
                self.novaclient)
            self.assertRaises(exception.ProcessRecoveryFailureException,
                              task.execute, self.ctxt, self.process_name,
                              self.service_host)
