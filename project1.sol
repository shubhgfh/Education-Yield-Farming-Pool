// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IERC20 interface to interact with ERC20 tokens
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract EducationYieldFarming {
    // Tokens for staking and rewards
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    
    // Education fund address
    address public educationFund;

    // Reward rate per second
    uint256 public rewardRate;
    
    // Total staked tokens
    uint256 public totalStaked;

    // Mapping for staking information
    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public lastUpdated;

    // Events
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 rewardAmount, uint256 educationContribution);

    // Constructor to initialize the contract with tokens and education fund address
    constructor(IERC20 _stakingToken, IERC20 _rewardToken, address _educationFund, uint256 _rewardRate) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        educationFund = _educationFund;
        rewardRate = _rewardRate;
    }

    // Modifier to update rewards
    modifier updateReward(address account) {
        if (stakedAmount[account] > 0) {
            uint256 reward = calculateReward(account);
            uint256 educationContribution = reward / 10; // 10% goes to education fund
            rewardToken.transfer(account, reward - educationContribution);
            rewardToken.transfer(educationFund, educationContribution);
            emit RewardsClaimed(account, reward - educationContribution, educationContribution);
        }
        _;
        lastUpdated[account] = block.timestamp;
    }

    // Stake tokens to the pool
    function stake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0 tokens");
        stakingToken.transferFrom(msg.sender, address(this), amount);
        stakedAmount[msg.sender] += amount;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    // Withdraw staked tokens from the pool
    function withdraw(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0 tokens");
        require(stakedAmount[msg.sender] >= amount, "Insufficient staked balance");
        stakingToken.transfer(msg.sender, amount);
        stakedAmount[msg.sender] -= amount;
        totalStaked -= amount;
        emit Withdrawn(msg.sender, amount);
    }

    // Calculate rewards for a user
    function calculateReward(address account) public view returns (uint256) {
        uint256 staked = stakedAmount[account];
        uint256 timeDiff = block.timestamp - lastUpdated[account];
        return staked * rewardRate * timeDiff / 1e18;  // Adjust reward calculation for better precision
    }

    // Update the reward rate
    function setRewardRate(uint256 newRate) external {
        rewardRate = newRate;
    }

    // Update the education fund address
    function setEducationFund(address newFund) external {
        educationFund = newFund;
    }

    // View function to get staked balance of a user
    function getStakedBalance(address account) external view returns (uint256) {
        return stakedAmount[account];
    }

    // View function to get total staked balance
    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
}
}