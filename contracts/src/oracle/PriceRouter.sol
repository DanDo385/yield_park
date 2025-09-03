// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IERC20Metadata} from "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IChainlinkFeed {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract PriceRouter is Ownable {
    constructor() Ownable(msg.sender) {}
    struct Feed {
        address feed;
        uint48 maxStale; // seconds
    }
    mapping(address => Feed) public feeds; // asset -> feed

    function setFeed(address asset, address feed, uint48 maxStale) external onlyOwner {
        feeds[asset] = Feed(feed, maxStale);
    }

    function price1e18(address asset) public view returns (uint256) {
        Feed memory f = feeds[asset];
        require(f.feed != address(0), "no-feed");
        int256 ans = IChainlinkFeed(f.feed).latestAnswer();
        require(ans > 0, "bad");
        uint256 ts = IChainlinkFeed(f.feed).latestTimestamp();
        require(block.timestamp - ts <= f.maxStale, "stale");
        uint8 fd = IChainlinkFeed(f.feed).decimals();
        uint8 ad = IERC20Metadata(asset).decimals();
        // normalize to 1e18 per 1 unit of asset
        uint256 p = uint256(ans);
        if (fd < 18) p *= (10 ** (18 - fd)); else if (fd > 18) p /= (10 ** (fd - 18));
        // price is usually USD per asset in 1e18; adjust for asset decimals to keep consistent valuation
        if (ad < 18) p /= (10 ** (18 - ad)); else if (ad > 18) p *= (10 ** (ad - 18));
        return p;
    }
}
