//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 public constant SUBSCRIPTION_ID = 4018;
    uint256 public constant ENTRANCE_FEE = 0.01 ether;
    uint256 public constant INTERVAL = 3;
    uint256 public lastTimeStamp;
    bytes32 public constant KEYHASH =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 public constant CALLBACK_GASLIMIT = 2500000;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1;
    address payable[] public s_player;
    address payable public s_recentWinner;
    uint256 public lastRequestId;

    enum Status {
        OPEN,
        CALCULATING
    }
    Status public currentStatus;
    event RaffleEntered(address indexed player);
    event RaffleWinner(address indexed winner);

    constructor()
        VRFConsumerBaseV2(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );
        lastTimeStamp = block.timestamp;
    }

    function enterRaffle() public payable {
        require(currentStatus == Status.OPEN, "Raffle not open!");
        require(msg.value == ENTRANCE_FEE, "Not enough fee!");

        s_player.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function pickWinner() external returns (uint256 requestId) {
        require(
            block.timestamp > lastTimeStamp + INTERVAL,
            "Time has not passed!!"
        );
        require(s_player.length > 1, "Not enough players!!");
        currentStatus = Status.CALCULATING;

        requestId = COORDINATOR.requestRandomWords(
            KEYHASH,
            SUBSCRIPTION_ID,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GASLIMIT,
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
