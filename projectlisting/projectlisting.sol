gpragma solidity ^0.8.0;

import './d.sol'; //imports the erc20 token to verify if a project has a token

contract projectListing{
    struct ProjectProps{
        string projectName;
        string projectDescription;
        address projectId;//each members will have a unique is called address
        uint amountoraise;
        // uint amountraised;
        mapping(address=>uint256) funding ;//this will map the address of projects to funds donated;
        // mapping(address=>uint256) tokendepo; ///brb
        mapping(address=>bool) approval;
        bool canbefunded;
    }
    
    
    mapping (address=>ProjectProps)project;
    function addProjectToIdo(string memory _projectName,string memory _projectDescription,address _projectId ,uint  _amountoraise) public {
     //   require(); require to stake from the timelock contract, call function to stake
        ProjectProps storage a=project[_projectId]; //
        a.projectName=_projectName;
        a.projectId=_projectId;
        a.projectDescription=_projectDescription;
        a.approval[_projectId]=true;
        a.amountoraise=_amountoraise;
        // requestForFunding(_projectName,_projectDescription,_projectId);
        
}
function requestForFunding(address _projectId) public  {
        ProjectProps storage a=project[_projectId];
        // require(a.approval[_projectId]==true);
    
        ProjectXToken token= ProjectXToken(0xd9145CCE52D386f254917e481eB44e9943F39138);
        require(token.balanceOf(_projectId)== 100);
        a.canbefunded=true;
        
        
        
}
function fundproject(address _projectId )public payable{
     ProjectProps storage a=project[_projectId];
       require (a.canbefunded==true);
    //   require(a.approval[_projectId]==true);
    //  ProjectXToken token= ProjectXToken(0xd9145CCE52D386f254917e481eB44e9943F39138);
    //   require(token.balanceOf(_projectId)== 100);
      a.funding[_projectId]+=msg.value;
      
      
      
      
      
}
}
 