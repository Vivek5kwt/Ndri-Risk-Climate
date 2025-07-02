// web/firebase-messaging-sw.js

// Give this file MIME type “application/javascript” when served
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing in
// your app’s Firebase config (same as DefaultFirebaseOptions.web)
firebase.initializeApp({
  apiKey: 'AIzaSyAnEEdu0pqeeIm3Too_9JobDYeH-wAmxrQ',
  authDomain: 'ndri-risk-app.firebaseapp.com',
  projectId: 'ndri-risk-app',
  storageBucket: 'ndri-risk-app.firebasestorage.app',
  messagingSenderId: '1001685338819',
  appId: '1:1001685338819:web:d43a357d3d5f7f71277076',
});

// Retrieve an instance of Firebase Messaging so that it can handle background
// messages.
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here
  const { title, ...options } = payload.notification || {};
  self.registration.showNotification(title || 'Background Message Title', options);
});
