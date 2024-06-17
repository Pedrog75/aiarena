// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { FighterFarm } from "src/FighterFarm.sol";
import { Handler } from "./handler.sol";
import {Neuron} from "src/Neuron.sol";
import {MergingPool} from "src/MergingPool.sol";
import {RankedBattle} from "src/RankedBattle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Invariant is StdInvariant, Test {

    FighterFarm  fighterFarm;
    Handler handler;
    MergingPool mergingPoolContract;
    Neuron neuronContract;
    RankedBattle rankedBattleContract;
    address player = makeAddr('player');
    address otherplayer = makeAddr('otherplayer');
    address internal constant _DELEGATED_ADDRESS = 0x22F4441ad6DbD602dFdE5Cd8A38F6CAdE68860b0;
    address internal _ownerAddress;
    address internal _treasuryAddress;
    uint256 tokenId = 1;

    function setUp() public {
    // vm.startPrank(player);
    // tokenId = 0;
    // _mintFromMergingPool(player);
    // _fundUserWith4kNeuronByTreasury(player);
    // _rankedBattleContract.stakeNRN(1 * 10 ** 18, tokenId);
    // vm.stopPrank();
    _ownerAddress = address(this);
    _treasuryAddress = vm.addr(1);
    fighterFarm = new FighterFarm(_ownerAddress, _DELEGATED_ADDRESS, _treasuryAddress);
    handler = new Handler(fighterFarm, mergingPoolContract, neuronContract, rankedBattleContract, player, otherplayer, _treasuryAddress);

    bytes4[] memory selectors = new bytes4[](4);
    selectors[0] = handler.mintFromMergingPool.selector;
    selectors[1] = handler.fundUserWith4kNeuronByTreasury.selector;
    selectors[2] = handler.stakeNRN.selector;
    selectors[3] = handler.transferFrom.selector;

    targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    targetContract(address(handler));
    }

    function statefulFuzz_NFTLockedCanBeTransferred() public {
      assertEq(fighterFarm.ownerOf(tokenId), otherplayer);
    }
}
