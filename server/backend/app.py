import os
from pathlib import Path

from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS

from backend import auth
from backend.database import init_db
from backend.routes.compare import bp as compare_bp
from backend.routes.insights import bp as insights_bp
from backend.routes.nodes import bp as nodes_bp
from backend.routes.telemetry import bp as telemetry_bp
from backend.routes.zones import bp as zones_bp


def create_app():
    app = Flask(__name__)
    CORS(
        app,
        resources={r"/api/*": {"origins": os.environ.get("AMPET_CORS_ORIGINS", "*")}},
        allow_headers=["Content-Type", "X-API-Key"],
    )
    auth.register(app)
    init_db(app)

    app.register_blueprint(zones_bp)
    app.register_blueprint(nodes_bp)
    app.register_blueprint(compare_bp)
    app.register_blueprint(telemetry_bp)
    app.register_blueprint(insights_bp)

    @app.route("/data")
    def legacy_data_redirect():
        from backend.routes.telemetry import legacy_data

        return legacy_data()

    @app.route("/update_consumer", methods=["POST"])
    def legacy_update_consumer():
        from backend.database import db
        from backend.models import Node, Reading

        data = request.get_json() or {}
        consumer = Node.query.filter_by(type="consumer").first()
        if not consumer:
            return jsonify({"error": "No consumer node found"}), 404
        reading = Reading(
            node_id=consumer.id,
            voltage=float(data.get("voltage", 0)),
            current=float(data.get("current", 0)),
            power=float(data.get("power", 0)),
            energy=float(data.get("energy", 0)),
        )
        db.session.add(reading)
        db.session.commit()
        return jsonify({"status": "ok"})

    @app.route("/update_feeder", methods=["POST"])
    def legacy_update_feeder():
        from backend.database import db
        from backend.models import Node, Reading

        data = request.get_json() or {}
        feeder = Node.query.filter_by(type="feeder").first()
        if not feeder:
            return jsonify({"error": "No feeder node found"}), 404
        reading = Reading(
            node_id=feeder.id,
            voltage=0.0,
            current=float(data.get("current", 0)),
            power=float(data.get("power", 0)),
            energy=float(data.get("energy_kWh", 0)),
        )
        db.session.add(reading)
        db.session.commit()
        return jsonify({"status": "ok"})

    @app.route("/api/health")
    def health():
        return jsonify({"status": "ok"})

    # A production build of the React dashboard lives here.  Serving it from
    # Flask keeps the dashboard and API available at one LAN address (:5000).
    frontend_dist = Path(app.root_path).parent / "frontend" / "dist"

    @app.route("/")
    @app.route("/<path:path>")
    def frontend(path=""):
        if frontend_dist.is_dir():
            requested_file = frontend_dist / path
            if path and requested_file.is_file():
                return send_from_directory(frontend_dist, path)
            return send_from_directory(frontend_dist, "index.html")

        return jsonify({
            "message": "AMPET API is running. Build the dashboard with 'npm.cmd run build' in frontend.",
            "health": "/api/health",
        })

    return app


app = create_app()

if __name__ == "__main__":
    debug_mode = os.environ.get("FLASK_DEBUG", "false").lower() in {"1", "true", "yes"}
    app.run(host="0.0.0.0", port=5000, debug=debug_mode)
