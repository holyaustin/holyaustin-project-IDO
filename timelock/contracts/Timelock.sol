//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TimeLock {
    address[] keepers;  // holds addresses of time lock keepers
    address masterKeeper;   // master keeper of the time lock
    mapping(address => uint) lockedFunds; // mapping from address to amount of fund locked, formally called 'bank'
    mapping(address => uint) lockedSince;
    mapping(StakeHolder => uint) stakeHoldersBalance;   // hold balance remainig to be distributed to stakeholders
    mapping(StakeHolder => uint) lastDistrbution;       // hold last time since token was distributed to stakeholders
    uint constant DISTRIBUTABLE_SHARES = 3500000 * (10 ** 18);   // total amount of tokens that can be distributed to all stakeholders
    
    // hold a representation for all defined stakeholders
    enum StakeHolder {
        TeamMembers,
        Investors,
        Advisors,
        Ecosystem,
        Liquidity,
        Public
    }
    
    address[] teamMembers;
    address[] investors;
    address[] advisors;

    IERC20 projectX_Token;

    uint deployedAt;            // date when the contract was deployed    
    uint timeToWithdrawfund; //declares the variable for fund withdrawal
    uint minLockAmount;     // minimum amount allowed for locking a token
    uint minLockTime;       // minimum time for which tokens would be locked, specified in days, formerly _timeToWithdrawFund

    modifier timeElapse(address _projectAddress) {
        require(lockedSince[_projectAddress] + (minLockTime * 1 days) >= block.timestamp, "time to unlock not complete yet");     // not tested yet
        _;
    }
    
    // modifier would allow only the keepers or the master keeper to pass
    modifier onlyKeepers() {
        bool allowed;
        if(msg.sender == masterKeeper) {
            allowed = true;
        }else {
            for(uint8 i = 0; i < keepers.length; i++) {
                if(msg.sender == keepers[i]) {
                    allowed = true;
                }
            }   
        }
        require(allowed, "Only keepers or master keeper allowed");
        _;
    }
    
    // modifier would allow only the master keeper to pass
    modifier onlyMaster() {
        require(msg.sender == masterKeeper, "Only master keeper allowed");
        _;
    }
    
    /*
        Events to emit for major contract state transitions
    */
    event MasterChanged (
        address indexed _oldMasterKeeper,
        address indexed _newMasterKeeper
    );
    
    event KeeperAdded (address indexed _newKeeper);
    
    event FundsLocked(
        address indexed _projectAddress,
        uint _amount
    );
    
    event FundsUnlocked(
        address indexed _projectAddress,
        uint _amount
    );

    event TeamMemberAdded(address indexed _newTeamMember);
    
    event InvestorAdded(address indexed _newInvestor);
    
    event AdvisorAdded(address indexed _newAdvisor);    
    
    constructor(address[] memory _keepers, uint _minLockAmount, uint _minLockTime, address _tokenAddress) {
        masterKeeper = msg.sender;
        for(uint8 i = 0; i < _keepers.length; i++) {
            if(_keepers[i] == msg.sender) continue;     // ensure masterKeeper cannot add himeself as keeper
            keepers.push(_keepers[i]);
        }
        deployedAt = block.timestamp;
        minLockAmount = _minLockAmount;
        minLockTime = _minLockTime;
        projectX_Token = IERC20(_tokenAddress);
        _setInitialStakeHoldersBalance();
        _setInitiallastDistrbution();
    }

    // called only once in constructor to set Initial balance for distribution to stakeholders
    function _setInitialStakeHoldersBalance() private {
        stakeHoldersBalance[StakeHolder.TeamMembers] = 20 * DISTRIBUTABLE_SHARES / 100;
        stakeHoldersBalance[StakeHolder.Investors] = 15 * DISTRIBUTABLE_SHARES / 100;
        stakeHoldersBalance[StakeHolder.Advisors] = 10 * DISTRIBUTABLE_SHARES / 100;
    }
    
    // called only once as well to set intitial last distribution time for all stakeholders
    function _setInitiallastDistrbution() private {
        lastDistrbution[StakeHolder.TeamMembers] = block.timestamp;
        lastDistrbution[StakeHolder.Investors] = block.timestamp;
        lastDistrbution[StakeHolder.Advisors] = block.timestamp;
    }

    // update the last time token was distributed for a particular stakeholder
    function _updateLastDistribution(StakeHolder _stakeHolder) private {
        lastDistrbution[_stakeHolder] = block.timestamp;
    }
    
    // for adding keepers for the contract
    function addKeeper(address _keeper) external onlyMaster {
        require(keepers.length < 3, "Keepers limit exceeded");
        require(_keeper != masterKeeper, "Already a master");
        require(_keeper != address(0), "Adress cannot be zero address");
        keepers.push(_keeper);
        emit KeeperAdded(_keeper);
    }
    
    function changeMaster(address _newMaster) external onlyMaster returns(bool) {
        require(_newMaster != masterKeeper, "Already master");
        require(_newMaster != address(0), "Address cannot be zero address");
        if(_isKeeper(_newMaster)) {
            masterKeeper = _newMaster;
            return true;
        }
        return false;
        
    }
    
    // private function to check that an address is a keeper
    function _isKeeper(address _keeper) private view returns(bool) {
        for(uint8 i = 0; i < keepers.length; i++) {
            if(keepers[i] == _keeper) {
                return true;
            }
        }
        return false;
    }
    
    function updateMinLockTime(uint _newLockTime) external onlyKeepers {
        minLockTime = _newLockTime;
    }
    
   // formely deposit(), changed to reflect projectX_Token deposit by a project
    function lockFund(uint _amount) public returns(bool) { // this function is for depositing 
        bool success;
        success = projectX_Token.transferFrom(msg.sender, address(this), _amount);     // initiate transfer to address of this contract
        if(success) {
            lockedFunds[msg.sender] += _amount;
            lockedSince[msg.sender] = block.timestamp;
            emit FundsLocked(msg.sender, _amount);
            return true;
        }
        return false;
    }
    
    // get the amount locked up by a project
    function getLockedAmount(address _projectAddress) external view returns(uint) {
        return lockedFunds[_projectAddress];
    }
    
    // formerly withdraw(), can only be called by keepers after locktime has ellapsed
    // I think we shld remove the _amount argument, and just unlock all funds back to the project address
    function unlockFund(uint _amount, address _projectAddress) external timeElapse(_projectAddress) onlyKeepers returns(bool) {
        bool success;
        require(_amount <= lockedFunds[_projectAddress], "Amount exceed value locked");
        success = projectX_Token.transfer(_projectAddress, _amount);
        if(success) {
            lockedFunds[_projectAddress] -= _amount;
            lockedSince[_projectAddress] = block.timestamp;
            return true;
        }
        return false;
    }

    /*
        ADD THE TEAM MEMBERS, INVESTORS AND ADVISORS
    */
    function addTeamMember(address _newMember) external onlyKeepers {
        teamMembers.push(_newMember);
        emit TeamMemberAdded(_newMember);
    }
    
    function addInvestor(address _newInvestor) external onlyKeepers {
        investors.push(_newInvestor);
        emit InvestorAdded(_newInvestor);
    }
    
    function addAdvisor(address _newAdvisor) external onlyKeepers {
        advisors.push(_newAdvisor);
        emit AdvisorAdded(_newAdvisor);
    }

    // distribute tokens to team members
    function distributeToTeam() external onlyKeepers returns(bool) {
        require(block.timestamp >= deployedAt + (12 * _oneMonth()), "12 months until token can be unlocked for team");
        require(block.timestamp >= lastDistrbution[StakeHolder.TeamMembers] + (1 * _oneMonth()), "Tokens cant be released to team yet");
        uint teamBalance = stakeHoldersBalance[StakeHolder.TeamMembers];
        (uint amountToDistribute, uint _distributeBal) = _divAndRem(20 * teamBalance, 100);
        (uint amountPerPerson, uint _perBal) = _divAndRem(amountToDistribute, teamMembers.length);
        uint _refundBal = _distributeBal + _perBal;
        bool failed;
        for(uint i = 0; i < teamMembers.length; i++) {
            if (!projectX_Token.transfer(teamMembers[i], amountPerPerson)) {
                failed = true;
                break;
            }
        }
        require(!failed, "Token distribution failed");
        stakeHoldersBalance[StakeHolder.TeamMembers] -= (amountToDistribute + _refundBal);
        _updateLastDistribution(StakeHolder.TeamMembers);
        return true;
    }

    // distribute tokens to private investors
    function distributeToInvestors() external onlyKeepers returns(bool) {
        require(block.timestamp >= deployedAt + (1 * _oneMonth()), "1 month until tokens can be unlocked for private investors");
        require(block.timestamp >= lastDistrbution[StakeHolder.Investors] + _oneMonth(), "Tokens cant be released to investors yet");
        uint investorBalance = stakeHoldersBalance[StakeHolder.Investors];
        (uint amountToDistribute, uint _distributeBal) = _divAndRem(25 * investorBalance, 100);
        (uint amountPerInvestor, uint _perBal) = _divAndRem(amountToDistribute, investors.length);
        uint _refundBal = _distributeBal + _perBal;
        bool fail;
        for(uint i = 0; i < investors.length; i++) {
            if(!projectX_Token.transfer(investors[i], amountPerInvestor)) {
                fail = true;
                break;
            }
        }
        require(!fail, "Token distribution failed");
        stakeHoldersBalance[StakeHolder.Investors] -= (amountToDistribute + _refundBal);
        _updateLastDistribution(StakeHolder.Investors);
        return true;
    }
    
    // distribute tokens to advisors
    function distributeToAdvisors() external onlyKeepers returns(bool) {
        require(block.timestamp >= deployedAt + (3 * _oneMonth()), "3 months until tokens can be unlocked for advisors");
        require(block.timestamp >= lastDistrbution[StakeHolder.Advisors] + (3 * _oneMonth()), "Tokens cant be released to ivestors yet");
        uint advisorsBalance = stakeHoldersBalance[StakeHolder.Advisors];
        (uint amountToDistribute, uint _distributeBal) = _divAndRem(25 * advisorsBalance, 100);
        (uint amountPerAdvisor, uint _perBal) = _divAndRem(amountToDistribute, advisors.length);
        uint _refundBal = _distributeBal + _perBal;
        bool fail;
        for(uint i = 0; i < advisors.length; i++) {
            if(!projectX_Token.transfer(advisors[i], amountPerAdvisor)) {
                fail = true;
                break;
            }
        }
        require(!fail, "Token distribution failed");
        stakeHoldersBalance[StakeHolder.Advisors] -= (amountToDistribute + _refundBal);
        _updateLastDistribution(StakeHolder.Advisors);
        return true;
    }
    
    // what would 1 month look like?
    function _oneMonth() private pure returns(uint24) {
        return 60 * 60 * 24 * 7 * 4;
    }
    
    // division and remainder
    function _divAndRem(uint _dividend, uint _divisor) pure private returns(uint, uint) {
        return(_dividend / _divisor, _dividend % _divisor);
    }
    
    // this will prevent ether transfer to this contract, as it isnt meant to hold any ether.
    receive() payable external {
        revert();
    }
}

/*
    MOTIVATION BEHIND THE KEEPERS AND MASTER KEEPER THING 
    SOME THINKINGS;
    (1) Following the specification, it means about 45% of token supply should be transferred to the timeLock contract,
            this 45% represent the 20% share for team, 15% share for private investors, and 10% share for advisors; 
            The problem now is that the native token contract now depends on the address of this time lock contract.
            ---------------------POSSIBLE SOLUTIONS ------------------
            (a) Theres a way to get the address of a contract even before it was deployed
            (b) The token team can delegate an address to send tokens to this time lock contract when it is later deployed.
    
    MOTIVATION BEHIND THE 'lockSince' MAPPING
    (1) When a project locks funds, aside updating her balance, we need to keep track of the time the funds was lockedSince
    (2) When a keeper attempts to unlock this fund, we can easily check that this lock time has ellapsed against the current time(now),
        and then update the state.
    
    MOST OF THE CODE I WROTE HERE HAS NOT BEEN TESTED, I LEFT THAT FOR LATER AFTER EXTENSIVE REVIEW AND MODIFICATION BY TEAMMATES.
*/
