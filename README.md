# Agora Marketplace

Clickable prototype of Agora, an escrow-protected marketplace for Lagos. Buyers pay into escrow, sellers are verified, and money is released only after the buyer confirms delivery.

Built from the Agora Figma file. It's a single `index.html` with no build step and no dependencies.

## Run it

- **Web:** https://jamesodigie.github.io/Agoramarketplace/ (or open `index.html` locally).
- **Install from the browser:** open the web link on your phone, then use *Add to Home Screen* (Chrome or Safari). It opens full screen like an app and works offline.
- **Android APK:** every push to `main` builds a new APK. Download **Agora.apk** from the latest release on your Android phone: https://github.com/Jamesodigie/Agoramarketplace/releases/latest. When the phone asks, allow your browser to install unknown apps.

## How the APK is built

`.github/workflows/android-apk.yml` wraps `index.html` in a native Android shell with [Capacitor](https://capacitorjs.com), generates the icon and splash screen from `assets/`, builds with Gradle and publishes the APK to Releases.

Every build is signed with the same key in `android-signing/`, so a new version installs over the old one. That key is a **debug key for testing only**. Before publishing on the Play Store, create a private release key and keep it out of the repo.

## What's in it

- **Intro:** the logo splash, then three swipeable slides, each with its own colour and a live UI scene that builds itself step by step (verified seller search, escrow checkout, order tracking with payout). Ends on a "Welcome to Agora, join as a Buyer or Seller" picker.
- **Seller verification (6 steps):** about you, store setup (name, link, categories, logo), business details (CAC number and certificate, or individual seller, plus socials), address with proof of address (buyers see only the area), identity (ID number, ID photo, selfie), and payout account with an account-name check. Then a review screen, an animated verification checklist and an approved screen.
- **Store trust page:** buyers tap any seller to see their verified badges, CAC number, area, ratings, reviews, return policy and products.
- **Buyer onboarding:** create account (Google, Apple or email), sign in, forgot password with an OTP code and an "all set" screen
- **Shopping:** home feed with category filters, search, product detail with sizes, cart with quantities
- **Checkout:** delivery details, review and payment by card or bank transfer, ending in success, pending or failed
- **Order tracking:** dispatch and delivery, photo confirmation, rating
- **Account:** profile, orders with tabs, saved addresses, how escrow works, settings, personal info, password and security
- **Seller dashboard:** payouts, funds held in escrow, adding products

Buttons labelled **"Prototype: …"** stand in for things a backend would do, such as a seller dispatching an order or a payment failing.
