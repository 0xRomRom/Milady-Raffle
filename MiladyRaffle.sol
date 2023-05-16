// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";

contract MiladyRaffle is Ownable, VRFV2WrapperConsumerBase {
    uint public ENTRY_PRICE;
    uint public ENTRY_CAP;
    uint public PLAYER_CAP;
    uint public PLAYER_COUNT;
    bool public refund;
    address public raffleWinner;
    uint[] public randomNum;
    uint public requestID;

    mapping(address => uint) public participatoors;
    address[] public entrantsWallets;

    uint32 callbackGasLimit = 500000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    // Address LINK - hardcoded for Sepolia
    address linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    // address WRAPPER - hardcoded for Sepolia
    address wrapperAddress = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;

    uint private requestPaid;

    constructor() VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) {
        ENTRY_PRICE = 10000000000000000 wei; // 0.01 ETH
        PLAYER_CAP = 1000;
        ENTRY_CAP = 5;
    }

    function requestRandomWords() public onlyOwner returns (uint256 requestId) {
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );

        requestPaid = VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(requestPaid > 0, "request not found");

        //Store function param (unused)
        requestID = _requestId;
        randomNum = _randomWords;

        // Winner info
        uint finalWinner;

        // Winner index and address

        finalWinner = randomNum[0] % PLAYER_COUNT;
        raffleWinner = entrantsWallets[finalWinner];

        withdrawRaffleFunds();
    }

    function enterRaffle(uint _ticketCount) public payable {
        require(
            PLAYER_COUNT + _ticketCount <= PLAYER_CAP,
            "Cap potentially reached. If more than 1 ticket, try with fewer."
        );
        require(
            msg.value >= _ticketCount * ENTRY_PRICE,
            "Not enough funds to pay for tickets."
        );
        require(
            entrantsWallets.length + _ticketCount <= PLAYER_CAP,
            "Try with fewer tickets."
        );
        require(
            _ticketCount <= ENTRY_CAP,
            "Cap reached, try with fewer tickets"
        );
        require(
            participatoors[msg.sender] + _ticketCount <= ENTRY_CAP,
            "Ticket cap reached"
        );

        PLAYER_COUNT += _ticketCount;
        participatoors[msg.sender] += _ticketCount;

        for (uint i = 0; i < _ticketCount; i++) {
            entrantsWallets.push(msg.sender);
        }
    }

    function pickWinner() public payable onlyOwner {
        requestRandomWords();
    }

    function emergancyRefundEntrants() public onlyOwner {
        refund = !refund;
    }

    function withdrawRefund() public {
        require(refund, "Refund is not available");
        require(participatoors[msg.sender] > 0, "Nothing to withdraw");

        uint refundAmount = participatoors[msg.sender] * ENTRY_PRICE;

        participatoors[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);

        require(participatoors[msg.sender] == 0, "Failed to withdraw");
    }

    function withdrawRaffleFunds() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}
