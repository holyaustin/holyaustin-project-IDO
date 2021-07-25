pragma solidity 0.8.4;

//import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract TokenA is ERC20{
    constructor(uint256 initialSupply) ERC20("Web3Bridge", "W3B") {
        _mint(msg.sender, initialSupply);
    }
}
contract TokenB is ERC20{
    constructor(uint256 initialSupply) ERC20("Web3Bridge1", "W3B1") {
        _mint(msg.sender, initialSupply);
    }
}