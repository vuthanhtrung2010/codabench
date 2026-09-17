from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError
from django.db import DEFAULT_DB_ALIAS
from django.db.models import Q


class Command(BaseCommand):
    help = 'Demote a superuser (remove superuser and staff privileges) by username or email.'

    def add_arguments(self, parser):
        parser.add_argument(
            'identifier',
            nargs='?',
            default=None,
            help='Username or email of the superuser to demote.',
        )
        parser.add_argument(
            '--username',
            dest='username',
            default=None,
            help='Explicitly specify the username.',
        )
        parser.add_argument(
            '--email',
            dest='email',
            default=None,
            help='Explicitly specify the email address.',
        )
        parser.add_argument(
            '--database',
            default=DEFAULT_DB_ALIAS,
            help='Database to use. Defaults to "default".',
        )

    def handle(self, *args, **options):
        UserModel = get_user_model()
        database = options['database']
        identifier = options.get('identifier')
        username = options.get('username')
        email = options.get('email')

        if not identifier and not username and not email:
            raise CommandError("Please provide a username or email: python manage.py demote_superuser <username_or_email>")

        manager = UserModel.objects.using(database)

        query = Q()
        if username:
            query = Q(username__iexact=username.strip())
        elif email:
            query = Q(email__iexact=email.strip().lower())
        elif identifier:
            id_clean = identifier.strip()
            query = Q(username__iexact=id_clean) | Q(email__iexact=id_clean.lower())

        users = manager.filter(query, is_deleted=False)

        if not users.exists():
            raise CommandError(f"No active user found matching '{identifier or username or email}'.")

        if users.count() > 1:
            raise CommandError(
                f"Multiple users matched '{identifier}'. Please disambiguate using --username or --email."
            )

        user = users.first()

        if not user.is_superuser and not user.is_staff:
            self.stdout.write(
                self.style.WARNING(f"User '{user.username}' ({user.email}) is already not a superuser or staff.")
            )
            return

        user.is_superuser = False
        user.is_staff = False
        user.save(using=database, update_fields=['is_superuser', 'is_staff'])

        self.stdout.write(
            self.style.SUCCESS(
                f"Successfully demoted user '{user.username}' ({user.email}) from superuser."
            )
        )
