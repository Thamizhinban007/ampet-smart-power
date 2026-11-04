from flask import Blueprint, jsonify, request

from backend.database import db
from backend.models import Node, Zone

bp = Blueprint("zones", __name__, url_prefix="/api/zones")


@bp.route("", methods=["GET"])
def list_zones():
    zones = Zone.query.order_by(Zone.name).all()
    return jsonify([z.to_dict(include_node_count=True) for z in zones])


@bp.route("", methods=["POST"])
def create_zone():
    data = request.get_json() or {}
    required = ["name", "code"]
    for field in required:
        if not data.get(field):
            return jsonify({"error": f"{field} is required"}), 400

    if Zone.query.filter_by(code=data["code"]).first():
        return jsonify({"error": "Zone code already exists"}), 409

    zone = Zone(
        name=data["name"],
        code=data["code"],
        description=data.get("description", ""),
        latitude=float(data.get("latitude", 0)),
        longitude=float(data.get("longitude", 0)),
    )
    db.session.add(zone)
    db.session.commit()
    return jsonify(zone.to_dict(include_node_count=True)), 201


@bp.route("/<int:zone_id>", methods=["GET"])
def get_zone(zone_id):
    zone = db.session.get(Zone, zone_id)
    if not zone:
        return jsonify({"error": "Zone not found"}), 404
    return jsonify(zone.to_dict(include_node_count=True))


@bp.route("/<int:zone_id>", methods=["PUT"])
def update_zone(zone_id):
    zone = db.session.get(Zone, zone_id)
    if not zone:
        return jsonify({"error": "Zone not found"}), 404

    data = request.get_json() or {}
    if "code" in data and data["code"] != zone.code:
        if Zone.query.filter_by(code=data["code"]).first():
            return jsonify({"error": "Zone code already exists"}), 409
        zone.code = data["code"]
    if "name" in data:
        zone.name = data["name"]
    if "description" in data:
        zone.description = data["description"]
    if "latitude" in data:
        zone.latitude = float(data["latitude"])
    if "longitude" in data:
        zone.longitude = float(data["longitude"])

    db.session.commit()
    return jsonify(zone.to_dict(include_node_count=True))


@bp.route("/<int:zone_id>", methods=["DELETE"])
def delete_zone(zone_id):
    zone = db.session.get(Zone, zone_id)
    if not zone:
        return jsonify({"error": "Zone not found"}), 404
    db.session.delete(zone)
    db.session.commit()
    return jsonify({"status": "deleted"})
