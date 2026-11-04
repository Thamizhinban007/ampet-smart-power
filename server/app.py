"""Legacy entry point — use run.py or python -m backend.app instead."""
from backend.app import app

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
