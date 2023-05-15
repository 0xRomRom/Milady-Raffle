// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract MiladyRaffle is Ownable {
    uint ENTRY_PRICE;
    uint PLAYER_CAP;
    uint PLAYER_COUNT;
    uint ENTRY_CAP;

    mapping(address => uint) public participatoors;
    address[] public entrantsWallets;

    constructor() {
        ENTRY_PRICE = 10000000000000000 wei; // 0.01 ETH
        PLAYER_CAP = 1000;
        ENTRY_CAP = 5;
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

        PLAYER_COUNT += _ticketCount;
        participatoors[msg.sender] += _ticketCount;

        for (uint i = 1; i < _ticketCount; i++) {
            entrantsWallets.push(msg.sender);
        }
    }

    function payWinner() public payable onlyOwner {}

    function emergancyRefundEntrants() public payable onlyOwner {}

    function withdrawRaffleFunds() public payable onlyOwner {}

    receive() external payable {}
}
