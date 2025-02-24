;; DeFi Protection Protocol

;; Define error constants with more specific messages
(define-constant ERR_INVALID_AMOUNT (err u100))
(define-constant ERR_INSUFFICIENT_BALANCE (err u101))
(define-constant ERR_PROTECTION_REQUEST_NOT_FOUND (err u102))
(define-constant ERR_UNAUTHORIZED (err u103))
(define-constant ERR_ALREADY_PROTECTED (err u104))
(define-constant ERR_INVALID_PRINCIPAL (err u105))
(define-constant ERR_NOT_PROTECTED (err u106))
(define-constant ERR_ZERO_AMOUNT (err u107))
(define-constant ERR_REQUEST_ALREADY_PROCESSED (err u108))
(define-constant ERR_VAULT_EMPTY (err u109))
(define-constant ERR_REQUEST_NOT_EXPIRED (err u110))
(define-constant ERR_REQUEST_EXCEEDS_PROTECTED (err u111))

;; Define the contract
(define-data-var protection-vault uint u0)
(define-data-var protocol-admin principal tx-sender)
(define-map protected-protocols principal uint)
(define-map protection-requests { requester: principal, amount: uint } { status: (string-ascii 20), timestamp: uint, disbursed-amount: uint })

;; Define the request expiration period (e.g., 30 days in blocks, assuming 10-minute block times)
(define-constant REQUEST_EXPIRATION_PERIOD u4320)

;; Function to purchase protection
(define-public (acquire-protection (amount uint))
  (let ((caller tx-sender))
    (asserts! (> amount u0) ERR_ZERO_AMOUNT)
    (asserts! (is-none (map-get? protected-protocols caller)) ERR_ALREADY_PROTECTED)
    (match (stx-transfer? amount caller (as-contract tx-sender))
      success (begin
        (var-set protection-vault (+ (var-get protection-vault) amount))
        (map-set protected-protocols caller amount)
        (print { event: "protection-acquired", protected-amount: amount, purchaser: caller })
        (ok true))
      error (err error))))

;; Function to submit protection request
(define-public (submit-protection-request (request-amount uint))
  (let (
    (caller tx-sender)
    (protected-amount (default-to u0 (map-get? protected-protocols caller)))
  )
    (asserts! (> request-amount u0) ERR_ZERO_AMOUNT)
    (asserts! (is-some (map-get? protected-protocols caller)) ERR_NOT_PROTECTED)
    (asserts! (>= protected-amount request-amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (is-none (map-get? protection-requests { requester: caller, amount: request-amount })) ERR_REQUEST_ALREADY_PROCESSED)
    (map-set protection-requests { requester: caller, amount: request-amount } { status: "pending", timestamp: block-height, disbursed-amount: u0 })
    (print { event: "protection-requested", requester: caller, request-amount: request-amount, timestamp: block-height })
    (ok true)))

;; Helper function to calculate disbursement amount
(define-private (calculate-disbursement-amount (request-amount uint) (vault-balance uint))
  (if (>= vault-balance request-amount)
      request-amount
      vault-balance))

;; Function to approve and process protection request
(define-public (approve-protection-request (requester principal) (request-amount uint))
  (let (
    (request-key { requester: requester, amount: request-amount })
    (request-data (unwrap! (map-get? protection-requests request-key) ERR_PROTECTION_REQUEST_NOT_FOUND))
    (vault-balance (var-get protection-vault))
    (protected-amount (unwrap! (map-get? protected-protocols requester) ERR_NOT_PROTECTED))
  )
    (asserts! (is-eq tx-sender (var-get protocol-admin)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status request-data) "pending") ERR_REQUEST_ALREADY_PROCESSED)
    (asserts! (> vault-balance u0) ERR_VAULT_EMPTY)
    (asserts! (<= request-amount protected-amount) ERR_REQUEST_EXCEEDS_PROTECTED)
    (asserts! (< (- block-height (get timestamp request-data)) REQUEST_EXPIRATION_PERIOD) ERR_REQUEST_NOT_EXPIRED)
    (let ((disbursement-amount (calculate-disbursement-amount request-amount vault-balance)))
      (match (as-contract (stx-transfer? disbursement-amount tx-sender requester))
        success (begin
          (var-set protection-vault (- vault-balance disbursement-amount))
          (if (< disbursement-amount request-amount)
              (map-set protection-requests request-key { status: "partially-disbursed", timestamp: block-height, disbursed-amount: disbursement-amount })
              (begin
                (map-delete protection-requests request-key)
                (map-delete protected-protocols requester)))
          (print { event: "protection-approved", requester: requester, request-amount: request-amount, disbursement-amount: disbursement-amount })
          (ok disbursement-amount))
        error (err error)))))

;; Function to deny protection request
(define-public (deny-protection-request (requester principal) (request-amount uint))
  (let (
    (request-key { requester: requester, amount: request-amount })
    (request-data (unwrap! (map-get? protection-requests request-key) ERR_PROTECTION_REQUEST_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (var-get protocol-admin)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status request-data) "pending") ERR_REQUEST_ALREADY_PROCESSED)
    (asserts! (< (- block-height (get timestamp request-data)) REQUEST_EXPIRATION_PERIOD) ERR_REQUEST_NOT_EXPIRED)
    (map-set protection-requests request-key { status: "denied", timestamp: (get timestamp request-data), disbursed-amount: u0 })
    (print { event: "protection-denied", requester: requester, request-amount: request-amount })
    (ok true)))

;; Function to check and expire protection request
(define-public (check-and-expire-request (requester principal) (request-amount uint))
  (let (
    (request-key { requester: requester, amount: request-amount })
    (request-data (unwrap! (map-get? protection-requests request-key) ERR_PROTECTION_REQUEST_NOT_FOUND))
  )
    (if (and (is-eq (get status request-data) "pending")
             (>= (- block-height (get timestamp request-data)) REQUEST_EXPIRATION_PERIOD))
        (begin
          (map-set protection-requests request-key { status: "expired", timestamp: (get timestamp request-data), disbursed-amount: u0 })
          (print { event: "protection-expired", requester: requester, request-amount: request-amount })
          (ok true))
        (ok false))))

