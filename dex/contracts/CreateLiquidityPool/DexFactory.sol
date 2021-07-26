pragma solidity >=0.5.16;
import "../Interfaces/IUniswapV2Factory.sol";
contract Dexfactory {
  address factoryAddress;
  constructor(address _factory) public {
    factoryAddress = _factory;
  }
  function createLiquidityPool(address _token0, address _token1) external returns(address) {
    // pointer to UniswapV2Factory contract
    IUniswapV2Factory _uniswapV2Factory = IUniswapV2Factory(factoryAddress);
    address _pairAddress = _uniswapV2Factory.createPair(_token0, _token1);
    return _pairAddress;
  }
}