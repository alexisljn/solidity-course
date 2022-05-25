//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract AuctionCreator {
    Auction[] public auctions;

    function createAuction() external {
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}

contract Auction {
    address payable public owner;
    mapping(address => uint) public bids;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash = "";
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    uint public highestBindingBid;
    address payable public highestBidder;
    uint public bidIncrement = 100;

    constructor(address _owner) {
        owner = payable(_owner);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 40320;
    }

    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock);
        _;
    }

    function min(uint a, uint b) pure internal returns(uint) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function placeBid() payable external notOwner afterStart beforeEnd {
        require(auctionState == State.Running);
        require(msg.value >= 100);

        // Sum previous value and value sent of the current user
        uint currentBid = bids[msg.sender] + msg.value;
        
        // Current bid has to be higher than the highest binding bid, otherwise what's the point of bidding ?
        require(currentBid > highestBindingBid);

        bids[msg.sender] = currentBid;

        if (currentBid <= bids[highestBidder]) { // current bid is higher than highest binding bid but lower than highest bidder bid
            // Redefine highestBindingBid with proper value : 
            // If currentBid + bidIncrement is lower than the value bidded by the highest bidder we choose this one
            // Else we choose the entire value bidded by the highest bidder
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else { // currentBid is higher than the value bidded by the highest bidder
            // Redefine highestBindingBid with proper value : 
            // If currentBid is lower than the sum of the bid of the highest bidder + bidIncrement we choose currentBid
            // Else we choose the sum of the highest bidder + bidIncrement
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            
            // Finally, current user is now the highest bidder
            highestBidder = payable(msg.sender);
        }
    }

    function cancelAuction() external onlyOwner {
        auctionState = State.Canceled;
    }

    // Function that respects the Withdrawal pattern
    function finalizeAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint value;

        if (auctionState == State.Canceled) { // Auction canceled
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else { // Auction ended
            if (msg.sender == owner) { // Owner of auction
                recipient = owner;
                value = highestBindingBid;
            } else { // Bidders
                if (msg.sender == highestBidder) { // The one who win the auction
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else { // The losers of the auction
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }

        // Reset bids mapping for current user to prevent he calls the contract multiple tmes
        bids[recipient] = 0;

        recipient.transfer(value);
    }

}