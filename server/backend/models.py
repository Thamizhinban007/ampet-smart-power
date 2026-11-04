from datetime import datetime, timezone

from backend.database import db


def utcnow():
    return datetime.now(timezone.utc)


class Zone(db.Model):
    __tablename__ = "zones"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    code = db.Column(db.String(32), unique=True, nullable=False)
    description = db.Column(db.Text, default="")
    latitude = db.Column(db.Float, nullable=False, default=0.0)
    longitude = db.Column(db.Float, nullable=False, default=0.0)
    created_at = db.Column(db.DateTime, default=utcnow)

    nodes = db.relationship("Node", back_populates="zone", cascade="all, delete-orphan")

    def to_dict(self, include_node_count=False):
        data = {
            "id": self.id,
            "name": self.name,
            "code": self.code,
            "description": self.description,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
        if include_node_count:
            data["node_count"] = len(self.nodes)
        return data


class Node(db.Model):
    __tablename__ = "nodes"

    id = db.Column(db.Integer, primary_key=True)
    zone_id = db.Column(db.Integer, db.ForeignKey("zones.id"), nullable=False)
    name = db.Column(db.String(120), nullable=False)
    type = db.Column(db.String(20), nullable=False)  # feeder | consumer
    parent_node_id = db.Column(db.Integer, db.ForeignKey("nodes.id"), nullable=True)
    latitude = db.Column(db.Float, nullable=False, default=0.0)
    longitude = db.Column(db.Float, nullable=False, default=0.0)
    status = db.Column(db.String(32), default="ACTIVE")
    created_at = db.Column(db.DateTime, default=utcnow)

    zone = db.relationship("Zone", back_populates="nodes")
    parent = db.relationship("Node", remote_side=[id], backref="children")
    readings = db.relationship("Reading", back_populates="node", cascade="all, delete-orphan")

    def latest_reading(self):
        return (
            Reading.query.filter_by(node_id=self.id)
            .order_by(Reading.recorded_at.desc())
            .first()
        )

    def to_dict(self, include_reading=False, include_zone=False):
        data = {
            "id": self.id,
            "zone_id": self.zone_id,
            "name": self.name,
            "type": self.type,
            "parent_node_id": self.parent_node_id,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
        if include_zone and self.zone:
            data["zone"] = self.zone.to_dict()
        if include_reading:
            reading = self.latest_reading()
            data["reading"] = reading.to_dict() if reading else None
        return data


class Reading(db.Model):
    __tablename__ = "readings"

    id = db.Column(db.Integer, primary_key=True)
    node_id = db.Column(db.Integer, db.ForeignKey("nodes.id"), nullable=False)
    voltage = db.Column(db.Float, default=0.0)
    current = db.Column(db.Float, default=0.0)
    power = db.Column(db.Float, default=0.0)
    energy = db.Column(db.Float, default=0.0)
    recorded_at = db.Column(db.DateTime, default=utcnow)

    node = db.relationship("Node", back_populates="readings")

    def to_dict(self):
        return {
            "id": self.id,
            "node_id": self.node_id,
            "voltage": self.voltage,
            "current": self.current,
            "power": self.power,
            "energy": self.energy,
            "recorded_at": self.recorded_at.isoformat() if self.recorded_at else None,
        }
