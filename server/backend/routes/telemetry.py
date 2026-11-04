from flask import Blueprint, jsonify, request

from backend.database import db
from backend.models import Node, Reading
from backend.services.theft import compute_difference

bp = Blueprint("telemetry", __name__, url_prefix="/api/telemetry")


@bp.route("/live", methods=["GET"])
def live_telemetry():
    nodes = Node.query.order_by(Node.name).all()
    result = []
    for node in nodes:
        item = node.to_dict(include_reading=True, include_zone=True)
        if node.type == "feeder" and node.children:
            total_consumer_power = sum(
                (c.latest_reading().power if c.latest_reading() else 0) for c in node.children
            )
            feeder_reading = node.latest_reading()
            diff = compute_difference(feeder_reading, _pseudo_reading(total_consumer_power))
            item["linked_diff"] = diff
        result.append(item)
    return jsonify(result)


@bp.route("/<int:node_id>", methods=["POST"])
def ingest_telemetry(node_id):
    node = db.session.get(Node, node_id)
    if not node:
        return jsonify({"error": "Node not found"}), 404

    data = request.get_json() or {}
    reading = Reading(
        node_id=node_id,
        voltage=float(data.get("voltage", 0)),
        current=float(data.get("current", 0)),
        power=float(data.get("power", 0)),
        energy=float(data.get("energy", 0)),
    )
    db.session.add(reading)
    db.session.commit()
    return jsonify({"status": "ok", "reading": reading.to_dict()})


@bp.route("/legacy/data", methods=["GET"])
def legacy_data():
    """Backward-compatible endpoint matching original /data shape."""
    feeder = Node.query.filter_by(type="feeder").first()
    consumer = Node.query.filter_by(type="consumer").first()
    feeder_reading = feeder.latest_reading() if feeder else None
    consumer_reading = consumer.latest_reading() if consumer else None
    diff = compute_difference(feeder_reading, consumer_reading)

    return jsonify(
        {
            "consumer": consumer_reading.to_dict() if consumer_reading else {},
            "feeder": feeder_reading.to_dict() if feeder_reading else {},
            "difference": {"power": diff["power"], "energy": diff["energy"]},
            "theft": diff["theft"],
        }
    )


def _pseudo_reading(power_val):
    from types import SimpleNamespace
    return SimpleNamespace(power=power_val, energy=0.0)
