#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <math.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);

// ================= WIFI =================
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

const char* serverName =
"http://YOUR_SERVER_IP:5000/update_consumer";

// ================= PINS =================
const int voltagePin = 35;
const int currentPin = 34;

// ================= CALIBRATION =================
float voltageCalibration = 168.47;

// ACS712 30A
float sensitivity = 0.066;

// ================= ENERGY =================
float energy_kWh = 0;
unsigned long lastTime = 0;

void setup() {

  Serial.begin(115200);
  analogReadResolution(12);

  lcd.begin();
  lcd.backlight();

  lcd.setCursor(0, 0);
  lcd.print("AMPET Meter");

  lcd.setCursor(0, 1);
  lcd.print("Connecting...");

  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);

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

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("WiFi Connected");

  delay(2000);
  lcd.clear();

  lastTime = millis();
}

void loop() {

  // ==========================================
  // VOLTAGE (Original working method)
  // ==========================================
  int maxV = 0;
  int minV = 4095;

  unsigned long startTime = millis();

  while (millis() - startTime < 100) {

    int sample = analogRead(voltagePin);

    if (sample > maxV)
      maxV = sample;

    if (sample < minV)
      minV = sample;
  }

  float peakToPeakV =
      maxV - minV;

  float sensorVoltage =
      (peakToPeakV * 3.3) / 4095.0;

  static float filteredVoltage = 230;

  filteredVoltage =
      (0.8 * filteredVoltage) +
      (0.2 * sensorVoltage *
       voltageCalibration);

  float mainsVoltage =
      filteredVoltage;

  // ==========================================
  // ACS712 Offset
  // ==========================================
  long offsetSum = 0;

  for (int i = 0; i < 1000; i++) {
    offsetSum +=
        analogRead(currentPin);
  }

  float offsetVoltage =
      (offsetSum / 1000.0) *
      3.3 / 4095.0;

  // ==========================================
  // RMS Current
  // ==========================================
  double sum = 0;

  for (int i = 0; i < 1000; i++) {

    int adc =
        analogRead(currentPin);

    float voltage =
        adc * 3.3 / 4095.0;

    float current =
        (voltage -
         offsetVoltage)
        / sensitivity;

    sum +=
        current * current;
  }

  float rmsCurrent =
      sqrt(sum / 1000.0);

  // Remove ACS712 noise
  if (rmsCurrent < 0.10)
    rmsCurrent = 0;

  // ==========================================
  // POWER
  // ==========================================
  float power =
      mainsVoltage *
      rmsCurrent;

  if (power < 20)
    power = 0;

  // ==========================================
  // ENERGY
  // ==========================================
  unsigned long now =
      millis();

  float hours =
      (float)(now -
      lastTime)
      / 3600000.0;

  energy_kWh +=
      (power / 1000.0)
      * hours;

  lastTime = now;

  // ==========================================
  // STATUS
  // ==========================================
  String status =
      "NORMAL";

  if (power > 500)
    status =
      "HIGH LOAD";

  String theft =
      "SAFE";

  // ==========================================
  // SERIAL MONITOR
  // ==========================================
  Serial.print("V=");
  Serial.print(
      mainsVoltage, 1);

  Serial.print(
      "V  I=");
  Serial.print(
      rmsCurrent, 2);

  Serial.print(
      "A  P=");
  Serial.print(
      power, 1);

  Serial.print(
      "W  E=");
  Serial.print(
      energy_kWh, 4);

  Serial.println(
      "kWh");

  // ==========================================
  // LCD
  // ==========================================
  lcd.setCursor(0, 0);

  lcd.print("V:");
  lcd.print(
      mainsVoltage, 0);

  lcd.print(" I:");
  lcd.print(
      rmsCurrent, 1);

  lcd.print("   ");

  lcd.setCursor(0, 1);

  lcd.print("P:");
  lcd.print(
      power, 0);

  lcd.print("W E:");
  lcd.print(
      energy_kWh, 2);

  lcd.print("   ");

  // ==========================================
  // SEND TO FLASK
  // ==========================================
  if (WiFi.status()
      == WL_CONNECTED) {

    HTTPClient http;

    http.begin(
        serverName);

    http.addHeader(
      "Content-Type",
      "application/json"
    );

    String jsonData =
        "{";

    jsonData +=
        "\"voltage\":";
    jsonData +=
        String(
        mainsVoltage,
        1);

    jsonData +=
        ",\"current\":";
    jsonData +=
        String(
        rmsCurrent,
        2);

    jsonData +=
        ",\"power\":";
    jsonData +=
        String(
        power,
        1);

    jsonData +=
        ",\"energy\":";
    jsonData +=
        String(
        energy_kWh,
        5);

    jsonData +=
        ",\"status\":\"";
    jsonData +=
        status;
    jsonData +=
        "\"";

    jsonData +=
        ",\"theft\":\"";
    jsonData +=
        theft;
    jsonData +=
        "\"";

    jsonData +=
        "}";

    int httpCode =
        http.POST(
        jsonData);

    Serial.print(
        "HTTP: ");
    Serial.println(
        httpCode);

    http.end();
  }

  delay(1000);
}
