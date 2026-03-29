# Multi-Sig Runbook — Agent Identity Owner Actions

> **Version**: 1.0 | **Date**: 2026-03-29 | **Network**: OP Sepolia (Chain ID 11155420)

---

## Safe Details

| Property | Value |
|----------|-------|
| **Safe Address** | `0xAaA33C556C9c97a5430D180A1f72e8cf0fe0354e` |
| **Threshold** | 3-of-5 |
| **Safe UI** | https://app.safe.global/home?safe=oeth:0xAaA33C556C9c97a5430D180A1f72e8cf0fe0354e |

## Pre-Requisites

- At least 3 signers must be available
- Each signer needs their hardware wallet or signing key
- Access to Safe UI or Safe CLI (`safe-cli`)
- OP Sepolia ETH for gas (only the executor pays gas)

---

## Procedure: General Owner Action

### 1. Propose Transaction

One signer initiates the transaction in Safe UI:

1. Go to Safe UI > **New Transaction** > **Contract Interaction**
2. Enter the target contract address (e.g., TAGITAgentIdentity)
3. Select the function to call (e.g., `suspendAgent(uint256)`)
4. Fill in parameters
5. Click **Submit** (signs with your key)

### 2. Collect Signatures

Notify other signers via the team channel:

```
MULTI-SIG ACTION REQUIRED
Safe: 0xAaA33C556C9c97a5430D180A1f72e8cf0fe0354e
Target: TAGITAgentIdentity
Function: suspendAgent(42)
Reason: [explain why]
Safe TX Link: [paste from Safe UI]
Signatures needed: 2 more (3-of-5 threshold)
```

Each signer:
1. Opens the Safe TX link
2. Reviews the transaction details
3. Clicks **Confirm** to add their signature

### 3. Execute Transaction

Once 3 signatures are collected:
1. Any signer clicks **Execute**
2. Confirm the on-chain transaction in their wallet
3. Wait for confirmation
4. Verify the result on-chain

---

## Common Owner Actions

### Suspend an Agent

```
Contract: TAGITAgentIdentity
Function: suspendAgent(uint256 agentId)
When: Agent is behaving maliciously or needs investigation
```

### Reactivate a Suspended Agent

```
Contract: TAGITAgentIdentity
Function: reactivateAgent(uint256 agentId)
When: Investigation complete, agent cleared
```

### Emergency Pause

```
Contract: TAGITAgentIdentity
Function: pause()
When: Security incident, exploit detected, emergency stop needed
```

**Recovery:**
```
Contract: TAGITAgentIdentity
Function: unpause()
When: Incident resolved, system safe to resume
```

### Update Access Controller

```
Contract: TAGITAgentIdentity
Function: setAccessController(address controller)
When: BIDGES access controller contract is upgraded/migrated
CAUTION: Verify new address thoroughly before executing
```

### Set Registration Fee

```
Contract: TAGITAgentIdentity
Function: setRegistrationFee(uint256 fee)
When: Adjusting agent registration cost
Note: Fee is in wei (1 ETH = 1e18 wei)
```

### Withdraw Fees

```
Contract: TAGITAgentIdentity
Function: withdrawFees(address to)
When: Collecting accumulated registration fees
CAUTION: Verify destination address is correct (ideally Treasury)
```

### Transfer Ownership

```
Contract: TAGITAgentIdentity
Function: transferOwnership(address newOwner)
When: Migrating to a new Safe or governance model
EXTREME CAUTION: This is irreversible. Triple-check the new owner address.
```

---

## Emergency Procedures

### If a Signer Key is Compromised

1. **Immediately** propose a Safe owner swap transaction:
   - Remove the compromised signer
   - Add a replacement signer
2. Collect 3 signatures from remaining uncompromised signers
3. Execute the swap
4. Audit all recent Safe transactions for unauthorized actions

### If Safe Itself is Compromised

1. From any remaining valid signer, propose `pause()` on all owned contracts
2. Collect emergency signatures (phone call, not chat)
3. Execute pause immediately
4. Plan recovery: deploy new Safe, transfer ownership via old Safe

---

## Verification Commands

```bash
# Check current owner
cast call <CONTRACT> "owner()(address)" --rpc-url $OP_SEPOLIA_RPC_URL

# Check Safe signers
cast call 0xAaA33C556C9c97a5430D180A1f72e8cf0fe0354e "getOwners()(address[])" --rpc-url $OP_SEPOLIA_RPC_URL

# Check Safe threshold
cast call 0xAaA33C556C9c97a5430D180A1f72e8cf0fe0354e "getThreshold()(uint256)" --rpc-url $OP_SEPOLIA_RPC_URL

# Check if contract is paused
cast call <CONTRACT> "paused()(bool)" --rpc-url $OP_SEPOLIA_RPC_URL
```
