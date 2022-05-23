//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;
 
contract Concat {
    
    function concat(string memory s1, string memory s2) public pure returns(string memory) {
        return(string(abi.encodePacked(s1, s2)));
    }
}