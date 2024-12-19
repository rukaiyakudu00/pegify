;; Pegify: Bitcoin-backed Stablecoin Platform
;; Author: Pegify Team
;; Version: 1.0.3

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant COLLATERAL-RATIO u150) ;; 150% collateralization ratio
(define-constant LIQUIDATION-RATIO u120) ;; 120% liquidation threshold
(define-constant MINIMUM-COLLATERAL u100000) ;; Minimum collateral in sats
(define-constant STABILITY-FEE u5) ;; 0.5% annual stability fee
(define-constant MAX-UINT u340282366920938463463374607431768211455) ;; Maximum uint value
(define-constant MAX-PRICE u1000000000) ;; Maximum price (10,000 USD per sat)
(define-constant BLOCKS-PER-YEAR u52560) ;; Approximate number of blocks per year

;; Data Variables
(define-data-var total-supply uint u0)
(define-data-var price-oracle uint u0)

;; Data Maps
(define-map vaults
    principal
    {
        collateral-amount: uint,
        debt-amount: uint,
        accrued-interest: uint,
        last-update: uint
    }
)

;; Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u101))
(define-constant ERR-BELOW-LIQUIDATION (err u102))
(define-constant ERR-VAULT-NOT-FOUND (err u103))
(define-constant ERR-WITHDRAWAL-EXCEEDS-AVAILABLE (err u104))
(define-constant ERR-BELOW-MINIMUM-COLLATERAL (err u105))
(define-constant ERR-INVALID-AMOUNT (err u106))
(define-constant ERR-INVALID-PRICE (err u107))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u108))

;; Helper Functions
(define-private (calculate-interest (debt uint) (blocks uint))
    (let (
        (interest-rate (/ (* STABILITY-FEE debt blocks) (* BLOCKS-PER-YEAR u1000)))
    )
    interest-rate)
)

(define-private (update-accrued-interest (vault-data {collateral-amount: uint, debt-amount: uint, accrued-interest: uint, last-update: uint}))
    (let (
        (blocks-passed (- block-height (get last-update vault-data)))
        (new-interest (calculate-interest (get debt-amount vault-data) blocks-passed))
    )
    (+ (get accrued-interest vault-data) new-interest))
)

;; Read-Only Functions
(define-read-only (get-vault (owner principal))
    (map-get? vaults owner)
)

(define-read-only (get-collateral-ratio (owner principal))
    (let (
        (vault (unwrap! (get-vault owner) ERR-VAULT-NOT-FOUND))
        (collateral-value (* (get collateral-amount vault) (var-get price-oracle)))
        (total-debt (+ (get debt-amount vault) (update-accrued-interest vault)))
    )
    (if (is-eq total-debt u0)
        (ok u0)
        (ok (/ (* collateral-value u100) total-debt))
    ))
)

(define-read-only (get-withdrawable-collateral (owner principal))
    (let (
        (vault (unwrap! (get-vault owner) ERR-VAULT-NOT-FOUND))
        (collateral-amount (get collateral-amount vault))
        (total-debt (+ (get debt-amount vault) (update-accrued-interest vault)))
        (collateral-value (* collateral-amount (var-get price-oracle)))
        (minimum-required-collateral (/ (* total-debt COLLATERAL-RATIO) (var-get price-oracle)))
    )
    (if (is-eq total-debt u0)
        (ok collateral-amount)
        (ok (- collateral-amount minimum-required-collateral))))
)

;; Public Functions
(define-public (create-vault (collateral-amount uint))
    (let (
        (sender tx-sender)
        (existing-vault (get-vault sender))
    )
    (asserts! (>= collateral-amount MINIMUM-COLLATERAL) ERR-INSUFFICIENT-COLLATERAL)
    (asserts! (is-none existing-vault) ERR-VAULT-NOT-FOUND)
    
    (map-set vaults
        sender
        {
            collateral-amount: collateral-amount,
            debt-amount: u0,
            accrued-interest: u0,
            last-update: block-height
        }
    )
    (ok true))
)

