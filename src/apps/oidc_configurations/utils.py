import logging
from django.conf import settings
from .models import Auth_Organization

logger = logging.getLogger(__name__)


def ensure_env_oidc_organization():
    """
    Ensure the Auth_Organization defined by OIDC environment variables exists
    and is up to date in the database.
    """
    if not getattr(settings, 'OIDC_ENABLED', True):
        return None

    client_id = getattr(settings, 'OIDC_CLIENT_ID', '')
    authorization_url = getattr(settings, 'OIDC_AUTHORIZATION_URL', '')

    if not client_id or not authorization_url:
        return None

    org_name = getattr(settings, 'OIDC_ORGANIZATION_NAME', 'Authentik')
    button_bg_color = getattr(settings, 'OIDC_BUTTON_BG_COLOR', '#2C3E4C')
    button_text_color = getattr(settings, 'OIDC_BUTTON_TEXT_COLOR', '#FFFFFF')
    token_url = getattr(settings, 'OIDC_TOKEN_URL', '')
    user_info_url = getattr(settings, 'OIDC_USER_INFO_URL', '')
    redirect_url = getattr(settings, 'OIDC_REDIRECT_URL', '')

    # If redirect_url is not set, attempt to construct default redirect url based on DOMAIN_NAME
    if not redirect_url and getattr(settings, 'DOMAIN_NAME', None):
        domain = settings.DOMAIN_NAME
        scheme = "https" if getattr(settings, 'CSRF_TRUSTED_ORIGINS', None) and any("https://" in str(o) for o in settings.CSRF_TRUSTED_ORIGINS) else "http"
        # Organization ID will be determined after lookup or set to default
        redirect_url = f"{scheme}://{domain}/oidc/complete/1/"

    try:
        org, created = Auth_Organization.objects.update_or_create(
            name=org_name,
            defaults={
                'client_id': client_id,
                'client_secret': getattr(settings, 'OIDC_CLIENT_SECRET', ''),
                'authorization_url': authorization_url,
                'token_url': token_url,
                'user_info_url': user_info_url,
                'redirect_url': redirect_url,
                'button_bg_color': button_bg_color,
                'button_text_color': button_text_color,
            }
        )
        # Update redirect_url with accurate org.id if dynamic
        if redirect_url and "/oidc/complete/1/" in redirect_url and org.id != 1:
            org.redirect_url = redirect_url.replace("/oidc/complete/1/", f"/oidc/complete/{org.id}/")
            org.save(update_fields=['redirect_url'])

        return org
    except Exception as e:
        logger.warning(f"Could not auto-configure OIDC organization from environment: {e}")
        return None
