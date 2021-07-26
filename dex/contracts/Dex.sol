//SPDX-License-Identifier: Unlicense
pragma solidity =0.6.6;

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IERC20.sol";
import "./libraries/UniswapV2Library.sol";

contract Dex {
  IUniswapV2Router02 uniswapV2Router;
  address[] public liquidityPools;

  constructor(address _router) public {
    uniswapV2Router = IUniswapV2Router02(_router);
  }
  
  function createLiquidityPool(address _tokenA, address _tokenB) internal returns(address) {
    IUniswapV2Factory factory = IUniswapV2Factory(uniswapV2Router.factory());
    address pairAddress = factory.createPair(_tokenA, _tokenB);
    liquidityPools.push(pairAddress);
    return pairAddress;
  }

  // router 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  // pairAddress = 0x289B25Bf99463282aDb740A300EB0DDBd9459d0C
  // token0 0x26Cdf6Fba8D42949075c7921d78F2DC1e252737A
  // token1 0x7e90f2d52bcE8c43Fb7Dd6C78aE33fCB895DB98F

  // Avoids "CompilerError: Stack too deep, try removing local variables"
  function _addLiquidity(
    address _tokenA,
    address _tokenB,
    uint _amountTokenA,
    uint _amountTokenB,
    uint _amountTokenAMin,
    uint _amountTokenBMin,
    address _to,
    uint deadline
  ) private returns (uint amountA, uint amountB, uint liquidity) {
    return uniswapV2Router.addLiquidity(_tokenA, _tokenB, _amountTokenA, _amountTokenB, _amountTokenAMin, _amountTokenBMin, _to, deadline);
  }

  function addLiquidity(
    address _tokenA,
    address _tokenB,
    uint _amountTokenA,
    uint _amountTokenB,
    uint _amountTokenAMin,
    uint _amountTokenBMin
    ) public {
    IUniswapV2Factory _factory = IUniswapV2Factory(uniswapV2Router.factory());
    address pairAddress = _factory.getPair(_tokenA, _tokenB);
    require(pairAddress != address(0), 'This pool does not exist');
    uint deadline = 20 minutes;
    IERC20 tokenA = IERC20(_tokenA);
    IERC20 tokenB = IERC20(_tokenB);
    tokenA.approve(address(uniswapV2Router), _amountTokenA);
    tokenB.approve(address(uniswapV2Router), _amountTokenB);
    _addLiquidity(_tokenA, _tokenB, _amountTokenA, _amountTokenB, _amountTokenAMin, _amountTokenBMin, msg.sender, deadline);

  }

}
