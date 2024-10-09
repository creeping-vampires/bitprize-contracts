// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

import {
  UniformRandomNumber,
  UpperBoundGtZero
} from "../src/UniformRandomNumber.sol";

import { UniformRandomNumberWrapper } from "./wrapper/UniformRandomNumberWrapper.sol";

contract UniformRandomNumberTest is Test {

  UniformRandomNumberWrapper wrapper;

  function setUp() public {
    wrapper = new UniformRandomNumberWrapper();
  }

  function testUniform_UpperBoundGtZero() public {
    vm.expectRevert(abi.encodeWithSelector(UpperBoundGtZero.selector));
    wrapper.uniform(0x1234, 0);
  }

  function testUniform() public {
    // Upper bound is 10
    // Max uint is 115792089237316195423570985008687907853269984665640564039457584007913129639935
    // So -upperBound = 115792089237316195423570985008687907853269984665640564039457584007913129639935 - 10 + 1
    //    -upperBound = 115792089237316195423570985008687907853269984665640564039457584007913129639926
    // =>
    // min = -upperBound % upperBound = 6
    // So we skip values less than 6

    for (uint i = 0; i < 6; i++) {
      assertEq(wrapper.uniform(i, 10), rehashRandomNumber(i, 10));
    }
    assertEq(wrapper.uniform(6, 10), 6, "first non-biased entropy");
  }

  function rehashRandomNumber(uint randomNumber, uint upperBound) internal pure returns (uint256) {
    uint rehash = uint256(keccak256(abi.encodePacked(randomNumber)));
    return rehash % upperBound;
  }

}
