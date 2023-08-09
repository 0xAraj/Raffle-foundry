//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;
    address PLAYER1 = makeAddr("player1");
    address PLAYER2 = makeAddr("player2");
    address PLAYER3 = makeAddr("player3");

    uint256 entranceFee;
    uint256 interval;
    address vrfAddress;
    bytes32 keyHash;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    event RaffleEntered(address indexed player);

    function setUp() external {
        // DeployRaffle deployRaffle = new DeployRaffle();
        // (raffle, helperConfig) = deployRaffle.run();
        // (
        //     entranceFee,
        //     interval,
        //     vrfAddress,
        //     keyHash,
        //     subscriptionId,
        //     callbackGasLimit
        // ) = helperConfig.activeNetwork();
        raffle = Raffle(0x99fd723c10c490fb1Ba8b66e1dEFbb4DD0c7DbDb);
        vm.deal(PLAYER1, 10e18);
        vm.deal(PLAYER2, 10e18);
        vm.deal(PLAYER3, 10e18);
        console.log(address(raffle));
    }

    function testRaffleInitialStateIsOpen() public view {
        assert(uint(raffle.currentStatus()) == 0);
    }

    function testEnterRaffleFailIfNotEnoughEth() public {
        vm.prank(PLAYER1);
        vm.expectRevert();
        raffle.enterRaffle();
    }

    function testRaffleStorePlayersWhenEnter() public {
        vm.prank(PLAYER1);
        raffle.enterRaffle{value: 0.01 ether}();

        address player = raffle.s_player(0);
        assert(player == PLAYER1);
    }

    function testRaffleEmitEventWhenPlayerEntered() public {
        vm.prank(PLAYER1);
        vm.expectEmit(address(raffle));
        emit RaffleEntered(PLAYER1);
        raffle.enterRaffle{value: 0.01 ether}();
    }

    function testCantEnterRaffleWhenItIsCalculating() public {
        vm.prank(PLAYER1);
        raffle.enterRaffle{value: 0.01 ether}();
        vm.prank(PLAYER2);
        raffle.enterRaffle{value: 0.01 ether}();
        vm.prank(PLAYER3);
        raffle.enterRaffle{value: 0.01 ether}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 5);

        raffle.pickWinner();

        vm.prank(PLAYER1);
        vm.expectRevert();
        raffle.enterRaffle{value: 0.01 ether}();
    }

    // function testPickWinnerFailsIfTimeNotPassed() public {
    //     for (uint160 i = 1; i < 5; i++) {
    //         hoax(address(i), 5e18);
    //         raffle.enterRaffle{value: 0.01 ether}();
    //     }
    //     console.log(block.timestamp);
    //     console.log(raffle.lastTimeStamp());
    //     vm.prank(PLAYER1);
    //     // vm.expectRevert();
    //     raffle.pickWinner();
    // }
}
