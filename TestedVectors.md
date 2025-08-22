# Tested Vectors

## Patcher Deposit Token Theft
- **Description**: Tokens transferred via `depositAndExecuteWithDynamicPatches` may remain in `Patcher` if the final target does not spend them. Attackers can retrieve this leftover balance using `executeWithDynamicPatches`.
- **Severity**: High
- **Status**: Reproduced in test `test_DepositTokensCanBeStolenByAnyone`.
