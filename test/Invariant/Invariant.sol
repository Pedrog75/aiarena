// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { FighterFarm } from "src/FighterFarm.sol";
import { Handler } from "./Handler.sol";
import { RankedBattle } from "test/RankedBattle.t.sol";

contract InvariantTest is StdInvariant, Test {
    FighterFarm fighterFarm;
    Handler handler;

    function setUp() public {
        // Initialize the FighterFarm contract and the Handler
        fighterFarm = new FighterFarm(address(this), address(this), address(this));
        handler = new Handler(fighterFarm);

        // Target the handler for fuzz testing
        targetContract(address(handler));
    }

    function invariant_FighterCannotBeTransferredWhenLocked() public {
        uint256 totalSupply = fighterFarm.totalSupply();

        for (uint256 tokenId = 0; tokenId < totalSupply; tokenId++) {
            bool isLocked = fighterFarm.fighterStaked(tokenId);
            address owner = fighterFarm.ownerOf(tokenId);

            // Try transferring the token to another address (this will revert if locked)
            if (isLocked) {
                address to = address(uint160(uint256(keccak256(abi.encodePacked(tokenId)))));
                try handler.transferFrom(owner, to, tokenId) {
                    assertTrue(false, "Transfer should fail when fighter is locked");
                } catch {}

                try handler.safeTransferFrom(owner, to, tokenId) {
                    assertTrue(false, "Safe transfer should fail when fighter is locked");
                } catch {}
            }
        }
    }
}
