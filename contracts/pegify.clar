;; Pegify: Bitcoin-backed Stablecoin Platform
;; Author: Pegify Team
;; Version: 1.0.0

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant COLLATERAL-RATIO u150) ;; 150% collateralization ratio
(define-constant LIQUIDATION-RATIO u120) ;; 120% liquidation threshold
(define-constant MINIMUM-COLLATERAL u100000) ;; Minimum collateral in sats
(define-constant STABILITY-FEE u5) ;; 0.5% annual stability fee

;; Data Variables
(define-data-var total-supply uint u0)
(define-data-var price-oracle uint u0)

;; Data Maps
(define-map vaults
    principal
    {
        collateral-amount: uint,
        debt-amount: uint,
        last-update: uint
    }
)

;; Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u101))
(define-constant ERR-BELOW-LIQUIDATION (err u102))
(define-constant ERR-VAULT-NOT-FOUND (err u103))

;; Read-Only Functions
(define-read-only (get-vault (owner principal))
    (map-get? vaults owner)
)

(define-read-only (get-collateral-ratio (owner principal))
    (let (
        (vault (unwrap! (get-vault owner) ERR-VAULT-NOT-FOUND))
        (collateral-value (* (get collateral-amount vault) (var-get price-oracle)))
        (debt-value (get debt-amount vault))
    )
    (if (is-eq debt-value u0)
        (ok u0)
        (ok (/ (* collateral-value u100) debt-value))
    ))
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
        (collateral-value (* (get collateral-amount vault) (var-get price-oracle)))
        (new-ratio (/ (* collateral-value u100) new-debt))
    )
    (asserts! (>= new-ratio COLLATERAL-RATIO) ERR-INSUFFICIENT-COLLATERAL)
    
    (map-set vaults
        sender
        {
            collateral-amount: (get collateral-amount vault),
            debt-amount: new-debt,
            last-update: block-height
        }
    )
    (var-set total-supply (+ (var-get total-supply) amount))
    (ok true))
)

(define-public (repay-stablecoin (amount uint))
    (let (
        (sender tx-sender)
        (vault (unwrap! (get-vault sender) ERR-VAULT-NOT-FOUND))
        (current-debt (get debt-amount vault))
    )
    (asserts! (>= current-debt amount) ERR-INSUFFICIENT-COLLATERAL)
    
    (map-set vaults
        sender
        {
            collateral-amount: (get collateral-amount vault),
            debt-amount: (- current-debt amount),
            last-update: block-height
        }
    )
    (var-set total-supply (- (var-get total-supply) amount))
    (ok true))
)

(define-public (liquidate-vault (owner principal))
    (let (
        (vault (unwrap! (get-vault owner) ERR-VAULT-NOT-FOUND))
        (ratio (unwrap! (get-collateral-ratio owner) ERR-VAULT-NOT-FOUND))
    )
    (asserts! (< ratio LIQUIDATION-RATIO) ERR-NOT-AUTHORIZED)
    
    ;; Transfer collateral to liquidator (tx-sender)
    (map-delete vaults owner)
    (var-set total-supply (- (var-get total-supply) (get debt-amount vault)))
    (ok true))
)

;; Admin Functions
(define-public (update-price-oracle (new-price uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (var-set price-oracle new-price)
        (ok true))
)