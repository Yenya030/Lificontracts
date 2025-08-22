# Tested Vectors

## Patcher Deposit Token Theft
- **Description**: Tokens transferred via `depositAndExecuteWithDynamicPatches` may remain in `Patcher` if the final target does not spend them. Attackers can retrieve this leftover balance using `executeWithDynamicPatches`.
- **Severity**: High
- **Status**: Reproduced in test `test_DepositTokensCanBeStolenByAnyone`.

## TransferrableOwnership zero-owner initialization
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/TransferrableOwnershipZero.t.sol`
- Result: Constructor accepts address(0) as owner, leaving contract without an owner and blocking future ownership transfers.

## RelayFacet reentrancy on `swapAndStartBridgeTokensViaRelay`
- Severity: High
- Tool: `slither`
- Result: External calls occur before state mutation of `consumedIds`, enabling reentrancy to reuse a request ID.

## GenericSwapFacetV3 arbitrary ETH transfer
- Severity: High
- Tool: `slither`
- Result: Uses low-level calls to transfer ETH to arbitrary receiver, allowing reentrancy before event emission.

| Date | Description | Severity | Result |
|------|-------------|----------|--------|
| 2025-02-14 | Unauthorized PancakeV3 swap callback invocation | High | Reverted with `UniswapV3SwapCallbackUnknownSource` |
| 2025-02-14 | Zero or negative amount in PancakeV3 swap callback | Medium | Reverted with `UniswapV3SwapCallbackNotPositiveAmount` |

| Vector | Severity | Status | Notes |
| ------ | -------- | ------ | ----- |
| Using zero address as receiver in swapTokensGeneric | Medium | Mitigated | Reverts with InvalidReceiver; covered by test |
| Missing validation for executor or spokepool zero address in ReceiverAcrossV3 constructor | Medium | Vulnerable | Contract deploys with zero addresses; see test_ConstructorAllowsZeroAddresses |
| Missing validation for ERC20 proxy zero address in Executor constructor | Medium | Vulnerable | Executor initializes with zero proxy; see test_ConstructorAllowsZeroProxy |
