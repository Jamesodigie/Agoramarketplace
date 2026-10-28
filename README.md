# Agora Marketplace

Clickable prototype of Agora, an escrow-protected marketplace for Lagos. Buyers pay into escrow, sellers are verified, and money is released only after the buyer confirms delivery.

Built from the Agora Figma file. It's a single `index.html` with no build step and no dependencies.

## Run it

Open `index.html` in a browser, or turn on GitHub Pages (Settings → Pages → Deploy from branch `main`, folder `/root`).

## What's in it

- **Animated hero:** a splash screen, then the welcome screen with a drifting security pattern, the bag logo dropping in and the checkmark drawing itself
- **Buyer onboarding:** create account (Google, Apple or email), sign in, forgot password with an OTP code, a three-slide intro and an "all set" screen
- **Shopping:** home feed with category filters, search, product detail with sizes, cart with quantities
- **Checkout:** delivery details, review and payment by card or bank transfer, ending in success, pending or failed
- **Order tracking:** dispatch and delivery, photo confirmation, rating
- **Account:** profile, orders with tabs, saved addresses, how escrow works, settings, personal info, password and security
- **Seller:** ID verification, store setup, adding products, verification pending and approved, dashboard, payouts, funds held in escrow

Buttons labelled **"Prototype: …"** stand in for things a backend would do, such as a seller dispatching an order or a payment failing.
