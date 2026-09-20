from django.urls import reverse
from rest_framework.test import APITestCase
from django.contrib.admin.sites import site

import factories
from competitions.models import Phase, Submission
from competitions.admin import PhaseExpansion as PhaseAdmin, PhaseInline


class LeaderboardAwardsTests(APITestCase):
    def setUp(self):
        self.creator = factories.UserFactory(username="creator", password="creator")
        self.comp = factories.CompetitionFactory(created_by=self.creator)
        self.leaderboard = factories.LeaderboardFactory()
        self.phase = factories.PhaseFactory(
            competition=self.comp,
            leaderboard=self.leaderboard,
            has_trophy=True,
            medal_gold_count=2,
            medal_silver_count=3,
            medal_bronze_count=4,
        )
        self.col = factories.ColumnFactory(leaderboard=self.leaderboard, key="score", index=0)
        self.sub = factories.SubmissionFactory(
            phase=self.phase,
            owner=self.creator,
            status=Submission.FINISHED,
            leaderboard=self.leaderboard,
        )

    def test_phase_award_fields_default_values(self):
        new_phase = factories.PhaseFactory(
            competition=self.comp,
            name="New Phase",
        )
        assert new_phase.has_trophy is True
        assert new_phase.medal_gold_count == 1
        assert new_phase.medal_silver_count == 1
        assert new_phase.medal_bronze_count == 1

    def test_phase_award_fields_custom_values(self):
        assert self.phase.has_trophy is True
        assert self.phase.medal_gold_count == 2
        assert self.phase.medal_silver_count == 3
        assert self.phase.medal_bronze_count == 4

    def test_get_leaderboard_api_returns_award_config(self):
        url = reverse("phases-get-leaderboard", kwargs={"pk": self.phase.id})
        resp = self.client.get(url)
        assert resp.status_code == 200
        data = resp.json()
        assert data["has_trophy"] is True
        assert data["medal_gold_count"] == 2
        assert data["medal_silver_count"] == 3
        assert data["medal_bronze_count"] == 4

    def test_phase_api_update_award_settings(self):
        self.client.login(username="creator", password="creator")
        url = reverse("phases-detail", kwargs={"pk": self.phase.id})
        resp = self.client.patch(
            url,
            {
                "has_trophy": False,
                "medal_gold_count": 5,
                "medal_silver_count": 6,
                "medal_bronze_count": 7,
            },
            format="json",
        )
        assert resp.status_code == 200
        self.phase.refresh_from_db()
        assert self.phase.has_trophy is False
        assert self.phase.medal_gold_count == 5
        assert self.phase.medal_silver_count == 6
        assert self.phase.medal_bronze_count == 7

    def test_admin_phase_and_inline_include_award_fields(self):
        phase_inline = PhaseInline(self.comp.__class__, site)
        assert "has_trophy" in phase_inline.fields
        assert "medal_gold_count" in phase_inline.fields
        assert "medal_silver_count" in phase_inline.fields
        assert "medal_bronze_count" in phase_inline.fields

        phase_admin = PhaseAdmin(Phase, site)
        assert "has_trophy" in phase_admin.list_display
