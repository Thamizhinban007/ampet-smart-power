from flask import Blueprint, jsonify

from backend.services.insights import generate_insights

bp = Blueprint("insights", __name__, url_prefix="/api/insights")


@bp.route("", methods=["GET"])
def get_insights():
    return jsonify(generate_insights())
