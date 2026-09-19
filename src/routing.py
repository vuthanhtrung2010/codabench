from django.urls import re_path
from apps.competitions.consumers import SubmissionIOConsumer, SubmissionOutputConsumer, LeaderboardConsumer
from utils.consumers import ComputeWorkersConsumer


websocket_urlpatterns = [
    re_path(r'submission_input/(?P<user_pk>\d+)/(?P<submission_id>\d+)/(?P<secret>[^/]+)/$', SubmissionIOConsumer.as_asgi()),
    re_path(r'submission_output/$', SubmissionOutputConsumer.as_asgi()),
    re_path(r"ws/workers/$", ComputeWorkersConsumer.as_asgi()),
    re_path(r"ws/leaderboard/(?P<competition_id>\d+)/$", LeaderboardConsumer.as_asgi()),
]
