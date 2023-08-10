//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {EnterRaffle, PickWinner} from "../../script/Interactions.s.sol";

contract RaffleIntegrationTest is Test {
    Raffle raffle;
    address sepoliaSmartContractAddress =
        0x99fd723c10c490fb1Ba8b66e1dEFbb4DD0c7DbDb;

    function setUp() external {
        raffle = Raffle(sepoliaSmartContractAddress);
    }

    function testRaffleIntegration() public {
        EnterRaffle enterRaffle = new EnterRaffle();
        enterRaffle.enterRaffle();

        assert(address(raffle).balance == 0.01 ether);

        enterRaffle.enterRaffle();
        enterRaffle.enterRaffle();

        PickWinner pickWinner = new PickWinner();
        uint256 requestId = pickWinner.pickWinner();
        console.log(requestId);
    }
}
