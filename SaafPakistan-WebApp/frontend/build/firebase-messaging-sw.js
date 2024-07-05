// Scripts for firebase and firebase messaging
importScripts(
  "https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js"
);

// Initialize the Firebase app in the service worker by passing the generated config
var firebaseConfig = {
  apiKey: "AIzaSyBYnKgYWS4euL5VzVvCfTlRx7ejkPhCDsI",
  authDomain: "saafpakistan123.firebaseapp.com",
  projectId: "saafpakistan123",
  storageBucket: "saafpakistan123.appspot.com",
  messagingSenderId: "355966022483",
  appId: "1:355966022483:web:ee8efcce96f5b2d7dca7a6",
  measurementId: "G-W5CMSHMF5W",
};

firebase.initializeApp(firebaseConfig);

// Retrieve firebase messaging
const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
  console.log("Received background message ", payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
