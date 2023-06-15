// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./AIO.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/PoolContractInterface.sol";

contract AllInOneStaking is Ownable {
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 reward;
        uint256 year;
        bool claimed;
    }

    AIO public token;
    mapping(address => Stake[]) public stakes;

    event Staked(address indexed user, uint256 amount, uint256 time, uint256 reward);

    AllInOnePoolStorageInterface poolStorage;

    constructor(AIO _token, address _poolStorageAddress) {
        token = _token;
        poolStorage = AllInOnePoolStorageInterface(_poolStorageAddress);
    }

    function stake(uint256 _amount, uint256 _time) external {
        require(_amount > 0, "Staking amount should be more than 0");
        require(_amount >= 10_000 ether, "Staking amount atleast should be 10_000 or more.");

        require(_time == 2 || _time == 3 || _time == 4, "Invalid staking time");
        require(token.allowanceForPresaled(msg.sender, _amount), "You cant stake with presaled token");
        
        uint256 _reward;
        if(_time == 2) {
            _reward = _amount * 20 / 100;
        } else if(_time == 3) {
            _reward = _amount * 45 / 100;
        } else if(_time == 4) {
            _reward = _amount * 100 / 100;
        }

        token.transferFrom(msg.sender, address(this), _amount);

        Stake memory newStake = Stake({
            amount: _amount,
            startTime: block.timestamp,
            endTime: block.timestamp + (_time * 365 days),
            reward: _reward,
            year: _time,
            claimed: false
        });

        stakes[msg.sender].push(newStake);

        emit Staked(msg.sender, _amount, _time, _reward);
    }

    function claim(uint256 _stakeIndex) external {
        Stake storage userStake = stakes[msg.sender][_stakeIndex];
        require(userStake.endTime <= block.timestamp, "Staking period is not over yet");
        require(userStake.claimed == false, "Rewards already claimed");

        token.transfer(msg.sender, userStake.amount); // Send actual staked amount
        poolStorage.withdraw(msg.sender, userStake.reward); // Send reward
        userStake.claimed = true;
    }

    function getAllStakes(address _user) external view returns (Stake[] memory) {
        return stakes[_user];
    }
}
