;; CraftWeave Marketplace Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-not-found (err u101))
(define-constant err-listing-exists (err u102))
(define-constant err-insufficient-funds (err u103))

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

;; Storage
(define-data-var next-listing-id uint u1)

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

(define-public (purchase-item (listing-id uint))
    (let
        (
            (listing (unwrap! (map-get? Listings {listing-id: listing-id}) err-not-found))
            (price (get price listing))
            (seller (get seller listing))
            (fee (/ (* price (var-get platform-fee)) u1000))
        )
        (asserts! (get available listing) err-not-found)
        (try! (stx-transfer? price tx-sender seller))
        (try! (stx-transfer? fee tx-sender contract-owner))
        (map-set Listings
            {listing-id: listing-id}
            (merge listing {available: false})
        )
        (ok true)
    )
)

(define-public (create-profile (name (string-ascii 50)) (bio (string-ascii 500)))
    (map-set SellerProfiles
        {seller: tx-sender}
        {
            name: name,
            bio: bio,
            rating: u0,
            review-count: u0
        }
    )
    (ok true)
)

(define-public (leave-review (seller principal) (rating uint))
    (let
        (
            (profile (unwrap! (map-get? SellerProfiles {seller: seller}) err-not-found))
            (current-rating (get rating profile))
            (review-count (get review-count profile))
            (new-count (+ review-count u1))
            (new-rating (/ (+ (* current-rating review-count) rating) new-count))
        )
        (map-set SellerProfiles
            {seller: seller}
            (merge profile {
                rating: new-rating,
                review-count: new-count
            })
        )
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-listing (listing-id uint))
    (map-get? Listings {listing-id: listing-id})
)

(define-read-only (get-seller-profile (seller principal))
    (map-get? SellerProfiles {seller: seller})
)