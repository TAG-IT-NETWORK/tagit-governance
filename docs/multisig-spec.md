# Multi-Sig Specification — AI Ambassador Agent Identity Ownership

> **Version**: 1.0 | **Date**: 2026-03-29 | **Task**: 3314e3e9-a2d3-8148-89d8-f686f5fe918e

---

## 1. Overview

This document specifies the multi-sig wallet configuration for owning the TAGITAgentIdentity
contract suite. The multi-sig ensures no single key can execute privileged operations on the
AI Ambassador agent identity system, satisfying Phase 1 mainnet readiness requirements.

## 2. Safe Configuration

| Parameter | Value |
|-----------|-------|
| **Safe Version** | Safe v1.4.1 (Gnosis Safe) |
| **Network** | OP Sepolia (Chain ID: 11155420) |
| **Safe Address** | `0xAaA33C556C9c97a5430D180A1f72e8cf0fe0354e` |
| **Threshold** | 3-of-5 |
| **Factory** | Safe Singleton Factory (CREATE2 deterministic) |
| **Fallback Handler** | CompatibilityFallbackHandler v1.4.1 |

## 3. Signers

| # | Role | Responsibility |
|---|------|----------------|
| 1 | **Founder (Artemus)** | Primary decision-maker, strategic oversight |
| 2 | **Engineering Lead (SUDO AI)** | Smart contract deployer, technical reviewer |
| 3 | **Security Officer** | Audit and compliance gatekeeper |
| 4 | **Operations Lead** | Day-to-day operational management |
| 5 | **Community Representative** | Governance voice, community interests |

> **Security**: Signer addresses are stored on-chain only. Query via `safe.getOwners()` or
> the Safe UI at https://app.safe.global. Never hardcode signer addresses in source.

## 4. Threshold Rationale

- **3-of-5** balances security with operational agility
- Prevents single point of failure (no single compromised key can act)
- Allows continued operations if up to 2 signers are unavailable
- Aligns with industry best practice for protocol-owned contracts
- Sufficient for Phase 1 testnet; will be reviewed for mainnet (consider 4-of-7)

## 5. Owned Contracts

| Contract | Address | Network |
|----------|---------|---------|
| TAGITAgentIdentity | `0xA7f34FD595eBc397Fe04DcE012dbcf0fbbD2A78D` | OP Sepolia |
| TAGITAgentReputation | `0x57CCa1974DFE29593FBd24fdAEE1cD614Bfd6E4a` | OP Sepolia |
| TAGITAgentValidation | `0x9806919185F98Bd07a64F7BC7F264e91939e86b7` | OP Sepolia |

## 6. Owner-Gated Functions

### TAGITAgentIdentity

| Function | Signature | Purpose |
|----------|-----------|---------|
| `setAccessController` | `setAccessController(address)` | Update BIDGES access controller |
| `setRegistrationFee` | `setRegistrationFee(uint256)` | Change agent registration fee |
| `suspendAgent` | `suspendAgent(uint256)` | Suspend a registered agent |
| `reactivateAgent` | `reactivateAgent(uint256)` | Reactivate a suspended agent |
| `pause` | `pause()` | Emergency pause (circuit breaker) |
| `unpause` | `unpause()` | Resume operations |
| `withdrawFees` | `withdrawFees(address)` | Withdraw collected registration fees |
| `transferOwnership` | `transferOwnership(address)` | Transfer contract ownership |

### TAGITAgentReputation

| Function | Signature | Purpose |
|----------|-----------|---------|
| `setAccessController` | `setAccessController(address)` | Update BIDGES access controller |
| `setIdentityRegistry` | `setIdentityRegistry(address)` | Link to identity contract |
| `pause` | `pause()` | Emergency pause |
| `unpause` | `unpause()` | Resume operations |

### TAGITAgentValidation

| Function | Signature | Purpose |
|----------|-----------|---------|
| `setAccessController` | `setAccessController(address)` | Update BIDGES access controller |
| `setIdentityRegistry` | `setIdentityRegistry(address)` | Link to identity contract |
| `pause` | `pause()` | Emergency pause |
| `unpause` | `unpause()` | Resume operations |

## 7. Ownership Transfer Procedure

### Pre-Transfer Checklist

- [ ] Safe deployed and verified on block explorer
- [ ] All 5 signers confirmed their addresses are added to the Safe
- [ ] 3-of-5 threshold verified via `safe.getThreshold()`
- [ ] Test transaction executed successfully (e.g., 0-value ETH send)

### Transfer Steps

```bash
# 1. Transfer ownership of TAGITAgentIdentity
cast send 0xA7f34FD595eBc397Fe04DcE012dbcf0fbbD2A78D \
  "transferOwnership(address)" \
  0xAaA33C556C9c97a5430D180A1f72e8cf0fe0354e \
  --rpc-url $OP_SEPOLIA_RPC_URL \
  --private-key $CURRENT_OWNER_KEY

# 2. Verify new owner
cast call 0xA7f34FD595eBc397Fe04DcE012dbcf0fbbD2A78D \
  "owner()(address)" \
  --rpc-url $OP_SEPOLIA_RPC_URL
# Expected: 0xAaA33C556C9c97a5430D180A1f72e8cf0fe0354e
```

### Post-Transfer Verification

- [ ] `owner()` returns Safe address for all 3 contracts
- [ ] Old EOA cannot call `onlyOwner` functions (reverts with `OwnableUnauthorizedAccount`)
- [ ] Safe can propose and execute a test transaction (e.g., `setRegistrationFee(0)`)
- [ ] All 3 contracts verified on block explorer with new owner

## 8. Signing Procedures

### Standard Operations (non-emergency)

1. Proposer creates transaction in Safe UI or via Safe SDK
2. Transaction details shared in secure channel (Signal group)
3. Each signer reviews calldata, target, and value independently
4. 3 of 5 signers approve within 48-hour window
5. Any signer executes the approved transaction
6. Execution verified on block explorer

### Emergency Operations (pause)

1. Security Officer or Engineering Lead proposes `pause()` transaction
2. Emergency signers respond within 1 hour
3. 3 signatures collected and executed immediately
4. Post-incident review within 24 hours
5. `unpause()` requires standard procedure (48-hour window)

## 9. Mainnet Readiness Considerations

| Item | Testnet (current) | Mainnet (planned) |
|------|-------------------|-------------------|
| Threshold | 3-of-5 | 4-of-7 (recommended) |
| Timelock | None | 24h timelock on non-emergency ops |
| Hardware wallets | Optional | Required for all signers |
| Backup keys | Recommended | Mandatory (secure vault) |
| Audit | Internal review | External audit of Safe config |

## 10. References

- [multisig-config.md](./multisig-config.md) — Operational configuration details
- [multisig-runbook.md](./multisig-runbook.md) — Day-to-day operational procedures
- [Gnosis Safe Documentation](https://docs.safe.global/)
- [OpenZeppelin Ownable](https://docs.openzeppelin.com/contracts/5.x/api/access#Ownable)
