from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('competitions', '0064_phase_normalize_leaderboard_phase_show_raw_scores_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='phase',
            name='has_trophy',
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name='phase',
            name='medal_gold_count',
            field=models.PositiveIntegerField(default=1),
        ),
        migrations.AddField(
            model_name='phase',
            name='medal_silver_count',
            field=models.PositiveIntegerField(default=1),
        ),
        migrations.AddField(
            model_name='phase',
            name='medal_bronze_count',
            field=models.PositiveIntegerField(default=1),
        ),
    ]
