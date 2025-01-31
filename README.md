# CraftWeave Marketplace

A decentralized marketplace for artisans and crafters to list and sell their handmade goods. Built on Stacks using Clarity.

## Features
- List handmade items for sale
- Purchase items using STX
- Maintain seller profiles and ratings
- Commission custom items
- Secure escrow system for safe transactions
  - Buyer funds held in escrow until approval
  - Seller protection with secure fund release
  - Refund capability for dispute resolution

## Getting Started
1. Clone the repository
2. Install dependencies with `clarinet install`
3. Run tests with `clarinet test`

## Contract Functions
- `list-item`: List a new handmade item for sale
- `purchase-item`: Purchase a listed item
- `update-listing`: Update an existing listing
- `remove-listing`: Remove a listing from the marketplace
- `create-profile`: Create a seller profile
- `update-profile`: Update seller profile details
- `leave-review`: Leave a review for a seller
- `create-escrow`: Create an escrow for a purchase
- `release-escrow`: Release escrowed funds to seller
- `refund-escrow`: Refund escrowed funds to buyer

## Escrow System
The marketplace includes a secure escrow system to protect both buyers and sellers:

1. Buyer initiates purchase by creating an escrow
2. Funds are locked in the smart contract
3. Upon receiving and approving the item, buyer releases the escrow
4. Seller can initiate refund if needed
5. Platform fee is automatically handled during escrow release
