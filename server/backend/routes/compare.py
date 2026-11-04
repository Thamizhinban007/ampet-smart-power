from flask import Blueprint, jsonify, request

from backend.database import db
from backend.models import Node
from backend.services.theft import compute_difference

bp = Blueprint("compare", __name__, url_prefix="/api/nodes")


@bp.route("/compare", methods=["GET"])
def compare_nodes():
    node_a_id = request.args.get("a", type=int)
    node_b_id = request.args.get("b", type=int)

    if not node_a_id or not node_b_id:
        return jsonify({"error": "Query params 'a' and 'b' are required"}), 400
    if node_a_id == node_b_id:
        return jsonify({"error": "Select two different nodes"}), 400

    node_a = db.session.get(Node, node_a_id)
    node_b = db.session.get(Node, node_b_id)
    if not node_a or not node_b:
        return jsonify({"error": "One or both nodes not found"}), 404

    reading_a = node_a.latest_reading()
    reading_b = node_b.latest_reading()
    diff = compute_difference(reading_a, reading_b)

    return jsonify(
        {
            "node_a": node_a.to_dict(include_reading=True, include_zone=True),
            "node_b": node_b.to_dict(include_reading=True, include_zone=True),
            "difference": {
                "power": diff["power"],
                "energy": diff["energy"],
            },
            "theft": diff["theft"],
        }
    )
