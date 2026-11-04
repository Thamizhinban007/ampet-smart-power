"""Entry point for running the AMPET backend API locally.

For production, use the WSGI entry point instead:
    gunicorn -w 4 -b 0.0.0.0:5000 wsgi:app
"""
import os

from backend.app import app

if __name__ == "__main__":
    debug_mode = os.environ.get("FLASK_DEBUG", "false").lower() in {"1", "true", "yes"}
    app.run(host="0.0.0.0", port=5000, debug=debug_mode)
