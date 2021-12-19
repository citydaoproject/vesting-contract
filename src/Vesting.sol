// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

library Errors {
  string internal constant InvalidBlockNumber =
    "invalid block number, please wait";
  string internal constant InvalidInput = "invalid input provided";
}

struct VestingSchedule {
  uint256 lastClaim;
  uint256 monthsRemaining;
  uint256 nftsPerMonth;
}

contract Vesting is Ownable {
  uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
  int256 constant OFFSET19700101 = 2440588;

  address private _tokenAddress =
    address(0x0000000000000000000000000000000000000000);
  uint256 private _tokenId = 0;

  mapping(address => VestingSchedule) private _vestingSchedules;

  function getToken() public view returns (address, uint256) {
    return (_tokenAddress, _tokenId);
  }

  function setToken(address nftAddress, uint256 id) external onlyOwner {
    _tokenAddress = nftAddress;
    _tokenId = id;
  }

  function _daysToDate(uint256 _days)
    private
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    int256 __days = int256(_days);

    int256 L = __days + 68569 + OFFSET19700101;
    int256 N = (4 * L) / 146097;
    L = L - (146097 * N + 3) / 4;
    int256 _year = (4000 * (L + 1)) / 1461001;
    L = L - (1461 * _year) / 4 + 31;
    int256 _month = (80 * L) / 2447;
    int256 _day = L - (2447 * _month) / 80;
    L = _month / 11;
    _month = _month + 2 - 12 * L;
    _year = 100 * (N - 49) + _year + L;

    year = uint256(_year);
    month = uint256(_month);
    day = uint256(_day);
  }

  function timestampToDate(uint256 timestamp)
    private
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function claimNFTs() external returns (uint256 nftsToClaim) {}

  // function setLastClaim(address addr) private {
  //   (uint256 year, uint256 month, uint256 day) = timestampToDate(
  //     block.timestamp
  //   );
  //   _lastClaim[addr] = (year * 12) + month;
  // }

  // function claimNFTs() external returns (uint256 nftsToClaim) {
  //   require(_nftsPerMonth[msg.sender] > 0, "No NFTs to claim");
  //   require(_monthsRemaining[msg.sender] > 0, "No NFTs to claim");

  //   (uint256 year, uint256 month, uint256 day) = timestampToDate(
  //     block.timestamp
  //   );

  //   int256 monthDiff = int256((year * 12) + month) -
  //     int256(_lastClaim[msg.sender]);
  //   require(monthDiff > 0, "NFTs already claimed for this month");

  //   setLastClaim(msg.sender);

  //   uint256 monthsRemaining = 0;
  //   if (monthDiff < int256(_monthsRemaining[msg.sender])) {
  //     monthsRemaining = uint256(monthDiff);
  //   } else if (monthDiff >= int256(_monthsRemaining[msg.sender])) {
  //     monthsRemaining = _monthsRemaining[msg.sender];
  //   }
  //   _monthsRemaining[msg.sender] -= monthsRemaining;

  //   IERC1155 citizenNft = IERC1155(_citizenNftAddress);

  //   nftsToClaim = _nftsPerMonth[msg.sender] * monthsRemaining;
  //   require(
  //     citizenNft.balanceOf(address(this), _citizenNftId) >= nftsToClaim,
  //     "Not enough NFTs to claim"
  //   );
  //   citizenNft.safeTransferFrom(
  //     address(this),
  //     msg.sender,
  //     _citizenNftId,
  //     nftsToClaim,
  //     ""
  //   );
  // }

  // function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns (bytes4)

  // function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override returns(bytes4)

  // function withdrawNFTs(uint256 count)

  // function revokeVesting(address toRevoke)

  function getVestingSchedule(address addr)
    external
    view
    returns (
      uint256 timestamp,
      uint256 monthsRemaining,
      uint256 nftsPerMonth
    )
  {
    VestingSchedule memory _vestingSchedule = _vestingSchedules[addr];
    return (
      _vestingSchedule.lastClaim,
      _vestingSchedule.monthsRemaining,
      _vestingSchedule.nftsPerMonth
    );
  }

  function grantVesting(
    address toGrant,
    uint256 amountPerMonth,
    uint256 numberOfMonths
  ) external onlyOwner {
    require(
      toGrant != address(0) && amountPerMonth > 0 && numberOfMonths > 0,
      Errors.InvalidInput
    );
    _vestingSchedules[toGrant] = VestingSchedule(
      block.timestamp,
      numberOfMonths,
      amountPerMonth
    );
  }
}
