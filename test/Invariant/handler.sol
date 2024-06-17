// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { FighterFarm } from "src/FighterFarm.sol";
import {Neuron} from "src/Neuron.sol";
// import {AAMintPass} from "src/AAMintPass.sol";
import {MergingPool} from "src/MergingPool.sol";
import {RankedBattle} from "src/RankedBattle.sol";
import {VoltageManager} from "src/VoltageManager.sol";
import {GameItems} from "src/GameItems.sol";
import {AiArenaHelper} from "src/AiArenaHelper.sol";
import {StakeAtRisk} from "src/StakeAtRisk.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Handler is Test {
    FighterFarm fighterFarm;
    MergingPool mergingPoolContract;
    Neuron neuronContract;
    RankedBattle rankedBattleContract;
    address player;
    address otherplayer;
    address treasuryAddress;

    constructor(
      FighterFarm _fighterFarm,
      MergingPool _mergingPoolContract,
      Neuron _neuronContract,
      RankedBattle _rankedBattleContract,
      address _player,
      address _treasuryAddress
      ) {
        fighterFarm = _fighterFarm;
        mergingPoolContract = _mergingPoolContract;
        neuronContract = _neuronContract;
        rankedBattleContract = _rankedBattleContract;
        player = _player;
        treasuryAddress = _treasuryAddress;
      }


    // create function mint >> to mint a NFT fighter
    function mintFromMergingPool(address to) public {
        vm.prank(address(mergingPoolContract));
        fighterFarm.mintFromMergingPool(to, "_neuralNetHash", "original", [uint256(1), uint256(80)]);
    }
    // create function fund >> to fund the contract with neuron tokens
    function fundUserWith4kNeuronByTreasury(address user) public {
      vm.prank(treasuryAddress);
      neuronContract.transfer(user, 4_000 * 10 ** 18);
      assertEq(4_000 * 10 ** 18 == neuronContract.balanceOf(user), true);
    }
    // create function stake >> to stake a NFT fighter
    function stakeNRN(uint256 _amount, uint256 tokenId) public {
      uint256 amount = bound(_amount, 0, 1*10**18);
      vm.prank(address(rankedBattleContract));
      rankedBattleContract.stakeNRN(amount, tokenId);
    }
    // create function transferFrom >> to transfer a NFT fighter
    function transferFrom(address from, address to, uint256 tokenId) public {
      require(fighterFarm.ownerOf(tokenId) == from, "TransferFrom: Token not owned by 'from' address");
      vm.prank(player);
      fighterFarm.safeTransferFrom(from, to, tokenId, "");
    }
}
