#include <SPI.h>
#include <MFRC522.h>
#include <Servo.h>
#include <LiquidCrystal.h>

// ---------- PIN DEFINITIONS ----------
#define LCD_RS   2
#define LCD_E    3
#define LCD_D4   4
#define LCD_D5   5
#define LCD_D6   6
#define LCD_D7   7

#define SERVO_PIN    8

#define RFID_RST_PIN 9
#define RFID_SS_PIN  10

#define ULTRASONIC_TRIG A0
#define ULTRASONIC_ECHO A1

#define GREEN_LED A2
#define RED_LED   A3
#define BUZZER    A4

// ---------- OBJECTS ----------
LiquidCrystal lcd(LCD_RS, LCD_E, LCD_D4, LCD_D5, LCD_D6, LCD_D7);
MFRC522 mfrc522(RFID_SS_PIN, RFID_RST_PIN);
Servo doorServo;

// ---------- CONFIG ----------
const int OPEN_ANGLE = 90;   // servo angle when door opens
const int CLOSED_ANGLE = 180;  // servo angle when door is closed
const int DISTANCE_THRESHOLD_CM = 8;  // ultrasonic trigger distance
const int MAX_INVALID_TRIES = 3;

// CARD UID: A3 5C 8C 14
byte authorizedUID[] = { 0xA3, 0x5C, 0x8C, 0x14 };
const byte authorizedUIDSize = 4;

// ---------- STATE ----------
int invalidTries = 0;
bool carPresent = false;

// ---------- HELPER FUNCTIONS ----------

long getDistanceCm() {
  // Send trigger pulse
  digitalWrite(ULTRASONIC_TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(ULTRASONIC_TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(ULTRASONIC_TRIG, LOW);

  // Read echo pulse
  long duration = pulseIn(ULTRASONIC_ECHO, HIGH, 25000); // 25 ms timeout
  if (duration == 0) return 999; // no echo, treat as "far away"

  long distance = duration * 0.034 / 2; // speed of sound: 0.034 cm/us
  return distance;
}

bool isAuthorizedUID(byte *uid, byte uidSize) {
  if (uidSize < authorizedUIDSize) return false;

  for (byte i = 0; i < authorizedUIDSize; i++) {
    if (uid[i] != authorizedUID[i]) return false;
  }
  return true;
}

void beepBuzzer(int times) {
  for (int i = 0; i < times; i++) {
    tone(BUZZER, 1000);
    delay(200);
    noTone(BUZZER);
    delay(200);
  }
}

void lockoutIllegalUser() {
  lcd.clear();
  lcd.display();
  lcd.setCursor(0, 0);
  lcd.print("ILLEGAL USER");
  digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED, HIGH);
  beepBuzzer(5);
  delay(3000);  // hold message

  // Reset state after lockout
  lcd.clear();
  lcd.noDisplay();
  digitalWrite(RED_LED, LOW);
  invalidTries = 0;
  carPresent = false;
}

// ---------- SETUP ----------
void setup() {
  Serial.begin(9600);

  // LCD
  lcd.begin(16, 2);
  lcd.noDisplay(); // start with blank screen

  // Servo
  doorServo.attach(SERVO_PIN);
  doorServo.write(CLOSED_ANGLE);

  // LEDs & buzzer
  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(BUZZER, OUTPUT);
  digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED, LOW);
  noTone(BUZZER);

  // Ultrasonic
  pinMode(ULTRASONIC_TRIG, OUTPUT);
  pinMode(ULTRASONIC_ECHO, INPUT);

  // RFID
  SPI.begin();
  mfrc522.PCD_Init();
}

// ---------- MAIN LOOP ----------
void loop() {
  long distance = getDistanceCm();

  // --- No car / object in front ---
  if (distance >= DISTANCE_THRESHOLD_CM) {
    if (carPresent) {
      // object just left -> reset state
      lcd.clear();
      lcd.noDisplay();
      invalidTries = 0;
      carPresent = false;
      digitalWrite(GREEN_LED, LOW);
      digitalWrite(RED_LED, LOW);
      noTone(BUZZER);
      doorServo.write(CLOSED_ANGLE);
    }
    delay(100);
    return;
  }

  // --- Object detected (< threshold) ---
  if (!carPresent) {
    carPresent = true;
    invalidTries = 0;
    lcd.clear();
    lcd.display();
    lcd.setCursor(0, 0);
    lcd.print("Scan ID");
  }

  // Check for RFID card
  if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) {
    // no card yet
    return;
  }

  // We have a card
  if (isAuthorizedUID(mfrc522.uid.uidByte, mfrc522.uid.size)) {
    // ----- AUTHORIZED CARD -----
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Welcome home!");
    digitalWrite(GREEN_LED, HIGH);
    digitalWrite(RED_LED, LOW);
    noTone(BUZZER);

    doorServo.write(OPEN_ANGLE);
    delay(5000);           // door stays open
    doorServo.write(CLOSED_ANGLE);

    // Reset state
    digitalWrite(GREEN_LED, LOW);
    lcd.clear();
    lcd.noDisplay();
    carPresent = false;
    invalidTries = 0;
  } else {
    // ----- UNAUTHORIZED CARD -----
    invalidTries++;

    if (invalidTries >= MAX_INVALID_TRIES) {
      mfrc522.PICC_HaltA();
      mfrc522.PCD_StopCrypto1();
      lockoutIllegalUser();
      return;
    } else {
      lcd.clear();
      lcd.display();
      lcd.setCursor(0, 0);
      lcd.print("Invalid ID!");
      lcd.setCursor(0, 1);
      lcd.print("Try again");
      beepBuzzer(1);
      digitalWrite(RED_LED, HIGH);
      delay(1500);
      digitalWrite(RED_LED, LOW);
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Scan ID");
    }
  }

  // Stop communication with the card
  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
}
