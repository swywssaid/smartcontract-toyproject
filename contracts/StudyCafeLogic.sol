// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StudyCafeStorage.sol";

contract StudyCafeLogic is StudyCafeStorage {
    event Payment(address indexed payer, uint256 amount);
    event Attendance(address indexed attendee, uint256 totalAttendanceDays, uint256 percentage, uint256 reward);
    event SeatReserved(address indexed customer, uint256 seatNumber);

    // 오너 체크 모디파이어
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

     constructor(uint256 _monthlySubscriptionFee, uint256 _dailySubscriptionFee, uint256 _totalSeats) {
        owner = msg.sender;
        monthlySubscriptionFee = _monthlySubscriptionFee;
        dailySubscriptionFee =_dailySubscriptionFee;
        totalSeats = _totalSeats;
    }

    // 월 이용료 지불 함수
    function payMonthlySubscription() external payable {
        require(msg.value == monthlySubscriptionFee, "Incorrect payment amount");
        userBalances[msg.sender] += monthlySubscriptionFee;
        emit Payment(msg.sender, msg.value);
    }

    // 총 좌석수 설정 함수
    function setTotalSeats(uint256 _totalSeats) external onlyOwner {
        totalSeats = _totalSeats;
    }

    // 좌석 예약 함수
    function reserveSeat(uint256 _seatNumber) external {
            require(_seatNumber > 0 && _seatNumber <= totalSeats, "Invalid seat number");
            require(seatToCustomer[_seatNumber] == address(0), "Please select another seat");

            address customer = msg.sender;

            require(customerToSeat[customer] == 0, "You have already reserved a seat");

            seatToCustomer[_seatNumber] = customer;
            customerToSeat[customer] = _seatNumber;

            emit SeatReserved(customer, _seatNumber);
    }

    // 좌석 변경 함수
    function changeSeat(uint256 _seatNumber) external {
            require(_seatNumber > 0 && _seatNumber <= totalSeats, "Invalid seat number");
            require(seatToCustomer[_seatNumber] == address(0), "Please select another seat");

            address customer = msg.sender;

            seatToCustomer[_seatNumber] = customer;
            customerToSeat[customer] = _seatNumber;

            emit SeatReserved(customer, _seatNumber);
    }
    
    // 출석체크 함수
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
        userBalances[msg.sender] -= dailySubscriptionFee;
        userPaybackBalances[msg.sender] += reward;

        // 마지막 출석일 갱신
        lastCheckInDate[msg.sender] = currentTime;
        emit Attendance(msg.sender, continuousAttendanceDays[msg.sender], percentage, reward);
    }

    // 페이백 비율 계산 함수
    function calculatePercentage(uint256 daysAttended) internal pure returns (uint256) {
        if (daysAttended % 7 == 0) {
            return 200;
        } else {
            return 10;
        }
    }

    // 페이백 값 계산 함수
    function calculateReward(uint256 percentage) internal view returns (uint256) {
        return percentage * monthlySubscriptionFee / 10000;
    }

    // 환불 함수
    function refund(address customer) external onlyOwner {
        require(userBalances[customer] > 0, "Customer has no balance to refund.");
        payable(address(customer)).transfer(userBalances[customer]);

        // 사용자의 잔고를 0으로 초기화
        userBalances[customer] = 0;
    }
}