(define-public (mint-stablecoin (amount uint))
    (let (
        (sender tx-sender)
        (vault (unwrap! (get-vault sender) ERR-VAULT-NOT-FOUND))
        (new-debt (+ (get debt-amount vault) amount))
        (updated-interest (update-accrued-interest vault))
        (collateral-value (* (get collateral-amount vault) (var-get price-oracle)))
        (total-debt (+ new-debt updated-interest))
        (new-ratio (/ (* collateral-value u100) total-debt))
    )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (<= (+ (var-get total-supply) amount) MAX-UINT) ERR-INVALID-AMOUNT)
    (asserts! (>= new-ratio COLLATERAL-RATIO) ERR-INSUFFICIENT-COLLATERAL)
    
    (map-set vaults
        sender
        {
            collateral-amount: (get collateral-amount vault),
            debt-amount: new-debt,
            accrued-interest: updated-interest,
            last-update: block-height
        }
    )
    (var-set total-supply (+ (var-get total-supply) amount))
    (ok true))
)

(define-public (repay-interest (amount uint))
    (let (
        (sender tx-sender)
        (vault (unwrap! (get-vault sender) ERR-VAULT-NOT-FOUND))
        (updated-interest (update-accrued-interest vault))
    )
    (asserts! (>= updated-interest amount) ERR-INSUFFICIENT-PAYMENT)
    
    (map-set vaults
        sender
        {
            collateral-amount: (get collateral-amount vault),
            debt-amount: (get debt-amount vault),
            accrued-interest: (- updated-interest amount),
            last-update: block-height
        }
    )
    (ok true))
)

(define-public (repay-stablecoin (amount uint))
    (let (
        (sender tx-sender)
        (vault (unwrap! (get-vault sender) ERR-VAULT-NOT-FOUND))
        (current-debt (get debt-amount vault))
        (updated-interest (update-accrued-interest vault))
    )
    (asserts! (>= current-debt amount) ERR-INSUFFICIENT-COLLATERAL)
    
    (map-set vaults
        sender
        {
            collateral-amount: (get collateral-amount vault),
            debt-amount: (- current-debt amount),
            accrued-interest: updated-interest,
            last-update: block-height
        }
    )
    (var-set total-supply (- (var-get total-supply) amount))
    (ok true))
)

(define-public (withdraw-collateral (amount uint))
    (let (
        (sender tx-sender)
        (vault (unwrap! (get-vault sender) ERR-VAULT-NOT-FOUND))
        (current-collateral (get collateral-amount vault))
        (current-debt (get debt-amount vault))
        (withdrawable (unwrap! (get-withdrawable-collateral sender) ERR-VAULT-NOT-FOUND))
    )
    (asserts! (<= amount withdrawable) ERR-WITHDRAWAL-EXCEEDS-AVAILABLE)
    (asserts! (>= (- current-collateral amount) MINIMUM-COLLATERAL) ERR-BELOW-MINIMUM-COLLATERAL)
    
    (map-set vaults
        sender
        {
            collateral-amount: (- current-collateral amount),
            debt-amount: current-debt,
            accrued-interest: (update-accrued-interest vault),
            last-update: block-height
        }
    )
    (ok true))
)

(define-public (liquidate-vault (owner principal))
    (let (
        (vault (unwrap! (get-vault owner) ERR-VAULT-NOT-FOUND))
        (ratio (unwrap! (get-collateral-ratio owner) ERR-VAULT-NOT-FOUND))
    )
    (asserts! (< ratio LIQUIDATION-RATIO) ERR-NOT-AUTHORIZED)
    
    (map-delete vaults owner)
    (var-set total-supply (- (var-get total-supply) (get debt-amount vault)))
    (ok true))
)

;; Admin Functions
(define-public (update-price-oracle (new-price uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (and (> new-price u0) (<= new-price MAX-PRICE)) ERR-INVALID-PRICE)
        (var-set price-oracle new-price)
        (ok true))
)