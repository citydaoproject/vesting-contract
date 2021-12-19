// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./utils/VestingTest.sol";
import { Errors, VestingSchedule } from "../Vesting.sol";

contract GrantVesting is VestingTest {
  function proveCanGrantVesting(
    address toGrant,
    uint256 amountPerMonth,
    uint256 numberOfMonths
  ) public {
    if (toGrant == address(0x0) || amountPerMonth == 0 || numberOfMonths == 0) {
      return;
    } else {
      alice.grantVesting(toGrant, amountPerMonth, numberOfMonths);

      (
        uint256 lastClaim,
        uint256 monthsRemaining,
        uint256 nftsPerMonth
      ) = vestingContract.getVestingSchedule(toGrant);
      assertEq(lastClaim, block.timestamp);
      assertEq(monthsRemaining, numberOfMonths);
      assertEq(nftsPerMonth, amountPerMonth);
    }
  }

  function proveCannotGrantVestingWithInvalidInputs(
    address toGrant,
    uint256 amountPerMonth,
    uint256 numberOfMonths
  ) public {
    if (toGrant == address(0x0) || amountPerMonth == 0 || numberOfMonths == 0) {
      try alice.grantVesting(toGrant, amountPerMonth, numberOfMonths) {
        fail();
      } catch Error(string memory error) {
        assertEq(error, Errors.InvalidInput);
      }
    } else {
      assertTrue(true);
    }
  }
}

contract ClaimNFTs is VestingTest {
  function testCanClaimNFTs(uint256 amountPerMonth, uint256 numberOfMonths)
    public
  {
    alice.grantVesting(address(bob), amountPerMonth, numberOfMonths);
    bob.claimNFTs();
  }
}

// contract VestingTest is DSTest {
//   Vesting vesting;

//   function setUp() public {
//     vesting = new Vesting();
//   }

//   function alaimNFTs() public {
//     vesting.claimNFTs();
//     assertTrue(true);
//   }

//   function testCitizenNftAddress(
//     address citizenNftAddress,
//     uint256 citizenNftId
//   ) public {
//     vesting.setCitizenNft(citizenNftAddress, citizenNftId);
//     (address _citizenNftAddress, uint256 _citizenNftId) = vesting
//       .getCitizenNft();
//     assertEq(_citizenNftAddress, citizenNftAddress);
//     assertEq(_citizenNftId, citizenNftId);
//   }

// function testGrantVesting(
//   address toGrant,
//   uint256 amountPerMonth,
//   uint256 numberOfMonths
// ) public {
//   if (toGrant == address(0x0) || amountPerMonth == 0 || numberOfMonths == 0) {
//     return;
//   } else {
//     vesting.grantVesting(toGrant, amountPerMonth, numberOfMonths);
//     assertEq(vesting.getMonthsRemaining(toGrant), numberOfMonths);
//     assertEq(vesting.getNftsPerMonth(toGrant), amountPerMonth);
//   }
// }

//   function testFailGrantVesting(
//     address toGrant,
//     uint256 amountPerMonth,
//     uint256 numberOfMonths
//   ) public {
//     if (toGrant == address(0x0) || amountPerMonth == 0 || numberOfMonths == 0) {
//       givenAddressHasGrantedNFTs(toGrant, amountPerMonth, numberOfMonths);
//       assertEq(vesting.getMonthsRemaining(toGrant), numberOfMonths);
//       assertEq(vesting.getNftsPerMonth(toGrant), amountPerMonth);
//     } else {
//       assertTrue(false);
//     }
//   }

//   function givenAddressHasGrantedNFTs(
//     address toGrant,
//     uint256 amountPerMonth,
//     uint256 numberOfMonths
//   ) public {
//     vesting.grantVesting(toGrant, amountPerMonth, numberOfMonths);
//   }
// }
