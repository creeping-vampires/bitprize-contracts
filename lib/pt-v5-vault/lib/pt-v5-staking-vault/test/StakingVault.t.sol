// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { ERC20Mock } from "openzeppelin-contracts/mocks/token/ERC20Mock.sol";

import { StakingVault, IERC20 } from "../src/StakingVault.sol";

contract StakingVaultTest is Test {

    StakingVault public stakingVault;
    ERC20Mock public asset;

    function setUp() public {
        asset = new ERC20Mock();
        stakingVault = new StakingVault("Staked MockToken", "sMock", asset);
    }

    function testConstructor() external view {
        assertEq(stakingVault.name(), "Staked MockToken");
        assertEq(stakingVault.symbol(), "sMock");
        assertEq(stakingVault.asset(), address(asset));
        assertEq(stakingVault.totalAssets(), 0);
        assertEq(stakingVault.totalSupply(), 0);
    }

    function testOneToOne() external {
        asset.mint(address(this), 1e18);
        asset.approve(address(stakingVault), 1e18);
        stakingVault.deposit(1e18, address(this));
        assertEq(stakingVault.balanceOf(address(this)), 1e18);
        assertEq(stakingVault.totalAssets(), 1e18);
        assertEq(stakingVault.totalSupply(), 1e18);

        stakingVault.withdraw(1e18, address(this), address(this));
        assertEq(stakingVault.balanceOf(address(this)), 0);
        assertEq(asset.balanceOf(address(this)), 1e18);
        assertEq(stakingVault.totalAssets(), 0);
        assertEq(stakingVault.totalSupply(), 0);
    }

    function testNoYield() external {
        asset.mint(address(this), 1e18);
        asset.approve(address(stakingVault), 1e18);
        stakingVault.deposit(1e18, address(this));
        assertEq(stakingVault.totalAssets(), 1e18);
        assertEq(stakingVault.totalSupply(), 1e18);

        // send assets directly to vault to see if exchange rate changes (it shouldn't)
        asset.mint(address(stakingVault), 1e18);
        assertEq(stakingVault.totalAssets(), 2e18);
        assertEq(stakingVault.totalSupply(), 1e18);

        // withdraw and check 1:1
        stakingVault.withdraw(1e18, address(this), address(this));
        assertEq(stakingVault.balanceOf(address(this)), 0);
        assertEq(stakingVault.totalAssets(), 1e18);
        assertEq(stakingVault.totalSupply(), 0);

        // deposit again to see if the rate is still 1:1
        asset.approve(address(stakingVault), 1e18);
        stakingVault.deposit(1e18, address(this));
        assertEq(stakingVault.balanceOf(address(this)), 1e18);
        assertEq(stakingVault.totalAssets(), 2e18);
        assertEq(stakingVault.totalSupply(), 1e18);
    }
}
