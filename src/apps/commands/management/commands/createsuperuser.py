import os
import sys
from django.contrib.auth import get_user_model
from django.core import exceptions
from django.core.management.base import BaseCommand, CommandError
from django.db import DEFAULT_DB_ALIAS


class Command(BaseCommand):
    help = 'Create a superuser without a password (for OIDC/SSO authentication environments).'

    def add_arguments(self, parser):
        parser.add_argument(
            '--username',
            dest='username',
            default=None,
            help='Specifies the login for the superuser.',
        )
        parser.add_argument(
            '--email',
            dest='email',
            default=None,
            help='Specifies the email for the superuser.',
        )
        parser.add_argument(
            '--noinput',
            '--no-input',
            action='store_false',
            dest='interactive',
            help=(
                'Tells Django to NOT prompt the user for input of any kind. '
                'You must use --username and --email or environment variables.'
            ),
        )
        parser.add_argument(
            '--database',
            default=DEFAULT_DB_ALIAS,
            help='Nominates a database onto which the superuser will be persisted. Defaults to "default".',
        )

    def handle(self, *args, **options):
        UserModel = get_user_model()
        database = options['database']
        interactive = options['interactive']
        username = options.get('username')
        email = options.get('email')

        username_field = UserModel.USERNAME_FIELD
        email_field = getattr(UserModel, 'EMAIL_FIELD', 'email')

        if not interactive:
            username = username or os.environ.get('DJANGO_SUPERUSER_' + username_field.upper())
            email = email or os.environ.get('DJANGO_SUPERUSER_' + email_field.upper())

            if not username:
                raise CommandError(f"You must provide --username or set DJANGO_SUPERUSER_{username_field.upper()} when using --no-input.")
            if not email:
                raise CommandError(f"You must provide --email or set DJANGO_SUPERUSER_{email_field.upper()} when using --no-input.")
        else:
            if hasattr(self.stdin, 'isatty') and not self.stdin.isatty():
                raise CommandError("Not running in a TTY. Use --no-input with --username and --email.")

            while not username:
                try:
                    username_input = input(f"{username_field.capitalize()}: ").strip()
                except KeyboardInterrupt:
                    self.stderr.write("\nOperation cancelled.")
                    sys.exit(1)
                if not username_input:
                    self.stderr.write(f"Error: {username_field} cannot be blank.")
                    continue
                username = username_input

            while not email:
                try:
                    email_input = input("Email address: ").strip()
                except KeyboardInterrupt:
                    self.stderr.write("\nOperation cancelled.")
                    sys.exit(1)
                if not email_input:
                    self.stderr.write("Error: Email cannot be blank.")
                    continue
                email = email_input

        username = str(username).strip()
        email = str(email).strip().lower()

        # Check for existing user
        manager = UserModel._default_manager.db_manager(database)
        if manager.filter(**{username_field: username}).exists():
            raise CommandError(f"User with {username_field} '{username}' already exists. Use grant_superuser to promote them.")

        if manager.filter(**{email_field: email}).exists():
            raise CommandError(f"User with email '{email}' already exists. Use grant_superuser to promote them.")

        try:
            user = UserModel(**{
                username_field: username,
                email_field: email,
                'is_staff': True,
                'is_superuser': True,
                'is_active': True,
            })
            user.set_unusable_password()
            user.save(using=database)

            self.stdout.write(
                self.style.SUCCESS(
                    f"Superuser '{username}' ({email}) created successfully without password. Authenticate via OIDC."
                )
            )
        except exceptions.ValidationError as e:
            raise CommandError("; ".join(e.messages))
        except Exception as e:
            raise CommandError(f"Error creating superuser: {e}")
