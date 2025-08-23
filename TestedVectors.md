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

## ERC20Proxy arbitrary token transfer
- Severity: High
- Test: `forge test --match-path test/solidity/Security/ERC20ProxyArbitraryFrom.t.sol`
- Result: Authorized callers can move tokens from any approved address, enabling theft if proxy is approved by victims.

## LidoWrapper sweeps existing stETH balance
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/LidoWrapperSweep.t.sol`
- Result: `wrapStETHToWstETH` unwraps entire contract balance, letting callers steal stray stETH deposits.

| Date | Description | Severity | Result |
|------|-------------|----------|--------|
| 2025-02-14 | Unauthorized PancakeV3 swap callback invocation | High | Reverted with `UniswapV3SwapCallbackUnknownSource` |
| 2025-02-14 | Zero or negative amount in PancakeV3 swap callback | Medium | Reverted with `UniswapV3SwapCallbackNotPositiveAmount` |
| Permit2 witness call executed by third party | Medium | Mitigated | Execution by unsignatured caller still honors witness; verified with `forge test --match-test test_can_call_diamond_with_permit2_plus_witness` |
| EIP-7702 delegated account misclassified as EOA | Medium | Mitigated | `LibAsset.isContract` returns false for 23-byte accounts, preventing contract-only interactions; verified with `forge test --match-test test_isContractWithDelegationDesignator` |\
| 2025-08-22 | Reentrancy during token transfer triggers PancakeV3 callback | High | Reverted with `UniswapV3SwapCallbackUnknownSource` |
| 2025-08-22 | Unauthorized Algebra swap callback invocation | High | Reverted with `UniswapV3SwapCallbackUnknownSource` |
| 2025-08-22 | Zero or negative amount in Algebra swap callback | Medium | Reverted with `UniswapV3SwapCallbackNotPositiveAmount` |
| 2025-08-22 | Reentrancy during token transfer triggers Algebra swap callback | High | Reverted with `UniswapV3SwapCallbackUnknownSource` |
| 2025-08-23 | Unauthorized RamsesV2 swap callback invocation | High | Reverted with `UniswapV3SwapCallbackUnknownSource` |
| 2025-08-23 | Zero or negative amount in RamsesV2 swap callback | Medium | Reverted with `UniswapV3SwapCallbackNotPositiveAmount` |
| Vector | Severity | Status | Notes |
| ------ | -------- | ------ | ----- |
| Using zero address as receiver in swapTokensGeneric | Medium | Mitigated | Reverts with InvalidReceiver; covered by test |
| Missing validation for executor or spokepool zero address in ReceiverAcrossV3 constructor | Medium | Vulnerable | Contract deploys with zero addresses; see test_ConstructorAllowsZeroAddresses |
| Missing validation for ERC20 proxy zero address in Executor constructor | Medium | Vulnerable | Executor initializes with zero proxy; see test_ConstructorAllowsZeroProxy |

## TokenWrapper deposit ignores failed transfer
- Severity: Medium
- Test: `forge test --match-test testDepositFailsSilentlyOnFalseReturn`
- Result: `deposit` deducts ETH but returns no wrapped tokens when underlying `transfer` returns false; tokens remain stuck in the contract.

## LiFiDEXAggregator token draining via malicious pool
- Severity: High
- Test: `forge test --match-path test/solidity/Periphery/LiFiDEXAggregatorMaliciousPool.t.sol`
- Result: Malicious pool drains contract's entire token balance via `uniswapV3SwapCallback` without depositing tokens.

## Executor swap reentrancy via malicious swap adapter
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/ExecutorReentrancy.t.sol`
- Result: Reentrancy attempt reverts with `ReentrancyError`, blocking nested swap execution.

## TokenWrapper withdraw guards against failed transferFrom
- Severity: Medium
- Test: `forge test --match-path test/solidity/Periphery/TokenWrapper.t.sol --match-test testWithdrawRevertsOnFalseTransferFrom`
- Result: `withdraw` reverts when the wrapped token's `transferFrom` returns false, preventing ETH release without token transfer.

