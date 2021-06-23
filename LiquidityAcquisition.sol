// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract InternalToken {
    // This is always expected to be
    // overwritten by a parent contract
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {}
}

contract LiquidityAcquisition is InternalToken {
    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV2Pair public immutable uniswapV2Pair;

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        );
        IUniswapV2Pair _uniswapV2Pair = IUniswapV2Pair(
            IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
                address(this),
                _uniswapV2Router.WETH()
            )
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
    }

    event SwapFailure(string reason);

    // Always expected to be overwritten by parent contract
    // since its' implementation is contract-specific
    function _checkSwapViability(address sender) internal virtual {}

    function swapTokensForBnb(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        try
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            )
        {} catch Error(string memory reason) {
            emit SwapFailure(reason);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) internal {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        try
            uniswapV2Router.addLiquidityETH{value: bnbAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                address(this),
                block.timestamp
            )
        {} catch Error(string memory reason) {
            emit SwapFailure(reason);
        }
    }
}
