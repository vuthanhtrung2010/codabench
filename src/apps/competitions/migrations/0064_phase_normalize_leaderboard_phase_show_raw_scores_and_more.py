from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('competitions', '0063_remove_competition_allow_robot_submissions'),
    ]

    operations = [
        migrations.AddField(
            model_name='phase',
            name='normalize_leaderboard',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='phase',
            name='show_raw_scores',
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name='phase',
            name='task_min_scores',
            field=models.JSONField(blank=True, default=list),
        ),
    ]
