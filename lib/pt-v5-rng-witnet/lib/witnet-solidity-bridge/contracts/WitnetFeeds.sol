// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./interfaces/IFeeds.sol";
import "./interfaces/IWitnetFeeds.sol";
import "./interfaces/IWitnetFeedsAdmin.sol";

import "ado-contracts/contracts/interfaces/IERC2362.sol";

abstract contract WitnetFeeds
    is 
        IERC2362,
        IFeeds,
        IWitnetFeeds,
        IWitnetFeedsAdmin,
        IWitnetOracleEvents
{
    Witnet.RadonDataTypes immutable public override dataType;

    function class() virtual external view returns (string memory);
    function specs() virtual external view returns (bytes4);
    function witnet() virtual external view returns (WitnetOracle);

    constructor(
            Witnet.RadonDataTypes _dataType,
            string memory _prefix
        )
    {
        dataType = _dataType;
        __prefix = Witnet.toBytes32(bytes(_prefix));
    }

    bytes32 immutable internal __prefix;

    function prefix() override public view returns (string memory) {
        return Witnet.toString(__prefix);
    }
}
