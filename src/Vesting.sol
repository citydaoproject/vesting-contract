// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "./DateTime.sol";

library Errors {
  string internal constant InvalidTimestamp = "invalid timestamp";
  string internal constant InvalidInput = "invalid input provided";
  string internal constant NoVestingSchedule =
    "sender has not been registered for a vesting schedule";
  string internal constant InsufficientTokenBalance =
    "contract does not have enough tokens to distribute";
}

struct VestingSchedule {
  uint256 lastClaim;
  uint16 monthsRemaining;
  uint32 tokensPerMonth;
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
  ) external pure override returns (bytes4) {
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
  ) external pure override returns (bytes4) {
    return
      bytes4(
        keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")
      );
  }

  function claimTokens() external returns (uint256 tokensToClaim) {
    VestingSchedule storage userVestingSchedule = _vestingSchedules[msg.sender];

    uint256 monthsPassed = DateTime.diffMonths(
      _vestingSchedules[msg.sender].lastClaim,
      block.timestamp
    );

    if (monthsPassed == 0) {
      return 0;
    } else if (monthsPassed > userVestingSchedule.monthsRemaining) {
      tokensToClaim =
        uint256(userVestingSchedule.tokensPerMonth) *
        uint256(userVestingSchedule.monthsRemaining);
    } else {
      tokensToClaim =
        uint256(userVestingSchedule.tokensPerMonth) *
        monthsPassed;
    }

    IERC1155 token = IERC1155(_tokenAddress);
    require(
      token.balanceOf(address(this), _tokenId) >= tokensToClaim,
      Errors.InsufficientTokenBalance
    );

    _vestingSchedules[msg.sender].lastClaim = block.timestamp;

    token.safeTransferFrom(
      address(this),
      msg.sender,
      _tokenId,
      tokensToClaim,
      "Claiming vested NFTs"
    );
  }

  function withdrawTokens(uint256 count) external onlyOwner {
    IERC1155 token = IERC1155(_tokenAddress);
    require(
      token.balanceOf(address(this), _tokenId) >= count,
      Errors.InsufficientTokenBalance
    );

    token.safeTransferFrom(
      address(this),
      msg.sender,
      _tokenId,
      count,
      "Withdrawing tokens"
    );
  }

  function revokeVesting(address toRevoke) external onlyOwner {
    _vestingSchedules[toRevoke].tokensPerMonth = 0;
    _vestingSchedules[toRevoke].monthsRemaining = 0;
  }

  function getVestingSchedule(address addr)
    external
    view
    returns (
      uint256 timestamp,
      uint16 monthsRemaining,
      uint32 tokensPerMonth
    )
  {
    VestingSchedule storage _vestingSchedule = _vestingSchedules[addr];
    return (
      _vestingSchedule.lastClaim,
      _vestingSchedule.monthsRemaining,
      _vestingSchedule.tokensPerMonth
    );
  }

  function grantVesting(
    address _toGrant,
    uint16 _numberOfMonths,
    uint32 _amountPerMonth
  ) external onlyOwner {
    require(_toGrant != address(0), Errors.InvalidInput);
    _vestingSchedules[_toGrant] = VestingSchedule(
      block.timestamp,
      _numberOfMonths,
      _amountPerMonth
    );
  }
}
