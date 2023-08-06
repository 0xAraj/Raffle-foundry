//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 public immutable i_subscriptionId;
    uint256 public immutable i_entranceFee;
    uint256 public immutable i_interval;
    bytes32 public immutable i_keyHash;
    uint32 public immutable i_callbackGasLimit;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1;
    address payable[] public s_player;
    address payable public s_recentWinner;
    uint256 public lastRequestId;
    uint256 public lastTimeStamp;

    enum Status {
        OPEN,
        CALCULATING
    }
    Status public currentStatus;
    event RaffleEntered(address indexed player);
    event RaffleWinner(address indexed winner);

    constructor(
        address vrfAddress,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint64 subscriptionId,
        uint256 entranceFee,
        uint256 interval
    ) VRFConsumerBaseV2(vrfAddress) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfAddress);
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        i_subscriptionId = subscriptionId;
        i_entranceFee = entranceFee;
        i_interval = interval;
        lastTimeStamp = block.timestamp;
    }

    function enterRaffle() public payable {
        require(currentStatus == Status.OPEN, "Raffle not open!");
        require(msg.value == i_entranceFee, "Not enough fee!");

        s_player.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function pickWinner() external returns (uint256 requestId) {
        require(
            block.timestamp > lastTimeStamp + i_interval,
            "Time has not passed!!"
        );
        require(s_player.length > 2, "Not enough players!!");
        currentStatus = Status.CALCULATING;

        requestId = COORDINATOR.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        return requestId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        lastRequestId = requestId;
        uint256 indexOfWinner = randomWords[0] % s_player.length;
        s_recentWinner = s_player[indexOfWinner];
        s_player = new address payable[](0);
        currentStatus = Status.OPEN;
        lastTimeStamp = block.timestamp;

        (bool success, ) = s_recentWinner.call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed!");
        emit RaffleWinner(s_recentWinner);
    }
}
