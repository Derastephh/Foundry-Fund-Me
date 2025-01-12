// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
error FundMe__NotOwner();

contract FundMe {
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    using PriceConverter for uint256;

    uint public constant MIN_USD = 5e18;
    address[] private s_funders;
    mapping(address funder => uint256 amountFunded) private s_addressToAmount;

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MIN_USD,
            "not enough ETH"
        );
        s_funders.push(msg.sender);
        s_addressToAmount[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmount[funder] = 0;
            s_funders = new address[](0);

            (bool success, ) = payable(msg.sender).call{
                value: address(this).balance
            }("");
            require(success, "Call Failed");
        }
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getAddressToAmountFunded(
        address _funder
    ) public view returns (uint256) {
        return s_addressToAmount[_funder];
    }

    function getFunders(uint256 _index) public view returns (address) {
        return s_funders[_index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
