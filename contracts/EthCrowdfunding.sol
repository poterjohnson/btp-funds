pragma solidity ^0.4.2;


contract EthCrowdfunding {

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


    function EthCrowdfunding(uint funding_period, uint funding_goal_usd, address fund_owner, address usd_eth_rate_pusher) 
        noEther 
    {
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
        payable
        atStageOR(Stages.CrowdfundingGoingAndGoalNotReached, Stages.CrowdfundingGoingAndGoalReached)
        minInvestment
        returns (bool)
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
        return true;
    }

    /// @dev Allows user to withdraw ETH if token creation period ended and target was not reached. Returns success.
    function withdrawFunding()
        external
        noEther
        timedTransitions
        atStage(Stages.CrowdfundingEndedAndGoalNotReached)
        returns (bool)
    {
        // Update fund's and user's balance and total supply of tokens.
        uint value = investers[msg.sender].eth_balance;
        // Send ETH back to user.
        if (value > 0  && !msg.sender.send(value)) {
            throw;
        }
        investers[msg.sender].eth_balance = 0;
        fundBalance -= value;
        return true;
    }

    ///  Withdraws ETH to owner address. Returns success.
    function withdrawForOwner()
        external
        noEther
        timedTransitions
        onlyOwner
        atStage(Stages.CrowdfundingEndedAndGoalReached)
        returns (bool)
    {
        uint value = fundBalance;
        fundBalance = 0;
        if (value > 0  && !msg.sender.send(value)) {
            throw;
        }
        return true;
    }

    function changeEthUSDRate(uint rate)
        external
        noEther
        onlyUsdEthRatePusher
        returns (bool)
    {
        USD_ETH_RATE = rate;
        return true;
    }


    /// @dev Returns if token creation ended successfully.
    function campaignEndedSuccessfully()
        constant
        external
        noEther
        returns (bool)
    {
        if (stage == Stages.CrowdfundingEndedAndGoalReached) {
            return true;
        }
        return false;
    }

    // updateStage allows calls to receive correct stage. It can be used for transactions but is not part of the regular token creation routine.
    // It is not marked as constant because timedTransitions modifier is altering state and constant is not yet enforced by solc.
    /// @dev returns correct stage, even if a function with timedTransitions modifier has not yet been called successfully.
    function updateStage()
        external
        timedTransitions
        noEther
        returns (Stages)
    {
        return stage;
    }
    /*
     *  Modifiers
     */
    modifier noEther() {
        if (msg.value > 0) {
            throw;
        }
        _;
    }

    modifier onlyOwner() {
        // Only owner is allowed to do this action.
        if (msg.sender != OWNER) {
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