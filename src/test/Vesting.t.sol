// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./utils/VestingTest.sol";
import { Errors, VestingSchedule } from "../Vesting.sol";

contract GrantVesting is VestingTest {
  function testCanGrantVesting(
    address toGrant,
    uint16 numberOfMonths,
    uint32 amountPerMonth
  ) public {
    if (toGrant == address(0x0)) {
      return;
    } else {
      alice.grantVesting(toGrant, numberOfMonths, amountPerMonth);

      (
        uint256 lastClaim,
        uint16 monthsRemaining,
        uint32 tokensPerMonth
      ) = vestingContract.getVestingSchedule(toGrant);
      assertEq(lastClaim, block.timestamp);
      assertEq(monthsRemaining, numberOfMonths);
      assertEq(tokensPerMonth, amountPerMonth);
    }
  }

  function testCannotGrantVestingWithInvalidInputs(
    address toGrant,
    uint16 numberOfMonths,
    uint32 amountPerMonth
  ) public {
    if (toGrant == address(0x0)) {
      try alice.grantVesting(toGrant, numberOfMonths, amountPerMonth) {
        fail();
      } catch Error(string memory error) {
        assertEq(error, Errors.InvalidInput);
      }
    } else {
      assertTrue(true);
    }
  }

  function testCanOverwriteGrantedVesting(
    address toGrant,
    uint16 numberOfMonths,
    uint32 amountPerMonth
  ) public {
    if (toGrant == address(0x0)) {
      return;
    } else {
      alice.grantVesting(toGrant, 1, 1);
      alice.grantVesting(toGrant, numberOfMonths, amountPerMonth);

      (
        uint256 lastClaim,
        uint16 monthsRemaining,
        uint32 tokensPerMonth
      ) = vestingContract.getVestingSchedule(toGrant);
      assertEq(monthsRemaining, numberOfMonths);
      assertEq(tokensPerMonth, amountPerMonth);
    }
  }

  function testCanRevokeGrantedVesting(
    address toGrant,
    uint16 numberOfMonths,
    uint32 amountPerMonth
  ) public {
    if (toGrant == address(0x0) || amountPerMonth == 0 || numberOfMonths == 0) {
      return;
    } else {
      alice.grantVesting(toGrant, numberOfMonths, amountPerMonth);
      alice.revokeVesting(toGrant);

      (
        uint256 lastClaim,
        uint16 monthsRemaining,
        uint32 tokensPerMonth
      ) = vestingContract.getVestingSchedule(toGrant);
      assertEq(monthsRemaining, 0);
      assertEq(tokensPerMonth, 0);
    }
  }
}

contract ClaimTokens is VestingTest {
  function testCanClaimTokensGivenTimePassed(
    uint16 numberOfMonths,
    uint32 amountPerMonth
  ) public {
    alice.grantVesting(address(bob), numberOfMonths, amountPerMonth);

    givenMonthsFromNow(numberOfMonths);
    givenVestingContractHasNFTs(
      uint256(numberOfMonths) * uint256(amountPerMonth)
    );
    uint256 nftsClaimed = bob.claimTokens();
    assertEq(nftsClaimed, uint256(numberOfMonths) * uint256(amountPerMonth));
    assertEq(
      token.balanceOf(address(bob), tokenId),
      uint256(numberOfMonths) * uint256(amountPerMonth)
    );
  }

  function testCanClaimTokensGivenMoreTimePassedThanRemaining(
    uint16 numberOfMonths,
    uint16 monthsExcess,
    uint32 amountPerMonth
  ) public {
    alice.grantVesting(address(bob), numberOfMonths, amountPerMonth);

    uint32 monthsPassed = uint32(numberOfMonths) + monthsExcess;
    givenMonthsFromNow(monthsPassed);
    givenVestingContractHasNFTs(
      uint256(numberOfMonths) * uint256(amountPerMonth)
    );
    uint256 nftsClaimed = bob.claimTokens();
    assertEq(nftsClaimed, uint256(numberOfMonths) * uint256(amountPerMonth));
    assertEq(
      token.balanceOf(address(bob), tokenId),
      uint256(numberOfMonths) * uint256(amountPerMonth)
    );
  }

  function testCanClaimTokensGivenLessTimePassedThanRemaining(
    uint16 numberOfMonths,
    uint16 monthsLess,
    uint32 amountPerMonth
  ) public {
    alice.grantVesting(address(bob), numberOfMonths, amountPerMonth);

    if (monthsLess > numberOfMonths) {
      monthsLess = numberOfMonths;
    }

    uint32 monthsPassed = uint32(numberOfMonths) - monthsLess;
    givenMonthsFromNow(monthsPassed);
    givenVestingContractHasNFTs(
      uint256(numberOfMonths) * uint256(amountPerMonth)
    );
    uint256 nftsClaimed = bob.claimTokens();
    assertEq(nftsClaimed, uint256(monthsPassed) * uint256(amountPerMonth));
    assertEq(
      token.balanceOf(address(bob), tokenId),
      uint256(monthsPassed) * uint256(amountPerMonth)
    );
  }

  function testClaimTokensGivenNoTimePassed(
    uint16 amountPerMonth,
    uint32 numberOfMonths
  ) public {
    alice.grantVesting(address(bob), amountPerMonth, numberOfMonths);

    givenVestingContractHasNFTs(
      uint256(numberOfMonths) * uint256(amountPerMonth)
    );
    uint256 nftsClaimed = bob.claimTokens();
    assertEq(nftsClaimed, 0);
    assertEq(token.balanceOf(address(bob), tokenId), 0);
  }

  function testCannotClaimTokensWithoutTokens(
    uint16 numberOfMonths,
    uint32 amountPerMonth
  ) public {
    alice.grantVesting(address(bob), numberOfMonths, amountPerMonth);

    givenMonthsFromNow(numberOfMonths);
    if (amountPerMonth == 0 || numberOfMonths == 0) {
      // tested in testCanClaimTokensGivenTimePassed, will return 0
      return;
    }
    try bob.claimTokens() {
      fail();
    } catch Error(string memory error) {
      assertEq(error, Errors.InsufficientTokenBalance);
    }
  }
}

contract WithdrawTokens is VestingTest {
  function testCanWithdrawTokens(uint256 numberOfTokens) public {
    givenVestingContractHasNFTs(numberOfTokens);
    alice.withdrawTokens(numberOfTokens);

    assertEq(token.balanceOf(address(alice), tokenId), numberOfTokens);
  }

  function testCannotWithdrawMoreTokensThanAvailable(uint256 numberOfTokens)
    public
  {
    givenVestingContractHasNFTs(numberOfTokens);
    try alice.withdrawTokens(numberOfTokens + 10) {
      fail();
    } catch Error(string memory error) {
      assertEq(error, Errors.InsufficientTokenBalance);
    }
  }
}
