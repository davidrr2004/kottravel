#include <WiFi.h>
#include <FirebaseESP32.h>

// Replace with your network credentials
#define WIFI_SSID "OP"
#define WIFI_PASSWORD "12345678"

// Replace with your Firebase project credentials
#define API_KEY "AIzaSyAFr3s-8-cP8EAeKKCmXZGq7PFHpOIuRgk"
#define DATABASE_URL "https://kottravel-2d580-default-rtdb.firebaseio.com/"


// Define Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

void setup() {
  Serial.begin(115200);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.println("Connected to WiFi");

  // Configure Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // Provide anonymous sign-in
  auth.user.email = "";
  auth.user.password = "";

  // Initialize Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // Optional: Wait for sign-in
  while (!Firebase.ready()) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.println("Firebase is ready");

  // Send test data
  if (Firebase.RTDB.setString(&fbdo, "/test/status", "ESP32 connected")) {
    Serial.println("Data sent to Firebase!");
  } else {
    Serial.print("Firebase setString failed: ");
    Serial.println(fbdo.errorReason());
  }
}

void loop() {
  // Nothing here
}
