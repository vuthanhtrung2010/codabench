from django.core.management.base import BaseCommand
from oidc_configurations.utils import ensure_env_oidc_organization


class Command(BaseCommand):
    help = 'Setup or update OIDC Organization from environment variables'

    def handle(self, *args, **options):
        org = ensure_env_oidc_organization()
        if org:
            self.stdout.write(self.style.SUCCESS(f"Successfully configured OIDC Organization: '{org.name}' (ID: {org.id})"))
        else:
            self.stdout.write(self.style.WARNING("OIDC environment variables not fully set (OIDC_CLIENT_ID and OIDC_AUTHORIZATION_URL required)."))
