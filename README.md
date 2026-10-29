# Agora Marketplace

Escrow-protected marketplace for Nigeria. Buyers pay into escrow, sellers are verified, and money is released only after the buyer confirms delivery.

## The app (Flutter: Android, iOS, web)

The real app lives in [`app/`](app). It's one Flutter codebase that builds for Android, iPhone and the web.

- **Download for Android:** https://github.com/Jamesodigie/Agoramarketplace/releases/latest/download/Agora.apk
- **iPhone:** every build also produces an unsigned iOS app. Installing it on an iPhone needs an Apple Developer account (TestFlight or the App Store).
- **How it's built:** `.github/workflows/flutter.yml` checks the code, runs the tests, then builds the Android APK, the iOS app and the web app on every push, and publishes them to Releases.

### Work on it locally

1. Install Flutter 3.29 or newer.
2. `cd app && flutter pub get`
3. `flutter run` with a phone or simulator connected (or `flutter run -d chrome`).

Code layout: `lib/screens/` holds the screens (intro, auth, shop, checkout, orders, account, seller onboarding, seller dashboard and store page), `lib/widgets.dart` the shared components, `lib/state.dart` the app state and `lib/data.dart` the sample products and sellers.

## Web prototype (HTML)

The original clickable prototype is `index.html` at the root of the repo, served at https://jamesodigie.github.io/Agoramarketplace/.

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
