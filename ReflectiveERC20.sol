// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Context.sol";

import "./LiquidityAcquisition.sol";

contract ReflectiveERC20 is IERC20, Context, Ownable, LiquidityAcquisition {
    mapping(address => uint256) internal _rOwned;
    mapping(address => uint256) internal _tOwned;
    mapping(address => mapping(address => uint256)) internal _allowances;

    mapping(address => bool) internal _isExcludedFromFee;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal _tTotal;
    uint256 internal _rTotal;
    uint256 internal _tFeeTotal;

    uint8 public reflectionFee;
    uint8 public swapFee;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_,
        uint8 reflectionFee_,
        uint8 swapFee_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _tTotal = totalSupply_ * 10**_decimals;
        _rTotal = (MAX - (MAX % _tTotal));

        // Reflective fee defaults
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        reflectionFee = reflectionFee_;
        swapFee = swapFee_;

        _rOwned[_msgSender()] = _rTotal;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    /**
     * Base ERC20 Functions
     */

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * ERC20 Helpers
     */

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Always expected to be overwritten by parent contract
    // since its' implementation is contract-specific
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {}

    /**
     * Base Reflection Functions
     */

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        return rAmount / _getRate();
    }

    function reflectionFromToken(uint256 tAmount) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        return tAmount * _getRate();
    }

    /**
     * Reflection Helpers
     */

    function _getValues(uint256 tAmount, bool takeFee)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currentRate = _getRate();
        uint256 tFee = 0;
        uint256 tSwap = 0;

        if (takeFee) {
            tFee = (tAmount * reflectionFee) / 100;
            tSwap = (tAmount * swapFee) / 100;
        }

        uint256 tTransferAmount = tAmount - tFee - tSwap;

        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rSwap = tSwap * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rSwap;

        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tSwap);
    }

    function _getRate() internal view virtual returns (uint256) {
        return _rTotal / _tTotal;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) internal {
        _rTotal -= rFee;
        _tFeeTotal += tFee;
    }

    function _takeSwapFee(uint256 tSwapFee) internal virtual {
        uint256 currentRate = _getRate();
        uint256 rSwapFee = tSwapFee * currentRate;
        _rOwned[address(this)] += rSwapFee;
    }
}
