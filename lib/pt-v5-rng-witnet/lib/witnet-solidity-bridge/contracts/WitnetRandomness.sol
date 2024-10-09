// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IWitnetOracleEvents.sol";
import "./interfaces/IWitnetRandomness.sol";
import "./interfaces/IWitnetRandomnessEvents.sol";

abstract contract WitnetRandomness
    is
        IWitnetOracleEvents,
        IWitnetRandomness,
        IWitnetRandomnessEvents
{
    function class() virtual external view returns (string memory);
    function specs() virtual external view returns (bytes4);
}
