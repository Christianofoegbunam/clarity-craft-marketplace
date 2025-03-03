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
(define-constant err-escrow-expired (err u107))
(define-constant err-invalid-price (err u108))
(define-constant err-below-minimum (err u109))
(define-constant max-price u1000000000000) ;; 1M STX maximum price
(define-constant min-price u1000) ;; Minimum price to ensure meaningful fee calculation

;; Data Variables 
(define-data-var platform-fee uint u25) ;; 2.5%
(define-data-var escrow-timeout uint u144) ;; ~24 hours in blocks

;; Status enumeration
(define-constant STATUS-PENDING "pending")
(define-constant STATUS-COMPLETED "completed")
(define-constant STATUS-REFUNDED "refunded")

;; [Previous data maps remain unchanged...]

;; Public Functions
(define-public (list-item (title (string-ascii 100)) (description (string-ascii 500)) (price uint))
    (let
        (
            (listing-id (var-get next-listing-id))
        )
        (asserts! (>= price min-price) err-below-minimum)
        (asserts! (<= price max-price) err-invalid-price)
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

(define-public (release-escrow (escrow-id uint))
    (let
        (
            (escrow (unwrap! (map-get? Escrows {escrow-id: escrow-id}) err-not-found))
            (listing-id (get listing-id escrow))
            (amount (get amount escrow))
            (fee (/ (* amount (var-get platform-fee)) u1000))
            (seller-amount (- amount fee))
        )
        ;; Validate conditions first
        (asserts! (is-eq (get status escrow) STATUS-PENDING) err-invalid-state)
        (asserts! (is-eq (get buyer escrow) tx-sender) err-not-buyer)
        (asserts! (not (is-escrow-expired escrow)) err-escrow-expired)
        
        ;; Update state before transfers
        (try! (map-set Escrows
            {escrow-id: escrow-id}
            (merge escrow {status: STATUS-COMPLETED})
        ))
        (try! (map-set Listings
            {listing-id: listing-id}
            (merge (unwrap! (map-get? Listings {listing-id: listing-id}) err-not-found)
                {available: false})
        ))
        
        ;; Perform transfers after state updates
        (try! (stx-transfer? seller-amount (as-contract tx-sender) (get seller escrow)))
        (try! (stx-transfer? fee (as-contract tx-sender) contract-owner))
        
        (ok true)
    )
)

;; [Remaining functions unchanged...]
