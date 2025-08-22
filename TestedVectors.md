# Tested Vectors

| Date | Description | Severity | Result |
|------|-------------|----------|--------|
| 2025-02-14 | Unauthorized PancakeV3 swap callback invocation | High | Reverted with `UniswapV3SwapCallbackUnknownSource` |
| 2025-02-14 | Zero or negative amount in PancakeV3 swap callback | Medium | Reverted with `UniswapV3SwapCallbackNotPositiveAmount` |
