// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import {Vm} from "forge-std/Vm.sol";
import {FighterFarm} from "src/FighterFarm.sol";
import {Neuron} from "src/Neuron.sol";
import {AAMintPass} from "src/AAMintPass.sol";
import {MergingPool} from "src/MergingPool.sol";
import {RankedBattle} from "src/RankedBattle.sol";
import {VoltageManager} from "src/VoltageManager.sol";
import {GameItems} from "src/GameItems.sol";
import {AiArenaHelper} from "src/AiArenaHelper.sol";
import {StakeAtRisk} from "src/StakeAtRisk.sol";
// import {Utilities} from "./utils/Utilities.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract BreakInvariantV2 is StdInvariant, Test {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint8[][] internal _probabilities;
    address internal constant _DELEGATED_ADDRESS = 0x22F4441ad6DbD602dFdE5Cd8A38F6CAdE68860b0;
    address internal constant _GAME_SERVER_ADDRESS = 0x7C0a2BAd62C664076eFE14b7f2d90BF6Fd3a6F6C;
    address internal _ownerAddress;
    address internal _treasuryAddress;
    address internal _neuronContributorAddress;
    address private player;
    address private otherPlayer;
    uint256 private tokenId;

    /*//////////////////////////////////////////////////////////////
                             CONTRACT INSTANCES
    //////////////////////////////////////////////////////////////*/

    FighterFarm internal _fighterFarmContract;
    AAMintPass internal _mintPassContract;
    MergingPool internal _mergingPoolContract;
    RankedBattle internal _rankedBattleContract;
    VoltageManager internal _voltageManagerContract;
    GameItems internal _gameItemsContract;
    AiArenaHelper internal _helperContract;
    Neuron internal _neuronContract;
    StakeAtRisk internal _stakeAtRiskContract;

     function getProb() public {
        _probabilities.push([25, 25, 13, 13, 9, 9]);
        _probabilities.push([25, 25, 13, 13, 9, 1]);
        _probabilities.push([25, 25, 13, 13, 9, 10]);
        _probabilities.push([25, 25, 13, 13, 9, 23]);
        _probabilities.push([25, 25, 13, 13, 9, 1]);
        _probabilities.push([25, 25, 13, 13, 9, 3]);
    }

    function setUp() public {
    // _utils = new Utilities();
    // _users = _utils.createUsers(5);
    _ownerAddress = address(this);
    _treasuryAddress = vm.addr(1);
    _neuronContributorAddress = vm.addr(2);
    getProb();

    _fighterFarmContract = new FighterFarm(
      _ownerAddress, _DELEGATED_ADDRESS, _treasuryAddress
      );

    _helperContract = new AiArenaHelper(_probabilities);

    _mintPassContract = new AAMintPass(_ownerAddress, _DELEGATED_ADDRESS);
    _mintPassContract.setFighterFarmAddress(address(_fighterFarmContract));
    _mintPassContract.setPaused(false);

    _gameItemsContract = new GameItems(_ownerAddress, _treasuryAddress);

    _voltageManagerContract = new VoltageManager(
      _ownerAddress, address(_gameItemsContract)
    );

    _neuronContract = new Neuron(
      _ownerAddress, _treasuryAddress, _neuronContributorAddress
      );

    // _rankedBattleContract = new RankedBattle(
    //     _ownerAddress, address(_fighterFarmContract), _DELEGATED_ADDRESS, address(_voltageManagerContract)
    // );
    _rankedBattleContract = new RankedBattle(
      _ownerAddress, _GAME_SERVER_ADDRESS, address(_fighterFarmContract),
      address(_voltageManagerContract)
    );


    _mergingPoolContract =
        new MergingPool(_ownerAddress, address(_rankedBattleContract),
        address(_fighterFarmContract));

    _stakeAtRiskContract =new StakeAtRisk(
      _treasuryAddress, address(_neuronContract), address(_rankedBattleContract));
    _voltageManagerContract.adjustAllowedVoltageSpenders(
      address(_rankedBattleContract), true);


    _neuronContract.addStaker(address(_rankedBattleContract));
    _neuronContract.addMinter(address(_rankedBattleContract));

    _rankedBattleContract.instantiateNeuronContract(address(_neuronContract));
    _rankedBattleContract.instantiateMergingPoolContract(address(_mergingPoolContract));
    _rankedBattleContract.setStakeAtRiskAddress(address(_stakeAtRiskContract));

    _fighterFarmContract.setMergingPoolAddress(address(_mergingPoolContract));
    _fighterFarmContract.addStaker(address(_rankedBattleContract));
    _fighterFarmContract.instantiateAIArenaHelperContract(address(_helperContract));
    _fighterFarmContract.instantiateMintpassContract(address(_mintPassContract));
    _fighterFarmContract.instantiateNeuronContract(address(_neuronContract));

    player = vm.addr(3);
    otherPlayer = vm.addr(4);
    tokenId = 0;
    _mintFromMergingPool(player);
    _fundUserWith4kNeuronByTreasury(player);
    vm.prank(player);
    _rankedBattleContract.stakeNRN(1 * 10 ** 18, tokenId);
    targetContract(address(_fighterFarmContract));
  }

  /// @notice Test transferring ownership from an none owner account.
  function testTransferOwnershipFromNonOwnerV2() public {
        vm.startPrank(msg.sender);
        vm.expectRevert();
        _fighterFarmContract.transferOwnership(msg.sender);
        vm.expectRevert();
        _fighterFarmContract.incrementGeneration(1);
        assertEq(_fighterFarmContract.generation(1), 0);
  }

  function statefulFuzz_testInvariantBreakV2() public {
        // Check the invariant
        assertEq(_fighterFarmContract.ownerOf(tokenId), player);
  }

  function _mintFromMergingPool(address to) internal {
      vm.prank(address(_mergingPoolContract));
      _fighterFarmContract.mintFromMergingPool(to, "_neuralNetHash", "original", [uint256(1), uint256(80)]);
  }

  function _fundUserWith4kNeuronByTreasury(address user) internal {
        vm.prank(_treasuryAddress);
        _neuronContract.transfer(user, 4_000 * 10 ** 18);
        assertEq(4_000 * 10 ** 18 == _neuronContract.balanceOf(user), true);
  }
}
