"""Production WSGI entry point.

Run with a real WSGI server instead of Flask's dev server, e.g.:

    gunicorn -w 4 -b 0.0.0.0:5000 wsgi:app

`run.py` still works for local development (python run.py), and now
respects FLASK_DEBUG=true if you want the auto-reloading dev server.
"""

from backend.app import app

__all__ = ["app"]
