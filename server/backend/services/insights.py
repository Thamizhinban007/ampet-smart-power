from backend.models import Node, Zone
from backend.services.theft import compute_theft_status


def generate_insights():
    zones = Zone.query.all()
    zone_summaries = []
    alerts = []
    recommendations = []
    health_points = []

    for zone in zones:
        feeders = [n for n in zone.nodes if n.type == "feeder"]
        consumers = [n for n in zone.nodes if n.type == "consumer"]

        feeder_power = sum((n.latest_reading().power if n.latest_reading() else 0) for n in feeders)
        consumer_power = sum((n.latest_reading().power if n.latest_reading() else 0) for n in consumers)
        power_diff = feeder_power - consumer_power
        theft = compute_theft_status(power_diff)

        zone_summaries.append(
            {
                "zone_id": zone.id,
                "zone_name": zone.name,
                "feeder_count": len(feeders),
                "consumer_count": len(consumers),
                "feeder_power": round(feeder_power, 2),
                "consumer_power": round(consumer_power, 2),
                "power_diff": round(power_diff, 2),
                "theft_status": theft,
            }
        )

        if theft != "SAFE":
            alerts.append(
                {
                    "zone_id": zone.id,
                    "zone_name": zone.name,
                    "severity": theft,
                    "message": f"{zone.name}: power gap of {round(power_diff, 1)} W detected",
                }
            )

        for consumer in consumers:
            parent = consumer.parent
            if not parent:
                continue
            parent_reading = parent.latest_reading()
            consumer_reading = consumer.latest_reading()
            if not parent_reading or not consumer_reading:
                continue
            gap = parent_reading.power - consumer_reading.power
            if gap > 50:
                recommendations.append(
                    {
                        "zone_id": zone.id,
                        "node_id": consumer.id,
                        "node_name": consumer.name,
                        "message": f"Inspect {consumer.name}: {round(gap, 1)} W gap from feeder {parent.name}",
                    }
                )

        if theft == "SAFE":
            health_points.append(100)
        elif theft == "SUSPECTED":
            health_points.append(65)
        else:
            health_points.append(30)

    overall_health = round(sum(health_points) / len(health_points)) if health_points else 100

    return {
        "overall_health": overall_health,
        "zone_summaries": zone_summaries,
        "alerts": alerts,
        "recommendations": recommendations[:10],
        "summary": _build_summary(overall_health, len(alerts), len(zones)),
    }


def _build_summary(health, alert_count, zone_count):
    if alert_count == 0:
        return f"All {zone_count} zone(s) operating normally. System health: {health}%."
    return (
        f"Monitoring {zone_count} zone(s). {alert_count} alert(s) require attention. "
        f"System health: {health}%."
    )
