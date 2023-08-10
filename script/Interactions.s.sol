//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

contract EnterRaffle is Script {
    address sepoliaSmartContractAddress =
        0x99fd723c10c490fb1Ba8b66e1dEFbb4DD0c7DbDb;

    function enterRaffle() public {
        Raffle raffle = Raffle(sepoliaSmartContractAddress);
        uint256 amount = 0.01 ether;
        vm.startBroadcast();
        raffle.enterRaffle{value: amount}();
        vm.stopBroadcast();
    }

    function run() external {
        enterRaffle();
    }
}

contract PickWinner is Script {
    address sepoliaSmartContractAddress =
        0x99fd723c10c490fb1Ba8b66e1dEFbb4DD0c7DbDb;

    function pickWinner() public {
        Raffle raffle = Raffle(sepoliaSmartContractAddress);
        vm.startBroadcast();
        raffle.pickWinner();
        vm.stopBroadcast();
    }

    function run() external {
        pickWinner();
    }
}
