pragma solidity ^0.8.0;

//SPDX-License-Identifier: None;

//------------------------------------------------------
// ERC20 TOKEN interface
// ------------------------------------------------------



interface ERC20interface{
    function totalsupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    
    function allowance(address owner, address spender) external returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval (address indexed owner, address indexed spender, uint256 value);
}




contract Halogen is ERC20interface{
    
    string private _name;
    
    string private _symbol;
    
    uint256 private _decimals;
    
    uint private _totalsupply;
    
    address public TokenDist;

    address private admin;
    
    mapping(address => uint256) _balances;
    
    mapping(address => mapping(address => uint256)) _allowances;
    
    event TokenDistChanged(address indexed delegator, address indexed delegatee );
    
    event newAdmin(address indexed owner, address indexed newowner);
    
    
    constructor() {
        _name = "Halogen";
        _symbol = "HGN";
        _decimals = 18;
        _totalsupply = 100000000*10**18; /// 100 million;
        _balances[msg.sender] = _totalsupply;
        admin = msg.sender;
        emit Transfer(address(0), msg.sender, _totalsupply);
    }
    
    
     modifier onlyAdmin{
        require(msg.sender == admin, "you are not the admin");
        _;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "HGN: Transfer from the zero address");
        require(recipient != address(0), "HGN: Transfer to the zero address");
        
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "HGN: Transfer amount exceeds in your balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
            _balances[recipient] += amount;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0),"HGN: Transfer from the zero address");
        require(spender != address(0),"HGN: Transfer to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    //@dev function to set the token distributor
    // param _TokenDist address of the token distributor;
    
    function setTokenDist(address _TokenDist) onlyAdmin public {
        emit TokenDistChanged(TokenDist, _TokenDist);
        TokenDist = _TokenDist;
    }
    
    function setNewAdmin(address _newAdmin) onlyAdmin public {
        emit newAdmin(admin, _newAdmin);
        admin = _newAdmin;
    }
    
    function name() public view returns(string memory){
        return _name;
    }
    
    function symbol() public view returns(string memory){
        return _symbol;
    }
    
    function totalsupply() public view override returns(uint256){
        return _totalsupply;
    }
    
    function balanceOf(address account) public view override returns(uint256){
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public override returns(bool){
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool){
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns(uint256){
        return _allowances[owner][spender];
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns(bool){
        _transfer(sender, recipient, amount);
        
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount,"HGN: allowance less than the amount");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        
        return true;
    }
    
}