;; Node Verification Contract
;; Validates grid connection points

(define-data-var admin principal tx-sender)

;; Node status: 0 = pending, 1 = verified, 2 = suspended
(define-map nodes
  { node-id: (string-ascii 24) }
  {
    owner: principal,
    location: (string-ascii 50),
    capacity: uint,
    status: uint,
    registration-time: uint
  }
)

(define-read-only (get-node (node-id (string-ascii 24)))
  (map-get? nodes { node-id: node-id })
)

(define-read-only (is-node-verified (node-id (string-ascii 24)))
  (let ((node (map-get? nodes { node-id: node-id })))
    (if (is-some node)
      (is-eq (get status (unwrap-panic node)) u1)
      false
    )
  )
)

(define-public (register-node
    (node-id (string-ascii 24))
    (location (string-ascii 50))
    (capacity uint))
  (let ((existing-node (map-get? nodes { node-id: node-id })))
    (asserts! (is-none existing-node) (err u1)) ;; Node ID already exists
    (ok (map-set nodes
      { node-id: node-id }
      {
        owner: tx-sender,
        location: location,
        capacity: capacity,
        status: u0, ;; Pending verification
        registration-time: block-height
      }
    ))
  )
)

(define-public (verify-node (node-id (string-ascii 24)))
  (let ((node (map-get? nodes { node-id: node-id })))
    (asserts! (is-some node) (err u2)) ;; Node not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized
    (asserts! (is-eq (get status (unwrap-panic node)) u0) (err u4)) ;; Node not in pending status

    (ok (map-set nodes
      { node-id: node-id }
      (merge (unwrap-panic node) { status: u1 })
    ))
  )
)

(define-public (suspend-node (node-id (string-ascii 24)))
  (let ((node (map-get? nodes { node-id: node-id })))
    (asserts! (is-some node) (err u2)) ;; Node not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized
    (asserts! (is-eq (get status (unwrap-panic node)) u1) (err u5)) ;; Node not in verified status

    (ok (map-set nodes
      { node-id: node-id }
      (merge (unwrap-panic node) { status: u2 })
    ))
  )
)

(define-public (update-node-capacity (node-id (string-ascii 24)) (new-capacity uint))
  (let ((node (map-get? nodes { node-id: node-id })))
    (asserts! (is-some node) (err u2)) ;; Node not found
    (asserts! (is-eq tx-sender (get owner (unwrap-panic node))) (err u3)) ;; Not the owner

    (ok (map-set nodes
      { node-id: node-id }
      (merge (unwrap-panic node) { capacity: new-capacity })
    ))
  )
)

(define-public (transfer-node-ownership (node-id (string-ascii 24)) (new-owner principal))
  (let ((node (map-get? nodes { node-id: node-id })))
    (asserts! (is-some node) (err u2)) ;; Node not found
    (asserts! (is-eq tx-sender (get owner (unwrap-panic node))) (err u3)) ;; Not the owner

    (ok (map-set nodes
      { node-id: node-id }
      (merge (unwrap-panic node) { owner: new-owner })
    ))
  )
)
