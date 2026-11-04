def compute_theft_status(power_diff: float) -> str:
    if power_diff < 50:
        return "SAFE"
    if power_diff < 100:
        return "SUSPECTED"
    return "THEFT DETECTED"


def compute_difference(reading_a, reading_b):
    power_a = reading_a.power if reading_a else 0.0
    power_b = reading_b.power if reading_b else 0.0
    energy_a = reading_a.energy if reading_a else 0.0
    energy_b = reading_b.energy if reading_b else 0.0

    power_diff = power_a - power_b
    energy_diff = energy_a - energy_b

    return {
        "power": round(power_diff, 2),
        "energy": round(energy_diff, 6),
        "theft": compute_theft_status(power_diff),
    }
