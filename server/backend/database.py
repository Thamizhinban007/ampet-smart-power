import os

from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")
os.makedirs(DATA_DIR, exist_ok=True)

DEFAULT_DB_PATH = os.path.join(DATA_DIR, "ampet.db")


def init_db(app):
    db_path = os.environ.get("DATABASE_URL", f"sqlite:///{DEFAULT_DB_PATH}")
    app.config["SQLALCHEMY_DATABASE_URI"] = db_path
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    db.init_app(app)

    with app.app_context():
        from backend import models  # noqa: F401
        from backend.seed import seed_database

        db.create_all()
        seed_database()
