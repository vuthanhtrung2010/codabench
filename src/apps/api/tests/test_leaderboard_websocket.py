import asyncio
from unittest.mock import patch, MagicMock, AsyncMock
from django.urls import reverse
from rest_framework.test import APITestCase
from django.contrib.auth.models import AnonymousUser

import factories
from competitions.models import Submission
from competitions.leaderboard_utils import send_leaderboard_update
from competitions.consumers import LeaderboardConsumer


class LeaderboardWebSocketHelperTests(APITestCase):
    def setUp(self):
        self.creator = factories.UserFactory()
        self.comp = factories.CompetitionFactory(created_by=self.creator)
        self.phase = factories.PhaseFactory(competition=self.comp)

    @patch("competitions.leaderboard_utils.get_channel_layer")
    def test_send_leaderboard_update_broadcasts(self, mock_get_channel_layer):
        mock_layer = MagicMock()
        mock_get_channel_layer.return_value = mock_layer

        send_leaderboard_update(self.comp.id, self.phase.id)

        mock_layer.group_send.assert_called_once()
        group_name, message = mock_layer.group_send.call_args[0]
        assert group_name == f"leaderboard_competition_{self.comp.id}"
        assert message["type"] == "leaderboard.message"
        assert message["text"]["kind"] == "leaderboard_update"
        assert message["text"]["phase_id"] == self.phase.id
        assert message["text"]["competition_id"] == self.comp.id


class LeaderboardConsumerUnitTests(APITestCase):
    def test_consumer_connect_public_competition(self):
        async def _run():
            consumer = LeaderboardConsumer()
            consumer.scope = {
                "url_route": {"kwargs": {"competition_id": 999}},
                "user": AnonymousUser(),
            }
            consumer.channel_layer = MagicMock()
            consumer.channel_layer.group_add = AsyncMock()
            consumer.channel_name = "test_channel"
            consumer.accept = AsyncMock()
            consumer.close = AsyncMock()

            with patch.object(consumer, "_check_access", return_value=True):
                await consumer.connect()
                consumer.accept.assert_called_once()
                consumer.channel_layer.group_add.assert_called_once_with(
                    "leaderboard_competition_999", "test_channel"
                )

        asyncio.run(_run())

    def test_consumer_connect_denied(self):
        async def _run():
            consumer = LeaderboardConsumer()
            consumer.scope = {
                "url_route": {"kwargs": {"competition_id": 999}},
                "user": AnonymousUser(),
            }
            consumer.channel_layer = MagicMock()
            consumer.channel_layer.group_add = AsyncMock()
            consumer.channel_name = "test_channel"
            consumer.accept = AsyncMock()
            consumer.close = AsyncMock()

            with patch.object(consumer, "_check_access", return_value=False):
                await consumer.connect()
                consumer.close.assert_called_once_with(code=4403)
                consumer.accept.assert_not_called()

        asyncio.run(_run())

    def test_consumer_receives_leaderboard_message_and_forwards(self):
        async def _run():
            consumer = LeaderboardConsumer()
            consumer.send_json = AsyncMock()

            event = {
                "type": "leaderboard.message",
                "text": {
                    "kind": "leaderboard_update",
                    "phase_id": 42,
                    "competition_id": 10,
                },
            }
            await consumer.leaderboard_message(event)
            consumer.send_json.assert_called_once_with({
                "type": "leaderboard_update",
                "phase_id": 42,
                "competition_id": 10,
            })

        asyncio.run(_run())


class LeaderboardUpdateTriggerTests(APITestCase):
    def setUp(self):
        self.creator = factories.UserFactory(username="creator", password="creator")
        self.comp = factories.CompetitionFactory(created_by=self.creator)
        self.leaderboard = factories.LeaderboardFactory()
        self.phase = factories.PhaseFactory(competition=self.comp, leaderboard=self.leaderboard)
        self.col = factories.ColumnFactory(leaderboard=self.leaderboard, key="acc", index=0)
        self.submission = factories.SubmissionFactory(
            phase=self.phase,
            owner=self.creator,
            status=Submission.FINISHED,
            leaderboard=None,
        )

    @patch("api.views.submissions.send_leaderboard_update")
    def test_submission_leaderboard_connection_triggers_update(self, mock_send):
        self.client.login(username="creator", password="creator")
        url = reverse("submission-submission-leaderboard-connection", kwargs={"pk": self.submission.id})
        resp = self.client.post(url)
        assert resp.status_code == 200
        mock_send.assert_called_with(self.comp.id, self.phase.id)

    @patch("api.views.submissions.send_leaderboard_update")
    def test_upload_submission_scores_triggers_update(self, mock_send):
        url = f"/api/upload_submission_scores/{self.submission.id}/"
        data = {
            "secret": str(self.submission.secret),
            "scores": {
                "acc": 85.5,
            },
        }
        resp = self.client.post(url, data=data, format="json")
        assert resp.status_code == 200
        mock_send.assert_called_with(self.comp.id, self.phase.id)
