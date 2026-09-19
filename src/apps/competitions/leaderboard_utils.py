import logging
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

logger = logging.getLogger(__name__)


def send_leaderboard_update(competition_id, phase_id=None):
    """
    Broadcast a real-time notification to the competition's leaderboard websocket group
    whenever submissions or scores are added, removed, or updated.
    """
    if not competition_id:
        return

    try:
        channel_layer = get_channel_layer()
        if not channel_layer:
            return

        async_to_sync(channel_layer.group_send)(
            f"leaderboard_competition_{competition_id}",
            {
                "type": "leaderboard.message",
                "text": {
                    "kind": "leaderboard_update",
                    "competition_id": competition_id,
                    "phase_id": phase_id,
                },
            },
        )
    except Exception as e:
        logger.warning(
            f"Failed to send leaderboard update over websocket for competition {competition_id}: {e}"
        )
