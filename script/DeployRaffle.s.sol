//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    Raffle raffle;
    HelperConfig helperConfig;

    function run() external returns (Raffle, HelperConfig) {
        helperConfig = new HelperConfig();
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfAddress,
            bytes32 keyHash,
            uint64 subscriptionId,
            uint32 callbackGasLimit
        ) = helperConfig.activeNetwork();

        vm.startBroadcast();
        raffle = new Raffle(
            vrfAddress,
            keyHash,
            callbackGasLimit,
            subscriptionId,
            entranceFee,
            interval
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}
