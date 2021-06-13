// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./ReflectiveERC20.sol";
import "./LiquidityAcquisition.sol";

contract ReflectiveToken is ReflectiveERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_,
        uint8 reflectionFee_,
        uint8 swapFee_
    )
        ReflectiveERC20(name_, symbol_, totalSupply_, decimals_, reflectionFee_, swapFee_)
    {}

    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balanceOf(sender) >= amount, "Not enough balance");

        bool takeFee = true;

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        } else {
            _swap(sender);
        }

        uint256 transferAmount = _tokenTransfer(sender, recipient, amount, takeFee);

        emit Transfer(sender, recipient, transferAmount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) internal virtual returns (uint256) {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tSwapFee
        ) = _getValues(amount, takeFee);

        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;

        _takeSwapFee(tSwapFee);
        _reflectFee(rFee, tFee);

        return tTransferAmount;
    }
}
