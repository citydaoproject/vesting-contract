// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "ds-test/test.sol";

import "../../Vesting.sol";
import "../../DateTime.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "./Hevm.sol";

contract User is ERC1155Receiver {
  Vesting internal vesting;

  constructor(address _vesting) ERC1155Receiver() {
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

  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external override returns (bytes4) {
    return
      bytes4(
        keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")
      );
  }

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external override returns (bytes4) {
    return
      bytes4(
        keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")
      );
  }
}

contract Token is ERC1155 {
  uint256 private _tokenId;

  constructor(uint256 tokenId) ERC1155("") {
    _tokenId = tokenId;
  }

  function mint(
    address to,
    uint256 amount,
    bytes memory data
  ) public {
    _mint(to, _tokenId, amount, data);
  }
}

abstract contract VestingTest is DSTest {
  Hevm internal constant hevm = Hevm(HEVM_ADDRESS);

  // contracts
  Vesting internal vestingContract;
  Token internal token;
  uint256 internal tokenId = 1;

  // users
  User internal alice;
  User internal bob;

  function setUp() public virtual {
    token = new Token(tokenId);
    vestingContract = new Vesting(address(token), tokenId);
    alice = new User(address(vestingContract));
    bob = new User(address(vestingContract));

    vestingContract.transferOwnership(address(alice));
  }

  function givenMonthsFromNow(uint16 _months) public {
    (uint256 year, uint256 month, uint256 day) = DateTime.timestampToDate(
      block.timestamp
    );
    uint256 newTime = DateTime.timestampFromDate(year, month + _months, day);
    hevm.warp(newTime);
  }

  function givenVestingContractHasNFTs(uint256 _amount) public {
    token.mint(address(vestingContract), _amount, "");
  }
}
