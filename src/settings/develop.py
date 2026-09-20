from .base import *  # noqa: F401,F403

# Static files (Whitenoise) development settings:
# Serve directly from STATICFILES_DIRS (including src/static/generated/riot.js & output.css)
# and autorefresh on every request so recompiled Riot tags and Stylus styles are served immediately.
WHITENOISE_USE_FINDERS = True
WHITENOISE_AUTOREFRESH = True
WHITENOISE_MAX_AGE = 0

