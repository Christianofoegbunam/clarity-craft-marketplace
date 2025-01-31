;; CraftWeave Marketplace Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-not-found (err u101))
(define-constant err-listing-exists (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-not-seller (err u104))
(define-constant err-not-buyer (err u105))
(define-constant err-invalid-state (err u106))

;; Data Variables
(define-data-var platform-fee uint u25) ;; 2.5%

;; Data Maps
(define-map Listings
    { listing-id: uint }
    {
        seller: principal,
        title: (string-ascii 100),
        description: (string-ascii 500),
        price: uint,
        available: bool
    }
)

(define-map SellerProfiles
    { seller: principal }
    {
        name: (string-ascii 50),
        bio: (string-ascii 500),
        rating: uint,
        review-count: uint
    }
)

(define-map Escrows
    { escrow-id: uint }
    {
        listing-id: uint,
        buyer: principal,
        seller: principal,
        amount: uint,
        status: (string-ascii 20), ;; "pending", "completed", "refunded"
        created-at: uint
    }
)

;; Storage
(define-data-var next-listing-id uint u1)
(define-data-var next-escrow-id uint u1)

;; Public Functions
(define-public (list-item (title (string-ascii 100)) (description (string-ascii 500)) (price uint))
    (let
        (
            (listing-id (var-get next-listing-id))
        )
        (asserts! (not (default-to false (map-get? Listings {listing-id: listing-id}))) err-listing-exists)
        (try! (map-set Listings
            {listing-id: listing-id}
            {
                seller: tx-sender,
                title: title,
                description: description,
                price: price,
                available: true
            }
        ))
        (var-set next-listing-id (+ listing-id u1))
        (ok listing-id)
    )
)

(define-public (create-escrow (listing-id uint))
    (let
        (
            (listing (unwrap! (map-get? Listings {listing-id: listing-id}) err-not-found))
            (escrow-id (var-get next-escrow-id))
            (price (get price listing))
        )
        (asserts! (get available listing) err-not-found)
        (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
        (try! (map-set Escrows
            {escrow-id: escrow-id}
            {
                listing-id: listing-id,
                buyer: tx-sender,
                seller: (get seller listing),
                amount: price,
                status: "pending",
                created-at: block-height
            }
        ))
        (var-set next-escrow-id (+ escrow-id u1))
        (ok escrow-id)
    )
)

(define-public (release-escrow (escrow-id uint))
    (let
        (
            (escrow (unwrap! (map-get? Escrows {escrow-id: escrow-id}) err-not-found))
            (listing-id (get listing-id escrow))
            (amount (get amount escrow))
            (fee (/ (* amount (var-get platform-fee)) u1000))
        )
        (asserts! (is-eq (get status escrow) "pending") err-invalid-state)
        (asserts! (is-eq (get buyer escrow) tx-sender) err-not-buyer)
        (try! (as-contract (stx-transfer? (- amount fee) (as-contract tx-sender) (get seller escrow))))
        (try! (as-contract (stx-transfer? fee (as-contract tx-sender) contract-owner)))
        (try! (map-set Escrows
            {escrow-id: escrow-id}
            (merge escrow {status: "completed"})
        ))
        (map-set Listings
            {listing-id: listing-id}
            (merge (unwrap! (map-get? Listings {listing-id: listing-id}) err-not-found)
                {available: false})
        )
        (ok true)
    )
)

(define-public (refund-escrow (escrow-id uint))
    (let
        (
            (escrow (unwrap! (map-get? Escrows {escrow-id: escrow-id}) err-not-found))
            (amount (get amount escrow))
        )
        (asserts! (is-eq (get status escrow) "pending") err-invalid-state)
        (asserts! (is-eq (get seller escrow) tx-sender) err-not-seller)
        (try! (as-contract (stx-transfer? amount (as-contract tx-sender) (get buyer escrow))))
        (try! (map-set Escrows
            {escrow-id: escrow-id}
            (merge escrow {status: "refunded"})
        ))
        (ok true)
    )
)

;; Previous functions remain unchanged...

;; New read-only functions
(define-read-only (get-escrow (escrow-id uint))
    (map-get? Escrows {escrow-id: escrow-id})
)
