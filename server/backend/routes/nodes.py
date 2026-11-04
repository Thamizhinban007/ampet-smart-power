from flask import Blueprint, jsonify, request

from backend.database import db
from backend.models import Node, Reading, Zone

bp = Blueprint("nodes", __name__, url_prefix="/api/nodes")

VALID_TYPES = {"feeder", "consumer"}


@bp.route("", methods=["GET"])
def list_nodes():
    query = Node.query
    zone_id = request.args.get("zone_id")
    node_type = request.args.get("type")

    if zone_id:
        query = query.filter_by(zone_id=int(zone_id))
    if node_type:
        query = query.filter_by(type=node_type)

    nodes = query.order_by(Node.name).all()
    return jsonify([n.to_dict(include_reading=True, include_zone=True) for n in nodes])


@bp.route("", methods=["POST"])
def create_node():
    data = request.get_json() or {}
    required = ["name", "type", "zone_id"]
    for field in required:
        if not data.get(field):
            return jsonify({"error": f"{field} is required"}), 400

    if data["type"] not in VALID_TYPES:
        return jsonify({"error": "type must be feeder or consumer"}), 400

    if not db.session.get(Zone, data["zone_id"]):
        return jsonify({"error": "Zone not found"}), 404

    parent_node_id = data.get("parent_node_id")
    if parent_node_id:
        parent = db.session.get(Node, parent_node_id)
        if not parent:
            return jsonify({"error": "Parent node not found"}), 404
        if parent.type != "feeder":
            return jsonify({"error": "Parent must be a feeder node"}), 400

    node = Node(
        zone_id=data["zone_id"],
        name=data["name"],
        type=data["type"],
        parent_node_id=parent_node_id,
        latitude=float(data.get("latitude", 0)),
        longitude=float(data.get("longitude", 0)),
        status=data.get("status", "ACTIVE"),
    )
    db.session.add(node)
    db.session.flush()

    reading_data = data.get("reading", {})
    db.session.add(
        Reading(
            node_id=node.id,
            voltage=float(reading_data.get("voltage", 0)),
            current=float(reading_data.get("current", 0)),
            power=float(reading_data.get("power", 0)),
            energy=float(reading_data.get("energy", 0)),
        )
    )
    db.session.commit()
    return jsonify(node.to_dict(include_reading=True, include_zone=True)), 201


@bp.route("/<int:node_id>", methods=["GET"])
def get_node(node_id):
    node = db.session.get(Node, node_id)
    if not node:
        return jsonify({"error": "Node not found"}), 404
    return jsonify(node.to_dict(include_reading=True, include_zone=True))


@bp.route("/<int:node_id>", methods=["PUT"])
def update_node(node_id):
    node = db.session.get(Node, node_id)
    if not node:
        return jsonify({"error": "Node not found"}), 404

    data = request.get_json() or {}
    if "name" in data:
        node.name = data["name"]
    if "type" in data:
        if data["type"] not in VALID_TYPES:
            return jsonify({"error": "type must be feeder or consumer"}), 400
        node.type = data["type"]
    if "zone_id" in data:
        if not db.session.get(Zone, data["zone_id"]):
            return jsonify({"error": "Zone not found"}), 404
        node.zone_id = data["zone_id"]
    if "parent_node_id" in data:
        parent_node_id = data["parent_node_id"]
        if parent_node_id:
            parent = db.session.get(Node, parent_node_id)
            if not parent:
                return jsonify({"error": "Parent node not found"}), 404
            if parent.type != "feeder":
                return jsonify({"error": "Parent must be a feeder node"}), 400
        node.parent_node_id = parent_node_id
    if "latitude" in data:
        node.latitude = float(data["latitude"])
    if "longitude" in data:
        node.longitude = float(data["longitude"])
    if "status" in data:
        node.status = data["status"]

    db.session.commit()
    return jsonify(node.to_dict(include_reading=True, include_zone=True))


@bp.route("/<int:node_id>", methods=["DELETE"])
def delete_node(node_id):
    node = db.session.get(Node, node_id)
    if not node:
        return jsonify({"error": "Node not found"}), 404
    db.session.delete(node)
    db.session.commit()
    return jsonify({"status": "deleted"})


@bp.route("/<int:node_id>/readings", methods=["GET"])
def node_readings(node_id):
    node = db.session.get(Node, node_id)
    if not node:
        return jsonify({"error": "Node not found"}), 404

    limit = request.args.get("limit", 50, type=int)
    readings = (
        Reading.query.filter_by(node_id=node_id)
        .order_by(Reading.recorded_at.desc())
        .limit(limit)
        .all()
    )
    return jsonify([r.to_dict() for r in readings])
