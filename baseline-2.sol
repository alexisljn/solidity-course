//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract CryptosToken{
    address public owner;
    string constant public name = "Cryptos";
    uint supply;

    constructor(uint _supply) {
        owner = msg.sender;
        supply = _supply;
    }

    function getSupply() public view returns(uint) {
        return supply;
    }

    function setSupply(uint _supply) public  {
        supply = _supply;
    }

}