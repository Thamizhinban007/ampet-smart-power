import json
import os

from backend.database import DATA_DIR, db
from backend.models import Node, Reading, Zone


def _load_json(filename, default):
    path = os.path.join(DATA_DIR, filename)
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return default


def seed_database():
    if Zone.query.first():
        return

    zone = Zone(
        name="Default Zone",
        code="ZONE-01",
        description="Primary service area",
        latitude=28.6139,
        longitude=77.2090,
    )
    db.session.add(zone)
    db.session.flush()

    feeder_data = _load_json("feeder.json", {"current": 0, "power": 0, "energy": 0})
    consumer_data = _load_json(
        "consumer.json",
        {"voltage": 0, "current": 0, "power": 0, "energy": 0},
    )

    feeder = Node(
        zone_id=zone.id,
        name="Feeder Unit 1",
        type="feeder",
        latitude=28.6145,
        longitude=77.2095,
        status="ACTIVE",
    )
    db.session.add(feeder)
    db.session.flush()

    consumer = Node(
        zone_id=zone.id,
        name="Consumer Unit 1",
        type="consumer",
        parent_node_id=feeder.id,
        latitude=28.6135,
        longitude=77.2085,
        status="ACTIVE",
    )
    db.session.add(consumer)
    db.session.flush()

    db.session.add(
        Reading(
            node_id=feeder.id,
            voltage=0.0,
            current=feeder_data.get("current", 0),
            power=feeder_data.get("power", 0),
            energy=feeder_data.get("energy", 0),
        )
    )
    db.session.add(
        Reading(
            node_id=consumer.id,
            voltage=consumer_data.get("voltage", 0),
            current=consumer_data.get("current", 0),
            power=consumer_data.get("power", 0),
            energy=consumer_data.get("energy", 0),
        )
    )

    db.session.commit()
