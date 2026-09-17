from django.urls import reverse
from rest_framework.test import APITestCase

from competitions.models import PhaseTaskInstance, CompetitionParticipant
from leaderboards.models import Leaderboard, Column, SubmissionScore
import factories


class DynamicLeaderboardTests(APITestCase):
    def setUp(self):
        self.creator = factories.UserFactory(username='creator', password='test_password')
        self.user1 = factories.UserFactory(username='user1', password='test_password')
        self.user2 = factories.UserFactory(username='user2', password='test_password')
        self.user3 = factories.UserFactory(username='user3', password='test_password')

        self.comp = factories.CompetitionFactory(created_by=self.creator)
        # Approve participants
        for u in [self.user1, self.user2, self.user3]:
            CompetitionParticipant.objects.create(user=u, competition=self.comp, status='approved')

        self.leaderboard = Leaderboard.objects.create(
            title="Results",
            key="results",
            primary_index=0
        )
        self.col = Column.objects.create(
            leaderboard=self.leaderboard,
            index=0,
            title="Accuracy",
            key="accuracy",
            sorting="desc",
            precision=2
        )

        self.task = factories.TaskFactory(created_by=self.creator)

        self.phase = factories.PhaseFactory(
            competition=self.comp,
            leaderboard=self.leaderboard,
            normalize_leaderboard=True,
            show_raw_scores=True,
            task_min_scores=[
                {
                    "task": 0,
                    "min_score": 56.0
                }
            ]
        )
        PhaseTaskInstance.objects.create(phase=self.phase, task=self.task, order_index=0)

        # Create 3 submissions
        # Sub 1: 91.57 (top)
        self.sub1 = factories.SubmissionFactory(
            owner=self.user1,
            phase=self.phase,
            leaderboard=self.leaderboard,
            task=self.task,
            status="Finished"
        )
        score1 = SubmissionScore.objects.create(column=self.col, score=91.57)
        score1.submissions.add(self.sub1)

        # Sub 2: 82.86
        self.sub2 = factories.SubmissionFactory(
            owner=self.user2,
            phase=self.phase,
            leaderboard=self.leaderboard,
            task=self.task,
            status="Finished"
        )
        score2 = SubmissionScore.objects.create(column=self.col, score=82.86)
        score2.submissions.add(self.sub2)

        # Sub 3: 40.0 (below min 56.0)
        self.sub3 = factories.SubmissionFactory(
            owner=self.user3,
            phase=self.phase,
            leaderboard=self.leaderboard,
            task=self.task,
            status="Finished"
        )
        score3 = SubmissionScore.objects.create(column=self.col, score=40.0)
        score3.submissions.add(self.sub3)

    def test_dynamic_leaderboard_normalization(self):
        url = reverse('phases-get-leaderboard', kwargs={'pk': self.phase.id})
        resp = self.client.get(url)
        assert resp.status_code == 200
        data = resp.json()

        assert data['normalize_leaderboard'] is True
        assert data['show_raw_scores'] is True
        assert data['normalized'] is True

        submissions = data['submissions']
        assert len(submissions) == 3

        # First submission is sub1 (normalized to 100.0)
        sub1_entry = next(s for s in submissions if s['owner'] == 'user1')
        sub1_score = sub1_entry['scores'][0]
        assert float(sub1_score['score']) == 100.0
        assert float(sub1_score['raw_score']) == 91.57
        assert float(sub1_score['normalized_score']) == 100.0

        # Second submission is sub2:
        # formula: 100 * (82.86 - 56.0) / (91.57 - 56.0) = 100 * 26.86 / 35.57 = 75.513... -> 75.51
        sub2_entry = next(s for s in submissions if s['owner'] == 'user2')
        sub2_score = sub2_entry['scores'][0]
        expected_sub2 = round(100.0 * (82.86 - 56.0) / (91.57 - 56.0), 2)
        assert float(sub2_score['score']) == expected_sub2
        assert float(sub2_score['raw_score']) == 82.86
        assert float(sub2_score['normalized_score']) == expected_sub2

        # Third submission is sub3 (below baseline 56.0 -> 0.0)
        sub3_entry = next(s for s in submissions if s['owner'] == 'user3')
        sub3_score = sub3_entry['scores'][0]
        assert float(sub3_score['score']) == 0.0
        assert float(sub3_score['raw_score']) == 40.0
        assert float(sub3_score['normalized_score']) == 0.0

    def test_dynamic_leaderboard_disabled(self):
        self.phase.normalize_leaderboard = False
        self.phase.save()

        url = reverse('phases-get-leaderboard', kwargs={'pk': self.phase.id})
        resp = self.client.get(url)
        assert resp.status_code == 200
        data = resp.json()

        assert data['normalize_leaderboard'] is False
        assert data['normalized'] is False

        submissions = data['submissions']
        sub1_entry = next(s for s in submissions if s['owner'] == 'user1')
        sub1_score = sub1_entry['scores'][0]
        assert float(sub1_score['score']) == 91.57
        assert float(sub1_score['raw_score']) == 91.57

    def test_dynamic_leaderboard_zero_denominator_safe(self):
        # If all scores are equal to min, or single submission equal to min, denominator is 0
        self.phase.task_min_scores = [{"task": 0, "min_score": 100.0}]
        self.phase.save()

        url = reverse('phases-get-leaderboard', kwargs={'pk': self.phase.id})
        resp = self.client.get(url)
        assert resp.status_code == 200
        data = resp.json()
        assert data['normalized'] is True
        # All are <= min (100.0), so all normalized to 0.0 without divide-by-zero error
        for sub in data['submissions']:
            assert float(sub['scores'][0]['score']) == 0.0

    def test_dynamic_leaderboard_multi_task_summary(self):
        # Create a second column and a sum column
        col2 = Column.objects.create(
            leaderboard=self.leaderboard,
            index=1,
            title="Score2",
            key="score2",
            sorting="desc",
            precision=2
        )
        _ = Column.objects.create(
            leaderboard=self.leaderboard,
            index=2,
            title="Total",
            key="total",
            sorting="desc",
            precision=2,
            computation=Column.SUM,
            computation_indexes="0,1"
        )
        self.leaderboard.save()

        self.phase.task_min_scores = [
            {"task": 0, "min_score": 50.0},
            {"task": 1, "min_score": 0.0},
        ]
        self.phase.save()

        # Clean existing submissions and scores
        SubmissionScore.objects.all().delete()
        self.phase.submissions.all().delete()

        # User 1 submission with col 0 = 100.0, col 1 = 50.0
        sub_u1 = factories.SubmissionFactory(
            owner=self.user1,
            phase=self.phase,
            leaderboard=self.leaderboard,
            task=self.task,
            status="Finished"
        )
        s1 = SubmissionScore.objects.create(column=self.col, score=100.0)
        s2 = SubmissionScore.objects.create(column=col2, score=50.0)
        sub_u1.scores.add(s1, s2)

        # User 2 submission with col 0 = 50.0, col 1 = 100.0
        sub_u2 = factories.SubmissionFactory(
            owner=self.user2,
            phase=self.phase,
            leaderboard=self.leaderboard,
            task=self.task,
            status="Finished"
        )
        s3 = SubmissionScore.objects.create(column=self.col, score=50.0)
        s4 = SubmissionScore.objects.create(column=col2, score=100.0)
        sub_u2.scores.add(s3, s4)

        url = reverse('phases-get-leaderboard', kwargs={'pk': self.phase.id})
        resp = self.client.get(url)
        assert resp.status_code == 200
        data = resp.json()

        subs = data['submissions']
        assert len(subs) == 2

        # User 1: col 0 is 100.0 (top), col 1 is 50.0 (equals min 50.0 -> 0.0). Total: 100.0
        u1_entry = next(s for s in subs if s['owner'] == 'user1')
        u1_scores_by_idx = {s['index']: s for s in u1_entry['scores']}
        assert float(u1_scores_by_idx[0]['score']) == 100.0
        assert float(u1_scores_by_idx[1]['score']) == 0.0
        assert float(u1_scores_by_idx[2]['score']) == 100.0
        assert float(u1_scores_by_idx[0]['raw_score']) == 100.0
        assert float(u1_scores_by_idx[1]['raw_score']) == 50.0
        assert float(u1_scores_by_idx[2]['raw_score']) == 150.0

        # User 2: col 0 is 50.0 (equals min 50.0 -> 0.0), col 1 is 100.0 (top -> 100.0). Total: 100.0
        u2_entry = next(s for s in subs if s['owner'] == 'user2')
        u2_scores_by_idx = {s['index']: s for s in u2_entry['scores']}
        assert float(u2_scores_by_idx[0]['score']) == 0.0
        assert float(u2_scores_by_idx[1]['score']) == 100.0
        assert float(u2_scores_by_idx[2]['score']) == 100.0
        assert float(u2_scores_by_idx[0]['raw_score']) == 50.0
        assert float(u2_scores_by_idx[1]['raw_score']) == 100.0
        assert float(u2_scores_by_idx[2]['raw_score']) == 150.0

        # Primary sort is on col 0 (Accuracy, desc): user1 (100.0) is first, user2 (0.0) is second
        assert subs[0]['owner'] == 'user1'
        assert subs[1]['owner'] == 'user2'