## GasZipPeriphery deposit reentrancy drains funds
- Severity: High
- Test: `forge test --match-path test/solidity/Security/GasZipPeripheryReentrancy.t.sol`
- Result: Malicious GasZip router can reenter `depositToGasZipNative` and siphon the contract's ETH balance.

## GasZipPeriphery public deposit drains contract ETH
- **Severity**: Medium
- **Test**: `forge test --match-path test/solidity/Security/GasZipPeripheryDrainNative.t.sol`
- **Result**: Anyone can call `depositToGasZipNative` with zero `msg.value` to forward the contract\x27s ETH balance to an arbitrary `receiverAddress`, draining stuck native tokens.

## LiFiDEXAggregator constructor allows zero BentoBox address
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/LiFiDexAggregatorZero.t.sol`
- Result: Deployer can set `BENTO_BOX` to the zero address, leaving the aggregator unusable and risking token lockup.

## LiFiDEXAggregator ETH drain via transferValueAndprocessRoute
- Severity: High
- Test: `forge test --match-path test/solidity/Periphery/LiFiDEXAggregatorTransferValueDrain.t.sol`
- Result: Function transfers arbitrary ETH amount from contract balance before verifying `msg.value`, allowing attackers to drain stored ETH.

## FeeCollector zero-address integrator locks fees
- Severity: Medium
- Test: `forge test --match-test testZeroAddressIntegratorLocksFees`
- Result: Fees collected for `integratorAddress` set to `address(0)` cannot be withdrawn and remain locked in the contract.
## ReceiverStargateV2 constructor allows zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/ReceiverStargateV2Zero.t.sol`
- Result: Contract deploys with zero executor, tokenMessaging, and endpoint addresses, leaving the receiver misconfigured and unusable.

## Permit2Proxy constructor allows zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/Permit2ProxyZero.t.sol`
- Result: Contract deploys with zero LIFI diamond, Permit2, and owner addresses, risking misconfiguration and locked funds.

## GasZipPeriphery constructor allows zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/GasZipPeripheryZero.t.sol`
- Result: Contract deploys with zero `gasZipRouter` and `liFiDEXAggregator`, leaving operations unusable and risking fund lockup.

## RelayFacet startBridgeTokensViaRelay reentrancy
- Severity: High
- Test: `forge test --match-path test/solidity/Security/RelayFacetReentrancyStart.t.sol`
- Result: Reentrancy attempt reverted; `ReentrancyGuard` prevents reuse of request IDs before `consumedIds` update.

## Executor single-swap partial fill refunds leftovers
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/ExecutorLeftover.t.sol`
- Result: Excess input tokens are returned to the receiver, leaving no balance in `Executor`.
## GenericSwapFacetV3 constructor allows zero native address
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/GenericSwapFacetV3Zero.t.sol`
- Result: Contract deploys with `NATIVE_ADDRESS` set to zero, leaving swaps misconfigured and potentially locking funds.

## StargateFacetV2 constructor allows zero token messaging address
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/StargateFacetV2Zero.t.sol`
- Result: Contract deploys with `tokenMessaging` set to zero, preventing pool lookups and halting bridging.

## AcrossFacetV3 constructor allows zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/AcrossFacetV3Zero.t.sol`
- Result: Contract deploys with `spokePool` and `wrappedNative` set to zero, leaving the facet unusable.

## AcrossFacetPackedV3 constructor allows zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/AcrossFacetPackedV3Zero.t.sol`
- Result: Contract deploys with zero `spokePool` and `wrappedNative`, leading to misconfiguration and potential fund loss.
## CelerCircleBridgeFacet constructor allows zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/CelerCircleBridgeFacetZero.t.sol`
- Result: Contract deploys with zero `circleBridgeProxy` and `usdc` addresses; calls to `startBridgeTokensViaCelerCircleBridge` succeed but leave tokens stuck in the contract.

