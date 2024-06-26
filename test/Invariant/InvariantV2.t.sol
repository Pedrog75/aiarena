// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

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
import { Handler } from "./handler.sol";
// import {Utilities} from "./utils/Utilities.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Invariant2 is StdInvariant, Test {


    uint8[][] internal _probabilities;
    address internal constant _DELEGATED_ADDRESS = 0x22F4441ad6DbD602dFdE5Cd8A38F6CAdE68860b0;
    address internal _ownerAddress;
    address internal _treasuryAddress;
    address internal _neuronContributorAddress;
    uint8 tokenId = 1;

    /*//////////////////////////////////////////////////////////////
                             CONTRACT INSTANCES
    //////////////////////////////////////////////////////////////*/

    FighterFarm internal _fighterFarmContract;
    Handler internal handler;
    AAMintPass internal _mintPassContract;
    MergingPool internal _mergingPoolContract;
    RankedBattle internal _rankedBattleContract;
    VoltageManager internal _voltageManagerContract;
    GameItems internal _gameItemsContract;
    AiArenaHelper internal _helperContract;
    Neuron internal _neuronContract;

    function getProb() public {
        _probabilities.push([25, 25, 13, 13, 9, 9]);
        _probabilities.push([25, 25, 13, 13, 9, 1]);
        _probabilities.push([25, 25, 13, 13, 9, 10]);
        _probabilities.push([25, 25, 13, 13, 9, 23]);
        _probabilities.push([25, 25, 13, 13, 9, 1]);
        _probabilities.push([25, 25, 13, 13, 9, 3]);
    }

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        // _utils = new Utilities();
        // _users = _utils.createUsers(5);
        _ownerAddress = address(this);
        _treasuryAddress = vm.addr(1);
        _neuronContributorAddress = vm.addr(2);
        getProb();

        _fighterFarmContract = new FighterFarm(_ownerAddress, _DELEGATED_ADDRESS, _treasuryAddress);

        _helperContract = new AiArenaHelper(_probabilities);

        _mintPassContract = new AAMintPass(_ownerAddress, _DELEGATED_ADDRESS);
        _mintPassContract.setFighterFarmAddress(address(_fighterFarmContract));
        _mintPassContract.setPaused(false);

        _gameItemsContract = new GameItems(_ownerAddress, _treasuryAddress);

        _voltageManagerContract = new VoltageManager(_ownerAddress, address(_gameItemsContract));

        _neuronContract = new Neuron(_ownerAddress, _treasuryAddress, _neuronContributorAddress);

        _rankedBattleContract = new RankedBattle(
            _ownerAddress, address(_fighterFarmContract), _DELEGATED_ADDRESS, address(_voltageManagerContract)
        );

        _rankedBattleContract.instantiateNeuronContract(address(_neuronContract));

        _mergingPoolContract =
            new MergingPool(_ownerAddress, address(_rankedBattleContract), address(_fighterFarmContract));

        _fighterFarmContract.setMergingPoolAddress(address(_mergingPoolContract));
        _fighterFarmContract.instantiateAIArenaHelperContract(address(_helperContract));
        _fighterFarmContract.instantiateMintpassContract(address(_mintPassContract));
        _fighterFarmContract.instantiateNeuronContract(address(_neuronContract));
        _fighterFarmContract.setMergingPoolAddress(address(_mergingPoolContract));

        handler = new Handler(_fighterFarmContract, _mergingPoolContract, _neuronContract, _rankedBattleContract, _ownerAddress, _treasuryAddress);

        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = handler.mintFromMergingPool.selector;
        selectors[1] = handler.fundUserWith4kNeuronByTreasury.selector;
        selectors[2] = handler.stakeNRN.selector;
        selectors[3] = handler.transferFrom.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    function statefulFuzz_NFTLockedCanBeTransferredV2() public {
      console.log("Avant mintFromMergingPool");
      _mintFromMergingPool(_ownerAddress);
      console.log("Apres mintFromMergingPool");
      _fighterFarmContract.addStaker(_ownerAddress);
      vm.prank(_ownerAddress);
      _fighterFarmContract.safeTransferFrom(_ownerAddress, _DELEGATED_ADDRESS, 0, "");
      assertEq(_fighterFarmContract.ownerOf(0), _ownerAddress);
    }

     function _mintFromMergingPool(address to) internal {
        vm.prank(address(_mergingPoolContract));
        console.log("Dans _mintFromMergingPool");
        _fighterFarmContract.mintFromMergingPool(to, "_neuralNetHash", "original", [uint256(1), uint256(80)]);
    }

    /// @notice Helper function to fund an account with 4k $NRN tokens.
    function _fundUserWith4kNeuronByTreasury(address user) internal {
        vm.prank(_treasuryAddress);
        _neuronContract.transfer(user, 4_000 * 10 ** 18);
        assertEq(4_000 * 10 ** 18 == _neuronContract.balanceOf(user), true);
    }

     function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4) {
        // Handle the token transfer here
        return this.onERC721Received.selector;
    }
}
