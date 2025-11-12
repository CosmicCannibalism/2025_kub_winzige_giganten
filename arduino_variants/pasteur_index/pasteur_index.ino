// cosmiccannibalism 
// kunst- und brotmuseum ulm
// winzige giganten exhibition
// PASTEUR VERSION (index.html)
//
// Video duration: ~117.9 seconds
// Relay timing: 500ms delay + 117500ms duration (118s total)
//
// •reads mechanical start button
// •sends keyboard Space event on button press
// •sends 'l' on 6 second long-press (return to trailer)
// •relay opens when movie is playing (timer)

#include <Keyboard.h>

bool buttonLocked = false;               // Cooldown lock flag

const int buttonPin = 6;                 // Pin where the button is connected
const unsigned long debounceDelay = 50;  // Debounce time in milliseconds
const unsigned long cooldownDelay = 200; // Cooldown time after valid press (in ms)
const unsigned long longPressThreshold = 6000; // Long-press threshold (6 seconds)
bool lastButtonState = HIGH;             // Start with HIGH because of pull-up
const int relayPin = 7;                  // Relay pin (change as needed)
const unsigned long relayDelay = 500;    // Delay before relay opens (500ms)
const unsigned long relayDuration = 117500; // Relay open duration for Pasteur video (118s - 500ms)
unsigned long buttonPressedAt = 0;
unsigned long relayOpenedAt = 0;
bool relayOpen = false;
bool relayPending = false;
unsigned long lastDebounceTime = 0;
unsigned long buttonDownTime = 0;        // Track when button was first pressed
bool longPressSent = false;              // Track if long-press 'l' was already sent

void setup() {
  pinMode(buttonPin, INPUT_PULLUP);
  pinMode(relayPin, OUTPUT);                       
  digitalWrite(relayPin, LOW); // relay initially closed
  Keyboard.begin();
}

void loop() {
  int reading = digitalRead(buttonPin);
  unsigned long currentTime = millis();

  // Debounce check for the button
  if (reading != lastButtonState) {
    lastDebounceTime = currentTime;
    lastButtonState = reading;
    
    // Button pressed down - start tracking for long-press
    if (reading == LOW) {
      buttonDownTime = currentTime;
      longPressSent = false;
    }
  }

  // Check for long-press (6 seconds held down)
  if (reading == LOW && !longPressSent && 
      (currentTime - buttonDownTime >= longPressThreshold)) {
    Keyboard.press('l');
    delay(30);
    Keyboard.release('l');
    longPressSent = true; // Only send once per hold
  }

  // On valid button press: send Space, schedule relay open, reset timer
  if (reading == LOW &&
      (currentTime - lastDebounceTime > debounceDelay) &&
      !buttonLocked &&
      (currentTime - relayOpenedAt > cooldownDelay)) {
    Keyboard.press(' ');
    delay(30);
    Keyboard.release(' ');
    buttonPressedAt = currentTime;
    relayPending = true;
    buttonLocked = true;
  }

  // Reset cooldown lock when button is released
  if (reading == HIGH) {
    buttonLocked = false;
  }

  // Open relay after delay
  if (relayPending && (currentTime - buttonPressedAt >= relayDelay)) {
    digitalWrite(relayPin, HIGH);
    relayOpenedAt = currentTime;
    relayOpen = true;
    relayPending = false;
  }

  // Close relay after duration
  if (relayOpen && (currentTime - relayOpenedAt >= relayDuration)) {
    digitalWrite(relayPin, LOW);
    relayOpen = false;
  }
}
