//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 public immutable i_subscriptionId;
    uint256 public immutable i_entranceFee;
    uint256 public immutable i_interval;
    uint256 public lastTimeStamp;
    bytes32 public immutable i_keyHash;
    uint32 public immutable i_callbackGasLimit;
    uint16 public constant REQUEST_CONFIRMATIONS = 1;
    uint32 public constant NUM_WORDS = 1;
    address payable[] public s_player;
    address payable public s_recentWinner;

    enum Status {
        OPEN,
        CLOSED,
        CALCULATING
    }
    Status public currentStatus;
    event RaffleEntered(address indexed player);
    event RaffleWinner(address indexed winner);

    constructor(
        uint256 entranceFee,
        address vrfAddress,
        uint256 interval,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfAddress) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfAddress);
        i_entranceFee = entranceFee;
        lastTimeStamp = block.timestamp;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        currentStatus = Status.OPEN;
    }

    function enterRaffle() public payable {
        require(currentStatus == Status.OPEN, "Raffle not open!");
        require(msg.value == i_entranceFee, "Not enough fee!");

        s_player.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    ) public returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = block.timestamp > lastTimeStamp + i_interval;
        bool isOpen = currentStatus == Status.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_player.length > 3;

        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("0x0");
        require(upkeepNeeded, "Condition not fullfilled!");

        currentStatus = Status.CALCULATING;

        uint256 requestId = COORDINATOR.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
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
