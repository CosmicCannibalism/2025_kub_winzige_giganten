// cosmiccannibalism 
// kunst- und brotmuseum ulm
// winzige giganten exhibition
// ROBERT HOOKE VERSION (index01.html)
//
// Video duration: ~154 seconds
// Relay timing: 155000ms (155s)
//
// •reads mechanical start button
// •sends keyboard Space event on button press
// •relay opens when movie is playing (timer)

#include <Keyboard.h>

bool buttonLocked = false;               // Cooldown lock flag

const int buttonPin = 6;                 // Pin where the button is connected
const unsigned long debounceDelay = 50;  // Debounce time in milliseconds
const unsigned long cooldownDelay = 200; // Cooldown time after valid press (in ms)
bool lastButtonState = HIGH;             // Start with HIGH because of pull-up
const int relayPin = 7;                  // Relay pin (change as needed)
const unsigned long relayDuration = 155000; // Relay open duration for Robert Hooke video (155s)
unsigned long relayOpenedAt = 0;
bool relayOpen = false;
unsigned long lastDebounceTime = 0;

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
  }

  // On valid button press: send Space, open relay, reset timer
  if (reading == LOW &&
      (currentTime - lastDebounceTime > debounceDelay) &&
      !buttonLocked &&
      (currentTime - relayOpenedAt > cooldownDelay)) {
    Keyboard.press(' ');
    delay(30);
    Keyboard.release(' ');
    digitalWrite(relayPin, HIGH);
    relayOpenedAt = currentTime;
    relayOpen = true;
    buttonLocked = true;
  }

  // Reset cooldown lock when button is released
  if (reading == HIGH) {
    buttonLocked = false;
  }

  // Close relay after duration
  if (relayOpen && (currentTime - relayOpenedAt >= relayDuration)) {
    digitalWrite(relayPin, LOW);
    relayOpen = false;
  }
}
