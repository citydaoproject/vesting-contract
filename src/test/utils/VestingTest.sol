// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "ds-test/test.sol";

import "../../Vesting.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./Hevm.sol";

contract User {
  Vesting internal vesting;

  constructor(address _vesting, address _token) {
    vesting = Vesting(_vesting);
  }

  function grantVesting(
    address toGrant,
    uint256 amountPerMonth,
    uint256 numberOfMonths
  ) public {
    vesting.grantVesting(toGrant, amountPerMonth, numberOfMonths);
  }

  function claimNFTs() public {
    vesting.claimNFTs();
  }
}

abstract contract VestingTest is DSTest {
  Hevm internal constant hevm = Hevm(HEVM_ADDRESS);

  // contracts
  Vesting internal vestingContract;
  ERC1155 internal token;

  // users
  User internal alice;
  User internal bob;

  function setUp() public virtual {
    vestingContract = new Vesting();
    token = new ERC1155("");
    alice = new User(address(vestingContract), address(token));
    bob = new User(address(vestingContract), address(token));

    vestingContract.setToken(address(token), 1);
    vestingContract.transferOwnership(address(alice));
  }
}
