//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Lottery {
    address payable[] public players;
    address public manager;

    constructor() {
        manager = msg.sender;
        addPlayer(payable(manager));
    }

    receive() payable external {
        require(msg.value == 0.1 ether, "You have to send exactly 0.1 ETH");

        // Convert plain address to payable one
        addPlayer(payable(msg.sender));
    }

    function getBalance() public view returns(uint) {
        require(msg.sender == manager, "you're not the manager");
        return(address(this).balance);
    }

    function addPlayer(address payable player) private {
        players.push(player);
    }

    function random() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() external {
        require(players.length >= 10, "not enough players");
        address payable winner = players[random() % players.length];
        winner.transfer(getBalance());
        reset();
    }

    function reset() private {
        require(msg.sender == manager, "you're not the manager");
        
        // keyword delete will change current value by default value
        delete players;
    }

}