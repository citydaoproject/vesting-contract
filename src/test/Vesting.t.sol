// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./utils/VestingTest.sol";
import {Errors, VestingSchedule} from "../Vesting.sol";

contract GrantVestingTokens is VestingTest {
    function testCanGrantVestingTokens(
        address toGrant,
        uint16 numberOfMonths,
        uint32 amountPerMonth
    ) public {
        if (toGrant == address(0x0)) {
            return;
        } else {
            alice.grantVestingTokens(toGrant, numberOfMonths, amountPerMonth);

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

    function testCannotGrantVestingTokensWithInvalidInputs(
        address toGrant,
        uint16 numberOfMonths,
        uint32 amountPerMonth
    ) public {
        if (toGrant == address(0x0)) {
            try
                alice.grantVestingTokens(
                    toGrant,
                    numberOfMonths,
                    amountPerMonth
                )
            {
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
            alice.grantVestingTokens(toGrant, 1, 1);
            alice.grantVestingTokens(toGrant, numberOfMonths, amountPerMonth);

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
        if (
            toGrant == address(0x0) ||
            amountPerMonth == 0 ||
            numberOfMonths == 0
        ) {
            return;
        } else {
            alice.grantVestingTokens(toGrant, numberOfMonths, amountPerMonth);
            alice.revokeVestingTokens(toGrant);

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
        alice.grantVestingTokens(address(bob), numberOfMonths, amountPerMonth);

        givenMonthsFromNow(numberOfMonths);
        givenVestingContractHasNFTs(
            uint256(numberOfMonths) * uint256(amountPerMonth)
        );
        uint256 nftsClaimed = bob.claimTokens();
        assertEq(
            nftsClaimed,
            uint256(numberOfMonths) * uint256(amountPerMonth)
        );
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
        alice.grantVestingTokens(address(bob), numberOfMonths, amountPerMonth);

        uint32 monthsPassed = uint32(numberOfMonths) + monthsExcess;
        givenMonthsFromNow(monthsPassed);
        givenVestingContractHasNFTs(
            uint256(numberOfMonths) * uint256(amountPerMonth)
        );
        uint256 nftsClaimed = bob.claimTokens();
        assertEq(
            nftsClaimed,
            uint256(numberOfMonths) * uint256(amountPerMonth)
        );
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
        alice.grantVestingTokens(address(bob), numberOfMonths, amountPerMonth);

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
        alice.grantVestingTokens(address(bob), amountPerMonth, numberOfMonths);

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
        alice.grantVestingTokens(address(bob), numberOfMonths, amountPerMonth);

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

    function testCanClaimMultipleTimes(
        uint32 amountPerMonth,
        uint16 numberOfMonths,
        uint16 claimPeriod
    ) public {
        alice.grantVestingTokens(address(bob), numberOfMonths, amountPerMonth);
        givenVestingContractHasNFTs(
            uint256(numberOfMonths) * uint256(amountPerMonth)
        );

        if (
            amountPerMonth == 0 ||
            claimPeriod == 0 ||
            numberOfMonths == 0 ||
            claimPeriod < numberOfMonths
        ) {
            // tested in testCanClaimTokensGivenTimePassed, will return 0
            // if claimPeriod == 0 then the test is tested in testClaimTokensGivenNoTimePassed
            // if claimPeriod > numberOfMonths then the test is invalid.
            return;
        }

        uint256 i = 0;
        for (i = claimPeriod; i < numberOfMonths; i += claimPeriod) {
            givenMonthsFromNow(claimPeriod);
            uint256 nftsClaimed = bob.claimTokens();
            assertEq(nftsClaimed, claimPeriod * amountPerMonth);
            assertEq(
                token.balanceOf(address(bob), tokenId),
                i * amountPerMonth
            );
        }
    }

    function testMonthsRemainingIsUpdatedAfterClaiming(
        uint16 numberOfMonths,
        uint32 amountPerMonth
    ) public {
        alice.grantVestingTokens(address(bob), numberOfMonths, amountPerMonth);
        givenVestingContractHasNFTs(
            uint256(numberOfMonths) * uint256(amountPerMonth)
        );

        if (amountPerMonth == 0 || numberOfMonths <= 1) {
            // tested in testCanClaimTokensGivenTimePassed, will return 0
            // since we need to make two claims, we need at least 2 months.
            return;
        }

        uint256 nftsClaimed = 0;

        // make the first claim after a month
        givenMonthsFromNow(1);
        nftsClaimed = bob.claimTokens();
        assertEq(nftsClaimed, amountPerMonth);
        assertEq(token.balanceOf(address(bob), tokenId), amountPerMonth);

        // after waiting past the last month, we should still not be able to take more tokens.
        givenMonthsFromNow(numberOfMonths);
        nftsClaimed = bob.claimTokens();
        assertEq(
            nftsClaimed,
            uint256(amountPerMonth) * uint256(numberOfMonths - 1)
        );
        assertEq(
            token.balanceOf(address(bob), tokenId),
            uint256(amountPerMonth) * uint256(numberOfMonths)
        );
    }
}

contract WithdrawTokens is VestingTest {
    function testCanWithdrawTokens(uint256 numberOfTokens) public {
        givenVestingContractHasNFTs(numberOfTokens);
        alice.withdrawTokens(numberOfTokens);

        assertEq(token.balanceOf(address(alice), tokenId), numberOfTokens);
    }

    function testCannotWithdrawMoreTokensThanAvailable(uint128 numberOfTokens)
        public
    {
        givenVestingContractHasNFTs(numberOfTokens);
        try alice.withdrawTokens(uint256(numberOfTokens) + 10) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.InsufficientTokenBalance);
        }
    }
}
