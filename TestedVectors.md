

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

## AcrossFacet constructor allows zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/AcrossFacetZero.t.sol`
- Result: Contract deploys with `spokePool` and `wrappedNative` set to zero, causing bridge attempts to revert and rendering the facet unusable.

## AcrossFacetV3 constructor allows zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/AcrossFacetV3Zero.t.sol`
- Result: Contract deploys with `spokePool` and `wrappedNative` set to zero, leaving the facet unusable.

## AcrossFacetPacked constructor allows zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/AcrossFacetPackedZero.t.sol`
- Result: Contract deploys with zero `spokePool` and `wrappedNative`, causing bridge attempts to revert and rendering the facet unusable.

## AcrossFacetPackedV3 constructor allows zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/AcrossFacetPackedV3Zero.t.sol`
- Result: Contract deploys with zero `spokePool` and `wrappedNative`, leading to misconfiguration and potential fund loss.

## TokenWrapper constructor rejects zero wrapped token
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/TokenWrapperZeroAddress.t.sol`
- Result: Deployment with `wrappedToken` set to `address(0)` reverts, preventing misconfiguration.

## PolygonBridgeFacet constructor allows zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/PolygonBridgeFacetZero.t.sol`
- Result: Contract deploys with zero `rootChainManager` and `erc20Predicate`, causing bridge calls to revert and leaving operations unusable.

## ArbitrumBridgeFacet constructor allows zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/ArbitrumBridgeFacetZero.t.sol`
- Result: Contract deploys with zero `gatewayRouter` and `inbox`, causing bridge initiation to revert.

## ReceiverChainflip allowance resets after execution
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/ReceiverChainflipAllowance.t.sol`
- Result: After a successful `cfReceive` call, the token allowance granted to `Executor` drops to zero, leaving no residual approval for later misuse.

## CBridgeFacet constructor allows zero cBridge address
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/CBridgeFacetZero.t.sol`
- Result: Contract deploys with `cBridge` set to zero, causing bridge calls to send funds to the zero address and render the facet unusable.

## CelerCircleBridgeFacet constructor allows zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/CelerCircleBridgeFacetZero.t.sol`
- Result: Contract deploys with zero `circleBridgeProxy` and `usdc` addresses; calls to `startBridgeTokensViaCelerCircleBridge` succeed but leave tokens stuck in the contract.

## OptimismBridgeFacet initialization allows zero standard bridge
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/OptimismBridgeFacetZeroStandardBridge.t.sol`
- Result: `initOptimism` accepts `standardBridge` as address(0); subsequent bridge attempts revert with "call to non-contract address", leaving the facet unusable.

## ThorSwapFacet constructor allows zero router address
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/ThorSwapFacetZero.t.sol`
- Result: Contract deploys with router set to zero, causing bridge attempts to revert and preventing token swaps.

## SquidFacet constructor allows zero router address
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/SquidFacetZero.t.sol`
- Result: Contract deploys with `_squidRouter` set to zero; subsequent bridge calls revert, leaving the facet unusable.

## ChainflipFacet constructor rejects zero vault address
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/ChainflipFacetZero.t.sol`
- Result: Deployment with `_chainflipVa


## CBridgeFacetPacked constructor allows zero cBridge address
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/CBridgeFacetPackedZero.t.sol`
- Result: Contract deploys with `cBridge` set to zero, causing bridge calls to revert and leaving operations unusable.


## GenericSwapFacetV3 zero receiver burns native tokens
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/GenericSwapFacetV3ZeroReceiver.t.sol`
- Result: `swapTokensSingleV3ERC20ToNative` accepts `address(0)` as receiver, sending the contract's ETH balance to the zero address and permanently burning the funds.


## LiFiTimelockController zero diamond address
- Severity: Medium (privileged)
- Test: `forge test --match-path test/solidity/Security/LiFiTimelockController.t.sol --match-test test_SetDiamondAddressAllowsZero`
- Result: Admin can set `diamond` to `address(0)`, potentially disabling timelock functions; requires `TIMELOCK_ADMIN_ROLE` so not exploitable by unprivileged users.
## SymbiosisFacet constructor allows zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/SymbiosisFacetZero.t.sol`
- Result: Contract deploys with zero Symbiosis MetaRouter and Gateway addresses, causing bridge calls to revert and leaving the facet unusable.


