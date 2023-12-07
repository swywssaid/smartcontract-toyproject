// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StudyCafeStorage.sol";

contract StudyCafeLogic is StudyCafeStorage {
    event Payment(address indexed payer, uint256 amount);
    event Attendance(address indexed attendee, uint256 totalAttendanceDays, uint256 percentage, uint256 reward);

    // 오너 체크
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

     constructor(uint256 _monthlySubscriptionFee) {
        owner = msg.sender;
        monthlySubscriptionFee = _monthlySubscriptionFee;
        continuousAttendanceDays[msg.sender] = 0;
    }

    // 이용료 지불
    function payMonthlySubscription() external {
        // require(msg.value == monthlySubscriptionFee, "Incorrect payment amount");
        userBalances[msg.sender] += monthlySubscriptionFee;
        // emit Payment(msg.sender, msg.value);
    }

    // 출석체크
    function checkIn() external {
        require(userBalances[msg.sender] >= monthlySubscriptionFee, "Insufficient funds");
        uint256 currentTime = block.timestamp;
        require(currentTime - lastCheckInDate[msg.sender] >= 1 days, "Already check in");

        if (currentTime - lastCheckInDate[msg.sender] >= 1 days && currentTime - lastCheckInDate[msg.sender] < 2 days) {
            continuousAttendanceDays[msg.sender]++;
        } else {
            // 출석체크가 중간에 멈춘 경우 연속 출석일 수 초기화
            continuousAttendanceDays[msg.sender] = 1;
        }

        uint256 percentage = calculatePercentage(continuousAttendanceDays[msg.sender]);
        uint256 reward = calculateReward(percentage);
        userPaybackBalances[msg.sender] += reward;

        // 마지막 출석일 갱신
        lastCheckInDate[msg.sender] = currentTime;
        emit Attendance(msg.sender, continuousAttendanceDays[msg.sender], percentage, reward);
    }

    function calculatePercentage(uint256 daysAttended) internal pure returns (uint256) {
        if (daysAttended % 7 == 0) {
            return 200;
        } else {
            return 10;
        }
    }

    function calculateReward(uint256 percentage) internal view returns (uint256) {
        return percentage * monthlySubscriptionFee / 10000;
    }

    function refund() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}