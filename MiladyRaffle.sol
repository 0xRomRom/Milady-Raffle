// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract MiladyRaffle is VRFV2WrapperConsumerBase, ConfirmedOwner {
    bool raffleEnd;
    uint public ENTRY_PRICE;
    uint public ENTRY_CAP;
    uint public PLAYER_CAP;
    uint public PLAYER_COUNT;
    bool public refund;
    address public raffleWinner;
    uint[] public randomNum;
    uint public requestID;
    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2;
    address linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address wrapperAddress = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;

    mapping(address => uint) public participatoors;
    address[] public entrantsWallets;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    struct RequestStatus {
        uint256 paid;
        bool fulfilled;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;

    constructor()
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {
        ENTRY_PRICE = 10000000000000000 wei; // 0.01 ETH
        PLAYER_CAP = 1000;
        ENTRY_CAP = 5;
    }

    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    function RANDOM_WINNER(uint _reqID) public onlyOwner returns (address) {
        uint winnerIndex = s_requests[_reqID].randomWords[0] %
            entrantsWallets.length;
        raffleWinner = entrantsWallets[winnerIndex];
        withdrawRaffleFunds();
        raffleEnd = true;
        return raffleWinner;
    }

    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
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
        require(!raffleEnd, "Raffle has ended.");

        PLAYER_COUNT += _ticketCount;
        participatoors[msg.sender] += _ticketCount;

        for (uint i = 0; i < _ticketCount; i++) {
            entrantsWallets.push(msg.sender);
        }
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