## LiFiDiamond constructor allows zero owner
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/LiFiDiamondZeroOwner.t.sol`
- Result: Deployment with `_contractOwner` set to `address(0)` succeeds, leaving the diamond without an owner and blocking further upgrades via `diamondCut`.

## OmniBridgeFacet constructor allows zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/OmniBridgeFacetZero.t.sol`
- Result: Contract deploys with zero `foreignOmniBridge` and `wethOmniBridge`, rendering bridging calls unusable as they revert.

## GnosisBridgeFacet constructor rejects zero router address
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/GnosisBridgeFacetZero.t.sol`
- Result: Deployment with `_gnosisBridgeRouter` set to `address(0)` reverts with `InvalidConfig`, preventing misconfiguration.
## HopFacetPacked constructor allows zero wrapper and owner
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/HopFacetPackedZero.t.sol`
- Result: Contract deploys with zero owner and Hop wrapper, leaving bridging addresses unset and potentially causing bridge calls to fail.


## DeBridgeDlnFacet constructor rejects zero DLN source address
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/DeBridgeDlnFacetZero.t.sol`
- Result: Deployment with `_dlnSource` set to `address(0)` reverts with `InvalidConfig`, preventing misconfiguration.

## PioneerFacet zero-address validations
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/PioneerFacetZero.t.sol`
- Result: Constructor reverts on zero `_pioneerAddress` and bridging reverts when `refundAddress` is zero, preventing unauthorized refunds or misconfiguration.

## Patcher leftover ETH can be stolen
- Severity: High
- Test: `forge test --match-path test/solidity/Periphery/PatcherEthDrain.t.sol`
- Result: Excess ETH sent to `Patcher` remains in the contract and can be drained by anyone through `executeWithDynamicPatches`.

## GlacisFacet unlimited token allowance to airlift
- Severity: High
- Test: `forge test --match-path test/solidity/Security/GlacisFacetAllowance.t.sol`
- Result: Leaves unlimited ERC20 allowance to the airlift contract, enabling token drain via `transferFrom` if the airlift is compromised.

## AllBridgeFacet constructor rejects zero router address
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/AllBridgeFacetZero.t.sol`
- Result: Deployment with `_allBridge` set to `address(0)` reverts with `InvalidConfig`, preventing misconfiguration and potential fund lockup.

## EmergencyPauseFacet constructor allows zero pauser wallet
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/EmergencyPauseFacetZero.t.sol`
- Result: Contract deploys with `pauserWallet` set to the zero address, leaving emergency pause and facet removal restricted only to the owner.

## GlacisFacet constructor and startBridge reject zero addresses
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/GlacisFacetZero.t.sol`
- Result: Deployment with zero airlift address or zero refund address reverts, preventing misconfiguration and locked funds.

## GlacisFacet zero refund address
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/GlacisFacetZeroRefundAddress.t.sol`
- Result: `_startBridge` reverts with `InvalidRefundAddress` when `refundAddress` is zero, preventing misconfiguration.
## LibSwap unlimited token allowance to arbitrary spender
- Severity: High
- Test: `forge test --match-path test/solidity/Security/LibSwapUnlimitedAllowance.t.sol`
- Result: `LibSwap.swap` leaves unlimited approval to user-specified `approveTo`, allowing approved contract to drain any tokens later sent to the executor.

## ReceiverChainflip zero receiver burns funds
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/ReceiverChainflipZeroReceiver.t.sol`
- Result: `cfReceive` accepts `receiver = address(0)` and transfers tokens to the zero address, permanently burning the funds.

## SwapperV2 native balance underflow
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/SwapperV2FetchBalancesReverts.t.sol`
- Result: `_fetchBalances` subtracts `msg.value` for each native receiving asset before deposits, causing underflow and reverting.`

## MayanFacet native amount normalization refund
- Severity: Medium
- Test: `forge test --match-path test/solidity/Security/MayanFacetDust.t.sol`
- Result: Excess native tokens are refunded to the caller via `refundExcessNative`, leaving no dust in the contract.

## HopFacet unlimited token allowance to bridge
- Severity: High
- Test: `forge test --match-path test/solidity/Security/HopFacetAllowance.t.sol`
- Result: HopFacet leaves an unlimited allowance to the Hop bridge contract after bridging, enabling token drain if the bridge is compromised.
## GenericSwapFacetV3 reentrancy drains token balance
- Severity: High
- Test: `forge test --match-path test/solidity/Security/GenericSwapFacetV3Reentrancy.t.sol`
- Result: Malicious DEX reenters swap to transfer entire contract token balance to attacker before outer call completes.
