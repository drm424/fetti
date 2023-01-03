// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../node_modules/@openzeppelin/contracts/interfaces/IERC4626.sol";
import "../../node_modules/@openzeppelin/contracts/utils/math/Math.sol";
import "../Vault/IVault.sol";

contract Token is ERC20, IERC4626{
    using Math for uint256;

    IERC20 private immutable _usdc;
    address private _gov;
    IVault private _vault;

    uint256 private _usdcConv = 10**6;
    uint8 private immutable _decimals = 6;

    constructor(IERC20 usdc_, string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _usdc = usdc_;
        _gov = msg.sender;
    }

    function setVault(IVault vault_)external returns(IVault vault){
        require(_gov==msg.sender, "Must be the gov!!");
        _vault = vault_;
        return _vault;
    }

    //function vault() external view returns (address vaultAddress);

    function asset() external view override returns (address assetTokenAddress){
        return address(_usdc);
    }

    function decimals() public pure override(ERC20, IERC20Metadata) returns (uint8) {
        return _decimals;
    }

    //vault address in balanceOf()
    function totalAssets() public view override(IERC4626) returns (uint256 totalManagedAssets){
        return _vault.totalAssets();
    }

    //changes in called function
    function convertToShares(uint256 assets) external view override returns (uint256 shares){
        return _convertToShares(assets, Math.Rounding.Down);
    }

    //changes in called function
    function convertToAssets(uint256 shares) external view override returns (uint256 assets){
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    //always return max amount possible to deposit
    function maxDeposit(address) public view override returns (uint256 maxAssets){
        return _isVaultCollateralized() ? type(uint256).max : 0;
    }

    //always return max amount possible to deposit
    function maxMint(address) public pure override returns (uint256 maxShares){
        return type(uint256).max;
    }

    //should be the same with previous changes
    //return what they would get - vault fee
    function maxWithdraw(address owner) public view override returns (uint256 maxAssets){
        return _convertToAssets(balanceOf(owner), Math.Rounding.Down);
    }

    //should be the same
    function maxRedeem(address owner) public view override returns (uint256 maxShares){
        return balanceOf(owner);
    }

    //should be the same
    function previewDeposit(uint256 assets) public view override returns (uint256 shares){
        return _convertToShares(assets, Math.Rounding.Down);
    }

    //should be the same
    function previewMint(uint256 shares) public view override returns (uint256 assets){
        return _convertToAssets(shares, Math.Rounding.Up);
    }

    //return what they would get - vault fee
    function previewWithdraw(uint256 assets) public view override returns (uint256 shares){
        return _convertToShares(assets, Math.Rounding.Up);
    }

    //return what they get - vault fee
    function previewRedeem(uint256 shares) public view override returns (uint256 assets){
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    //changes made in _deposit not here
    //check for deprecation
    //idk what else is needed
    function deposit(uint256 assets, address receiver) external override returns (uint256 shares){
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");
        require(_usdc.balanceOf(msg.sender)>=assets, "Not enough assets in the wallet");
        uint256 shares_ = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares_);

        return shares;
    }

    function mint(uint256 shares, address receiver) external override returns (uint256 assets){
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 asset_ = previewMint(shares);
        _deposit(_msgSender(), receiver, asset_, shares);

        return assets;
    }

    function withdraw(uint256 assets, address receiver, address owner) external override returns (uint256 shares){
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares__ = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares__);

        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner) external override returns (uint256 assets){
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets__ = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets__, shares);

        return assets;
    }

    //vault.totalAssets() or asset.balanceOf, prob balanceOf
    //also check deprecation
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view returns (uint256 shares) {
        uint256 supply = totalSupply();
        //balance of in line below
        return (assets == 0 || supply == 0) ? _initialConvertToShares(assets, rounding) : assets.mulDiv(supply, totalAssets(), rounding);
    }

    function _initialConvertToShares(uint256 assets, Math.Rounding) internal pure returns (uint256 shares) {
        return assets;
    }

    //get total assets from the vault or balanceOF(vaultAddy)
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view returns (uint256 assets) {
        uint256 supply = totalSupply();
        return (supply == 0) ? _initialConvertToAssets(shares, rounding) : shares.mulDiv(totalAssets(), supply, rounding);
    }

    function _initialConvertToAssets(uint256 shares, Math.Rounding) internal pure returns (uint256 assets) {
        return shares;
    }

    function _isVaultCollateralized() private view returns (bool) {
        return totalAssets() > 0 || totalSupply() == 0;
    }

    //transfer to vault address
    //i think that is the only change, but check again 
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal {
        SafeERC20.safeTransferFrom(_usdc, caller, address(_vault), assets);
        _mint(receiver, shares);
        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }
        _burn(owner, shares);
        _vault.widthdraw(receiver, assets);
        emit Withdraw(caller, receiver, owner, assets, shares);
    }


    function getVaultAssets() internal view returns (uint256 assets){
        return _vault.totalAssets();
    }

}