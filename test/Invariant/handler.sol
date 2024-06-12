// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "src/FighterFarm.sol";

contract Handler {
    FighterFarm  fighterFarm;

    constructor(FighterFarm _fighterFarm) {
        fighterFarm = _fighterFarm;
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        fighterFarm.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        fighterFarm.safeTransferFrom(from, to, tokenId);
    }
}
