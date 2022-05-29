//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

contract AlonsoCoin is ERC20Interface {
    string public name = "AlonsoCoin";
    string public symbol = "ALO";
    uint public decimals = 0; // 0 to 18 generally
    uint public override totalSupply;

    address public founder; // not part of ERC standard
    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) allowed; // One address allows several addresses to transfer some amounts of tokens from its balance.

    constructor() {
        founder = msg.sender;
        totalSupply = 1000000;
        balances[founder] = totalSupply;
    }

    function balanceOf(address tokenOwner) public override view returns(uint) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public virtual override returns (bool success) {
        require(balances[msg.sender] >= tokens);
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;

        emit Transfer(msg.sender, to, tokens);

        return true;
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;
    }

    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success) {
        require(allowed[from][msg.sender] >= tokens);
        require(balances[from] >= tokens);

        balances[to] += tokens;
        balances[from] -= tokens;
        
        allowed[from][msg.sender] -= tokens;

        emit Transfer(from, to, tokens);

        return true;
    }
}

contract AlonsoCoinICO is AlonsoCoin {
    address public admin;
    address payable public deposit;
    uint public tokenPrice = 0.001 ether; // 1ETH = 1000ALO
    uint public hardCap = 300 ether;
    uint public raisedAmount;
    uint public saleStart = block.timestamp + 30; // 30 seconds after deployment
    uint public saleEnd = saleStart + 120; // ICO ends in 2 minutes
    uint public tokenTradeStart = saleEnd + 60; // transferrable 1 minute after the ICO end.
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.01 ether;
    
    enum State {beforeStart, running, afterEnd, halted}

    State public icoState;
    
    constructor(address payable _deposit) {
        admin = msg.sender;
        deposit = _deposit;
        icoState = State.beforeStart;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    event Invest(address investor, uint value, uint tokens);

    function halt() public onlyAdmin {
        icoState = State.halted;
    }

    function resume() public onlyAdmin {
        icoState = State.running;
    }

    function changeDeposit(address payable newDeposit) public onlyAdmin {
        deposit = newDeposit;
    }

    function getCurrentState() public view returns(State){
        if(icoState == State.halted){
            return State.halted;
        }else if(block.timestamp < saleStart){
            return State.beforeStart;
        }else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }

    function invest() payable public returns(bool) {
        icoState = getCurrentState();
        require(icoState == State.running);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        raisedAmount += msg.value;
        require(raisedAmount <= hardCap);

        uint tokens = msg.value / tokenPrice;

        balances[msg.sender] += tokens;
        balances[admin] -= tokens;

        deposit.transfer(msg.value);

        emit Invest(msg.sender, msg.value, tokens);

        return true;
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        require(block.timestamp > tokenTradeStart);
        super.transfer(to, tokens); // AlonsoCoin.transfer() works too
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        require(block.timestamp > tokenTradeStart);
        super.transferFrom(from, to, tokens); // AlonsoCoin.transfer() works too
        return true;
    }

    function burn() public returns (bool) {
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[admin] = 0;
        return true;
    }


    receive() payable external {
        invest();
    }
}