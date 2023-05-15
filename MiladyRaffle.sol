// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";

contract MiladyRaffle is Ownable, VRFV2WrapperConsumerBase {
    uint ENTRY_PRICE;
    uint PLAYER_CAP;
    uint PLAYER_COUNT;
    uint ENTRY_CAP;
    bool refund;
    address raffleWinner;

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

    function requestRandomWords() private returns (uint256 requestId) {
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
        require(PLAYER_COUNT > 300, "Not enough players");

        requestPaid = 0;

        //Store function param (unused)
        uint reqID = _requestId;

        // Winner info
        uint winnerIndex;

        // Winner index and address
        winnerIndex = _randomWords[0];
        raffleWinner = entrantsWallets[winnerIndex];

        requestPaid = 0;
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

    function payWinner() public payable onlyOwner {}

    function emergancyRefundEntrants() public onlyOwner {
        refund = true;
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
