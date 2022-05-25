//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract CrowdFunding {
    mapping(address => uint) public contributors;
    address public admin;
    uint public numberOfContributors;
    uint public minimalContribution;
    uint public deadline;
    uint public goal;
    uint public raisedAmount;

    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint numberOfVoters;
        mapping(address => bool) voters;
    }

    // We store request in a mapping because in the Request struct there is a mapping and arrays can't have mappings as item.
    mapping(uint => Request) public requests;

    uint public numRequests;

    event ContributeEvent(address sender, uint value);
    event CreateRequestEvent(string description, address recipient, uint value);
    event MakePaymentEvent(address recipient, uint value);

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor(uint _goal, uint _deadline) {
        goal = _goal;
        deadline = block.timestamp + _deadline;
        minimalContribution = 100;
        admin = msg.sender;
    }

    receive() payable external {
        contribute();
    }

    function contribute() public payable {
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value >= minimalContribution, "Minimal contribution not met");

        if (contributors[msg.sender] == 0) {
            numberOfContributors++;
        }

        contributors[msg.sender] += msg.value;

        raisedAmount += msg.value;

        emit ContributeEvent(msg.sender, msg.value);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getRefund() public {
        require(block.timestamp > deadline && raisedAmount < goal);
        require(contributors[msg.sender] > 0);

        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];

        recipient.transfer(value);

        contributors[msg.sender] =  0;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        // /!\ Reference type
        Request storage newRequest = requests[numRequests];
        numRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;

        emit CreateRequestEvent(_description, _recipient, _value);
    }

    function voteRequest(uint requestIndex) public {
        require(contributors[msg.sender] > 0);

        // We work directly on the request saved in storage and not on a copy
        Request storage currentRequest =  requests[requestIndex];

        require(currentRequest.voters[msg.sender] == false, "you have already voted");
        currentRequest.voters[msg.sender] = true;
        currentRequest.numberOfVoters++;
    }

    function makePayment(uint requestIndex) public onlyAdmin {
        require(raisedAmount >= goal);
        
        Request storage currentRequest = requests[requestIndex];

        require(currentRequest.completed == false, "Request has been completed");
        require(currentRequest.numberOfVoters >=  numberOfContributors / 2); // 50%

        currentRequest.recipient.transfer(currentRequest.value);

        currentRequest.completed = true;

        emit MakePaymentEvent(currentRequest.recipient, currentRequest.value);
    }
}