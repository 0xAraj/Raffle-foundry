//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;
    address PLAYER = makeAddr("player");

    uint256 entranceFee;
    uint256 interval;
    address vrfAddress;
    bytes32 keyHash;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    event RaffleEntered(address indexed player);

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        (
            entranceFee,
            interval,
            vrfAddress,
            keyHash,
            subscriptionId,
            callbackGasLimit
        ) = helperConfig.activeNetwork();
        vm.deal(PLAYER, 10e18);
    }

    function testEnterRaffleFailIfNotEnoughEth() public {
        vm.prank(PLAYER);
        vm.expectRevert();
        raffle.enterRaffle();
    }

    function testRaffleStorePlayersWhenEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 0.01 ether}();

        address player = raffle.s_player(0);
        assert(player == PLAYER);
    }

    function testRaffleEmitEventWhenPlayerEntered() public {
        vm.prank(PLAYER);
        vm.expectEmit(address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: 0.01 ether}();
    }
}
