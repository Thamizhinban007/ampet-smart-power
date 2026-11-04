"""Minimal API key authentication.

Set the AMPET_API_KEY environment variable to require every request to
send a matching `X-API-Key` header. If AMPET_API_KEY is not set, the API
runs unauthenticated (useful for local development) and a warning is
logged once at startup so this doesn't silently ship to production.
"""

import os
import secrets

API_KEY = os.environ.get("AMPET_API_KEY", "").strip()

# Routes that must stay reachable without a key (health checks, load balancers).
EXEMPT_PATHS = {"/api/health"}


def is_configured() -> bool:
    return bool(API_KEY)


def register(app):
    if not is_configured():
        app.logger.warning(
            "AMPET_API_KEY is not set — the API is running WITHOUT authentication. "
            "Set AMPET_API_KEY before deploying anywhere reachable outside localhost."
        )
        return

    @app.before_request
    def _check_api_key():
        from flask import request, jsonify

        if request.method == "OPTIONS" or request.path in EXEMPT_PATHS:
            return None

        supplied = request.headers.get("X-API-Key", "")
        if not supplied or not secrets.compare_digest(supplied, API_KEY):
            return jsonify({"error": "Unauthorized: missing or invalid X-API-Key"}), 401
        return None
