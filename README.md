# DeFi Protection Protocol

A decentralized protection protocol for DeFi projects on the Stacks blockchain, providing coverage against specified events through a secure and transparent smart contract system.

## Overview

The DeFi Protection Protocol enables DeFi projects to acquire protection coverage by locking STX tokens into a protection vault. In the event of eligible incidents, protected protocols can submit protection requests to recover their locked funds, subject to verification and approval by the protocol admin.

## Features

- **Protection Coverage**: Protocols can acquire protection by depositing STX
- **Flexible Request System**: Submit and process protection requests with supporting evidence
- **Transparent Processing**: All request statuses and outcomes are publicly visible
- **Automatic Expiration**: Stale requests automatically expire after a defined period
- **Admin Controls**: Secure management of request approvals and protocol parameters

## Technical Specifications

### Protection Acquisition
- Protocols deposit STX to receive protection coverage
- Coverage amount directly correlates to deposited amount
- One active protection policy per protocol address

### Request Processing
- Submit requests up to protected amount
- Requests expire after 4,320 blocks (approximately 30 days)
- Partial disbursements possible if vault balance is insufficient
- Admin review required for all requests

### Status Tracking
- Request statuses: pending, partially-disbursed, denied, expired
- Real-time vault balance monitoring
- Protection amount tracking per protocol

## Function Reference

### Public Functions

```clarity
(acquire-protection (amount uint))
(submit-protection-request (request-amount uint))
(approve-protection-request (requester principal) (request-amount uint))
(deny-protection-request (requester principal) (request-amount uint))
(check-and-expire-request (requester principal) (request-amount uint))
(update-protocol-admin (new-admin principal))
```

### Read-Only Functions

```clarity
(get-vault-balance)
(is-protected (protocol principal))
(get-protected-amount (protocol principal))
(get-protection-status (requester principal) (request-amount uint))
```

## Error Codes

- `ERR_INVALID_AMOUNT` (u100): Invalid amount specified
- `ERR_INSUFFICIENT_BALANCE` (u101): Insufficient balance for operation
- `ERR_PROTECTION_REQUEST_NOT_FOUND` (u102): Request not found
- `ERR_UNAUTHORIZED` (u103): Unauthorized access attempt
- `ERR_ALREADY_PROTECTED` (u104): Protocol already has protection
- `ERR_NOT_PROTECTED` (u105): Protocol not protected
- `ERR_ZERO_AMOUNT` (u106): Zero amount not allowed
- Additional error codes documented in contract

## Events

The contract emits the following events:
- Protection acquired
- Protection requested
- Request approved
- Request denied
- Request expired
- Admin updated

## Security Considerations

1. **Admin Access**: Only the designated admin can approve/deny requests
2. **Amount Validation**: All operations validate amounts and balances
3. **Expiration**: Automatic expiration prevents stale requests
4. **Balance Checks**: Vault balance verified before disbursements
5. **Principal Validation**: Protected against invalid principal addresses

## Development Setup

1. Install Clarinet
2. Clone the repository
3. Run `clarinet test` to execute test suite
4. Use `clarinet console` for interactive testing

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Submit pull request
5. Ensure tests pass

## Contact

For questions or support, please open an issue in the repository.