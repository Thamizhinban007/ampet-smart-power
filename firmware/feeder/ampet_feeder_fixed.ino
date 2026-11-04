#include <WiFi.h>
#include <HTTPClient.h>
#include <math.h>

// ---------------- WIFI ----------------
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

const char* serverName =
"http://YOUR_SERVER_IP:5000/update_feeder";

// ---------------- CT ----------------
const int currentPin = 34;

const float noiseVrms = 0.0066;
float calibrationFactor = 3.1;

// ---------------- ENERGY ----------------
float energy_kWh = 0;
unsigned long lastTime = 0;

void setup() {

  Serial.begin(115200);
  analogReadResolution(12);

  Serial.println("AMPET Feeder Started");

  WiFi.begin(ssid, password);

  Serial.print("Connecting");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("WiFi Connected");

  Serial.print("ESP IP: ");
  Serial.println(WiFi.localIP());

  lastTime = millis();
}

void loop() {

  // ==========================
  // RMS Measurement
  // ==========================
  double sum = 0;
  const int sampleCount = 4000;

  for (int i = 0; i < sampleCount; i++) {

    int adc = analogRead(currentPin);

    sum += (double)adc * adc;
  }

  float meanSq = sum / sampleCount;

  if (meanSq < 0)
    meanSq = 0;

  float rmsADC = sqrt(meanSq);

  float vrms =
      rmsADC * 3.3 / 4095.0;

  float effectiveVrms =
      vrms - noiseVrms;

  if (effectiveVrms < 0)
    effectiveVrms = 0;

  // ==========================
  // Current
  // ==========================
  float current =
      effectiveVrms *
      calibrationFactor;

  if (current < 0.02)
    current = 0;

  // ==========================
  // Power
  // ==========================
  float power =
      current * 230.0;

  if (power < 1)
    power = 0;

  // ==========================
  // Energy
  // ==========================
  unsigned long now = millis();

  float hours =
      (now - lastTime) /
      3600000.0;

  energy_kWh +=
      (power / 1000.0) *
      hours;

  lastTime = now;

  // ==========================
  // Serial Monitor
  // ==========================
  Serial.print("Current=");
  Serial.print(current, 3);

  Serial.print(" A  Power=");
  Serial.print(power, 1);

  Serial.print(" W  Energy=");
  Serial.print(energy_kWh, 5);

  Serial.println(" kWh");

  // ==========================
  // Send to Flask
  // ==========================
  if (WiFi.status() == WL_CONNECTED) {

    HTTPClient http;

    http.begin(serverName);

    http.addHeader(
      "Content-Type",
      "application/json"
    );

    String jsonData = "{";

    jsonData += "\"current\":";
    jsonData += String(current, 3);

    jsonData += ",\"power\":";
    jsonData += String(power, 1);

    jsonData += ",\"energy\":";
    jsonData += String(energy_kWh, 5);

    jsonData += "}";

    int httpCode =
        http.POST(jsonData);

    Serial.print("HTTP: ");
    Serial.println(httpCode);
    Serial.println("Response: " + http.getString());  // add this
    Serial.println("Sent JSON: " + jsonData);           // add this too

    http.end();
  }

  delay(1000);
}
