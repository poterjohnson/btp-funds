pragma solidity ^0.4.2;


contract BtpCrowdfunding {

    /*
    statement configration
    */
    uint public FUNDING_GOAL_USD = 1000000; // funding goal of usd rate
    uint public CROWDFUNDING_PERIOD = 1 days; //default 
    uint public ETH_LOCKING_PERIOD = 2 hours; //
    uint public startDate;
    uint public fundBalance;
    address public OWNER;
    address public USD_ETH_RATE_PUSHER;
    uint public USD_ETH_RATE;
   
    struct Invester {
        bytes32 name; // weight is accumulated by delegation
        uint eth_balance;
    }
    // participant address => value in Wei
    mapping (address => Invester) public investers;

    // Initialize stage
    Stages public stage = Stages.CrowdfundingGoingAndGoalNotReached;

   
    enum Stages {
        CrowdfundingGoingAndGoalNotReached,
        CrowdfundingEndedAndGoalNotReached,
        CrowdfundingGoingAndGoalReached,
        CrowdfundingEndedAndGoalReached
    }


    function BtpCrowdfunding(uint funding_period, uint funding_goal_usd, address fund_owner, address usd_eth_rate_pusher) {
        CROWDFUNDING_PERIOD = funding_period;
        FUNDING_GOAL_USD = funding_goal_usd;
        OWNER = fund_owner;
        USD_ETH_RATE_PUSHER = usd_eth_rate_pusher;
        startDate = now;
    }
    /// @dev Allows user to create tokens if token creation is still going and cap not reached. Returns token count.
    function fund(bytes32 name)
        external
        timedTransitions
        atStageOR(Stages.CrowdfundingGoingAndGoalNotReached, Stages.CrowdfundingGoingAndGoalReached)
        minInvestment
        returns (uint)
    {

        // Update fund's and user's balance and total supply of tokens.
        fundBalance += msg.value;
        investers[msg.sender].eth_balance += msg.value;
        investers[msg.sender].name = name;

      
        if (stage == Stages.CrowdfundingGoingAndGoalNotReached) {
            if (fundBalance * USD_ETH_RATE > FUNDING_GOAL_USD) {
                stage = Stages.CrowdfundingGoingAndGoalReached;
            }
        }

       
        // not an else clause for the edge case that the CAP and TOKEN_TARGET are reached in one call
        }
      
        return stage;
    }

    /// @dev Allows user to withdraw ETH if token creation period ended and target was not reached. Returns success.
 

    modifier onlyOwner() {
        // Only owner is allowed to do this action.
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

    modifier onlyUsdEthRatePusher() {
        // Only owner is allowed to do this action.
        if (msg.sender != USD_ETH_RATE_PUSHER) {
            throw;
        }
        _;
    }

    modifier minInvestment() {
        // User has to send at least the ether value of one token.
        if (msg.value < 1 ) {
            throw;
        }
        _;

    }

    modifier atStage(Stages _stage) {
        if (stage != _stage) {
            throw;
        }
        _;
    }

    modifier atStageOR(Stages _stage1, Stages _stage2) {
        if (stage != _stage1 && stage != _stage2) {
            throw;
        }
        _;
    }

    modifier timedTransitions() {
        uint crowdfundDuration = now - startDate;
        if (crowdfundDuration >= CROWDFUNDING_PERIOD) {
            if (stage == Stages.CrowdfundingGoingAndGoalNotReached) {
                stage = Stages.CrowdfundingEndedAndGoalNotReached;
            }
            else if (stage == Stages.CrowdfundingGoingAndGoalReached) {
                stage = Stages.CrowdfundingEndedAndGoalReached;
            }
        }
        _;
    }

    /// @dev Fallback function always fails. Use fund function to create tokens.
    function () {
        throw;
    }
}