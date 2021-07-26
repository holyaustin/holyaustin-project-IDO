// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


// This is a test token made compatible with ERC20 standard courtesy @openzeppelin
contract ProjectXToken is ERC20 {
    constructor() ERC20("E20 Token", "E20") {
        _mint(_msgSender(), 100000000 * 10^18);  // mint a hundred milliom projectX tokens
    }
}