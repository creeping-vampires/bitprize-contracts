// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20, IERC4626 } from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import { SafeERC20 } from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import { StakingVault } from "./StakingVault.sol";

interface IPrizeVaultFactory {
    function deployVault(
        string memory _name,
        string memory _symbol,
        address _yieldVault,
        address _prizePool,
        address _claimer,
        address _yieldFeeRecipient,
        uint32 _yieldFeePercentage,
        uint256 _yieldBuffer,
        address _owner
    ) external returns (address);
}

/// @title  PoolTogether V5 Prize Staking Vault Factory
/// @author G9 Software Inc.
/// @notice Factory contract for deploying no-yield prize vaults using an underlying asset.
contract PrizeStakingVaultFactory {
    using SafeERC20 for IERC20;

    ////////////////////////////////////////////////////////////////////////////////
    // Events
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when a new StakingVault has been deployed by this factory.
    /// @param vault The staking vault that was deployed
    /// @param asset The underlying asset of the staking vault
    /// @param name The name of the vault token
    /// @param symbol The symbol for the vault token
    event NewStakingVault(
        StakingVault indexed vault,
        IERC20 indexed asset,
        string name,
        string symbol
    );

    ////////////////////////////////////////////////////////////////////////////////
    // Variables
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice List of all staking vaults deployed by this factory.
    StakingVault[] public allVaults;

    /// @notice Mapping to verify if a staking vault has been deployed via this factory.
    mapping(address vault => bool deployedByFactory) public deployedVaults;

    /// @notice Mapping to store deployer nonces for CREATE2
    mapping(address deployer => uint256 nonce) public deployerNonces;

    ////////////////////////////////////////////////////////////////////////////////
    // External Functions
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Deploy a new prize staking vault using the specified parameters
    /// @param _name Name of the ERC20 share minted by the prize vault
    /// @param _symbol Symbol of the ERC20 share minted by the prize vault
    /// @param _asset The asset that will be staked
    /// @param _prizeVaultFactory The prize vault factory to use to deploy the prize vault
    /// @param _prizePool The prize pool that the prize vault will participate in
    /// @param _claimer Address of the claimer to set on the prize vault
    /// @param _owner Address that will gain ownership of the prize vault
    /// @return address The newly deployed prize vault address
    function deployPrizeStakingVault(
      string memory _name,
      string memory _symbol,
      IERC20 _asset,
      IPrizeVaultFactory _prizeVaultFactory,
      address _prizePool,
      address _claimer,
      address _owner
    ) external returns (address) {
        string memory _stakingVaultName = string.concat("Staking Vault - ", _name);
        string memory _stakingVaultSymbol = string.concat("stk-", _symbol);
        StakingVault _stakingVault = new StakingVault{
            salt: keccak256(abi.encode(msg.sender, deployerNonces[msg.sender]++))
        }(
            _stakingVaultName,
            _stakingVaultSymbol,
            _asset
        );
        
        address _prizeVault = _prizeVaultFactory.deployVault(
            _name,
            _symbol,
            address(_stakingVault),
            _prizePool,
            _claimer,
            address(0),     // _yieldFeeRecipient
            0,              // _yieldFeePercentage
            0,              // _yieldBuffer
            _owner
        );

        allVaults.push(_stakingVault);
        deployedVaults[address(_stakingVault)] = true;

        emit NewStakingVault(
            _stakingVault,
            _asset,
            _stakingVaultName,
            _stakingVaultSymbol
        );

        return _prizeVault;
    }

    /// @notice Total number of vaults deployed by this factory.
    /// @return uint256 Number of vaults deployed by this factory.
    function totalVaults() external view returns (uint256) {
        return allVaults.length;
    }
}