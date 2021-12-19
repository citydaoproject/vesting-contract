// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "./DateTime.sol";

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

contract Vesting is Ownable, ERC1155Receiver {
  address private _tokenAddress;
  uint256 private _tokenId;

  mapping(address => VestingSchedule) private _vestingSchedules;

  constructor(address tokenAddress, uint256 tokenId) ERC1155Receiver() {
    _tokenAddress = tokenAddress;
    _tokenId = tokenId;
  }

  function getToken() public view returns (address, uint256) {
    return (_tokenAddress, _tokenId);
  }

  function setToken(address nftAddress, uint256 id) external onlyOwner {
    _tokenAddress = nftAddress;
    _tokenId = id;
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

  function claimNFTs() external returns (uint256 nftsToClaim) {
    VestingSchedule storage userVestingSchedule = _vestingSchedules[msg.sender];
    nftsToClaim =
      userVestingSchedule.nftsPerMonth *
      userVestingSchedule.monthsRemaining;

    IERC1155 token = IERC1155(_tokenAddress);
    token.safeTransferFrom(
      address(this),
      msg.sender,
      _tokenId,
      nftsToClaim,
      "Claiming vested NFTs"
    );
  }

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
    VestingSchedule storage _vestingSchedule = _vestingSchedules[addr];
    return (
      _vestingSchedule.lastClaim,
      _vestingSchedule.monthsRemaining,
      _vestingSchedule.nftsPerMonth
    );
  }

  function grantVesting(
    address _toGrant,
    uint256 _amountPerMonth,
    uint256 _numberOfMonths
  ) external onlyOwner {
    require(
      _toGrant != address(0) && _amountPerMonth > 0 && _numberOfMonths > 0,
      Errors.InvalidInput
    );
    _vestingSchedules[_toGrant] = VestingSchedule(
      block.timestamp,
      _numberOfMonths,
      _amountPerMonth
    );
  }
}
