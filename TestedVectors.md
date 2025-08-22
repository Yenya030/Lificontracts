# Tested Attack Vectors

| Vector | Severity | Status | Notes |
| ------ | -------- | ------ | ----- |
| Using zero address as receiver in swapTokensGeneric | Medium | Mitigated | Reverts with InvalidReceiver; covered by test |
