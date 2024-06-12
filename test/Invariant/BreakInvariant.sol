// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { FighterFarm } from "src/FighterFarm.sol";
import { Neuron } from "src/Neuron.sol";
import { RankedBattle } from "src/RankedBattle.sol";
import { VoltageManager } from "src/VoltageManager.sol";
import { GameItems } from "src/GameItems.sol";
import { MergingPool } from "src/MergingPool.sol";

contract BreakInvariant is StdInvariant, Test {
    FighterFarm _fighterFarmContract;
    Neuron _neuronContract;
    RankedBattle _rankedBattleContract;
    VoltageManager _voltageManagerContract;
    GameItems _gameItemsContract;
    MergingPool _mergingPoolContract;
    address internal constant _DELEGATED_ADDRESS = 0x22F4441ad6DbD602dFdE5Cd8A38F6CAdE68860b0;
    address internal constant _GAME_SERVER_ADDRESS = 0x7C0a2BAd62C664076eFE14b7f2d90BF6Fd3a6F6C;
    address internal _ownerAddress = address(1);
    address internal _treasuryAddress = address(2);
    address internal _neuronContributorAddress = address(3);


    function setUp() public{
    _fighterFarmContract = new FighterFarm(_ownerAddress, _DELEGATED_ADDRESS, _treasuryAddress);
    _neuronContract = new Neuron(_ownerAddress, _treasuryAddress, _neuronContributorAddress);
    _gameItemsContract = new GameItems(_ownerAddress, _treasuryAddress);
    _voltageManagerContract = new VoltageManager(_ownerAddress, address(_gameItemsContract));
    _rankedBattleContract = new RankedBattle(
      _ownerAddress, _GAME_SERVER_ADDRESS, address(_fighterFarmContract), address(_voltageManagerContract)
    );
    _mergingPoolContract = new MergingPool(_ownerAddress, address(_rankedBattleContract), address(_fighterFarmContract));
    targetContract(address(_fighterFarmContract));
    }

     function _mintFromMergingPool(address to) internal {
        // require(to == address(_mergingPoolContract), "Only Merging Pool can mint");
        // require(to != address(0), "Cannot mint to zero address");
        vm.prank(address(_mergingPoolContract));
        _fighterFarmContract.mintFromMergingPool(to, "_neuralNetHash", "original", [uint256(1), uint256(80)]);
    }

  function statefulFuzz_testInvariantBreak() public  {
    // Création des joueurs
    address player = vm.addr(1);
    // address newplayer = vm.addr(2);
    // On mint un fighter à player
    _mintFromMergingPool(player);
    vm.stopPrank();
    uint8 tokenId = 0;

    // On alimente le joueur en NRN
    vm.prank(_treasuryAddress);
    _neuronContract.transfer(player, 4_000 * 10 ** 18);
    // On stake des NRN pour vérrouiller le fighter(tokenID)
    vm.prank(player);
    _rankedBattleContract.stakeNRN(1 * 10 ** 18, tokenId);

    assert(_fighterFarmContract.ownerOf(tokenId) == player);

  }
}
