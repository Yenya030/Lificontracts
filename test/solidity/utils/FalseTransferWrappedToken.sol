// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice Wrapped token that fails transfers by returning false
contract FalseTransferWrappedToken is ERC20 {
    constructor() ERC20("FalseTransferToken", "FTT", 18) {}

    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) external {
        _burn(msg.sender, wad);
        (bool ok, ) = payable(msg.sender).call{value: wad}("");
        require(ok, "withdraw failed");
    }

    function transfer(address, uint256) public pure override returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        return false;
    }
}
