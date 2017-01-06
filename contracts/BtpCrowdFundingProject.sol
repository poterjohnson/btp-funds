pragma solidity ^0.4.2;

import "EthCrowdfunding.sol";

contract BtpCrowdFundingProject {
    EthCrowdfunding[] public crowdfunds;

    function addBtpCrowdFundingProject(uint funding_period, uint funding_goal_usd, address fund_owner, address usd_eth_rate_pusher) returns (bool) {
        EthCrowdfunding crawdfund = new EthCrowdfunding(funding_period, funding_goal_usd, fund_owner, usd_eth_rate_pusher);
        crowdfunds.push(crawdfund);
        return true;
    }

    function getCrowdFund(uint num) returns (address){
        return address(crowdfunds[num]);
    }
}
