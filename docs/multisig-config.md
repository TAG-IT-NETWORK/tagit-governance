# Multi-Sig Configuration — Agent Identity Ownership

> **Version**: 1.0 | **Date**: 2026-03-29 | **Network**: OP Sepolia (Chain ID 11155420)

---

## Safe Address

| Property | Value |
|----------|-------|
| **Safe Address** | `0xAaA33C556C9c97a5430D180A1f72e8cf0fe0354e` |
| **Safe Version** | Safe v1.4.1 |
| **Chain** | OP Sepolia (11155420) |
| **Threshold** | 3-of-5 |

## Signers

| # | Role | Description |
|---|------|-------------|
| 1 | Founder (Artemus) | Primary decision-maker |
| 2 | Engineering Lead (SUDO) | Smart contract deployer |
| 3 | Security Officer | Audit & compliance |
| 4 | Operations Lead | Day-to-day management |
| 5 | Community Representative | Governance voice |

> **Note**: Signer addresses are stored in the Safe contract on-chain and must not be hardcoded in source.
> Query signers via `safe.getOwners()` or Safe UI at https://app.safe.global.

## Threshold Rationale

- **3-of-5** chosen to balance security with operational agility
- Any 3 signers can execute owner-gated actions
- Prevents single point of failure (no single key can act alone)
- Allows operations to continue if up to 2 signers are unavailable

## Owned Contracts

| Contract | Address | Owner-Gated Functions |
|----------|---------|----------------------|
| TAGITAgentIdentity | `0xA7f34FD595eBc397Fe04DcE012dbcf0fbbD2A78D` | setAccessController, setRegistrationFee, suspendAgent, reactivateAgent, pause, unpause, withdrawFees |
| TAGITAgentReputation | `0x57CCa1974DFE29593FBd24fdAEE1cD614Bfd6E4a` | setAccessController, setIdentityRegistry, pause, unpause |
| TAGITAgentValidation | `0x9806919185F98Bd07a64F7BC7F264e91939e86b7` | setAccessController, setIdentityRegistry, pause, unpause |

## Ownership Transfer Plan

For existing deployed contracts, ownership must be transferred to the Safe:

```bash
# Using cast (Foundry CLI)
cast send <CONTRACT_ADDRESS> \
  "transferOwnership(address)" \
  0xAaA33C556C9c97a5430D180A1f72e8cf0fe0354e \
  --rpc-url $OP_SEPOLIA_RPC_URL \
  --private-key $CURRENT_OWNER_KEY
```

For new deployments, the Safe address is passed as the `initialOwner` constructor parameter.

## Security Considerations

- The Safe address MUST be verified before any ownership transfer
- Never transfer ownership to an unverified address
- After transfer, verify new owner via `owner()` call
- Keep deployer key secure even after transfer (for emergency recovery via Safe)
- All multi-sig transactions require off-chain coordination between signers
