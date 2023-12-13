// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StudyCafeStorage.sol";

/**
 * @title StudyCafeLogic
 * @dev Logic contract for the Study Cafe application, managing subscription payments,
 * seat reservations, attendance tracking, and user refunds.
 */
contract StudyCafeLogic is StudyCafeStorage {
    /**
     * @dev Emitted when a payment is received.
     * @param payer The address of the payer.
     * @param amount The amount of ether paid.
     */
    event Payment(address indexed payer, uint256 amount);

    /**
     * @dev Emitted when a user checks in, providing attendance information and rewards.
     * @param attendee The address of the attendee.
     * @param totalAttendanceDays The total consecutive attendance days.
     * @param percentage The payback percentage, determining the reward.
     * @param reward The reward amount in ether.
     */
    event Attendance(address indexed attendee, uint256 totalAttendanceDays, uint256 percentage, uint256 reward);

    /**
     * @dev Emitted when a customer reserves a seat.
     * @param customer The address of the customer reserving the seat.
     * @param seatNumber The reserved seat number.
     */
    event SeatReserved(address indexed customer, uint256 seatNumber);

    /**
     * @dev Modifier to restrict access to the admin only.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    /**
     * @dev Constructor to initialize the StudyCafeLogic contract with initial values.
     * @param _monthlySubscriptionFee The monthly subscription fee for StudyCafeLogic.
     * @param _dailySubscriptionFee The daily subscription fee for StudyCafeLogic.
     * @param _totalSeats The total number of seats available in the study cafe.
     */
    constructor(uint256 _monthlySubscriptionFee, uint256 _dailySubscriptionFee, uint256 _totalSeats) {
        admin = msg.sender;
        monthlySubscriptionFee = _monthlySubscriptionFee;
        dailySubscriptionFee =_dailySubscriptionFee;
        totalSeats = _totalSeats;
    }

    /**
     * @dev Allows a user to pay the monthly subscription fee.
     * @dev Emits a Payment event with the payer's address and the payment amount.
     */
    function payMonthlySubscription() external payable {
        require(msg.value == monthlySubscriptionFee, "Incorrect payment amount");
        userBalances[msg.sender] += monthlySubscriptionFee;
        emit Payment(msg.sender, msg.value);
    }

    /**
     * @dev Sets the total number of seats, restricted to the admin.
     * @param _totalSeats The new total number of seats.
     */
    function setTotalSeats(uint256 _totalSeats) external onlyAdmin {
        totalSeats = _totalSeats;
    }

     /**
     * @dev Allows a user to reserve a seat, emitting a SeatReserved event.
     * @param _seatNumber The seat number to be reserved.
     */
    function reserveSeat(uint256 _seatNumber) external {
            require(_seatNumber > 0 && _seatNumber <= totalSeats, "Invalid seat number");
            require(seatToCustomer[_seatNumber] == address(0), "Please select another seat");

            address customer = msg.sender;

            require(customerToSeat[customer] == 0, "You have already reserved a seat");

            seatToCustomer[_seatNumber] = customer;
            customerToSeat[customer] = _seatNumber;

            emit SeatReserved(customer, _seatNumber);
    }

     /**
     * @dev Allows a user to change their reserved seat, emitting a SeatReserved event.
     * @param _seatNumber The new seat number to be reserved.
     */
    function changeSeat(uint256 _seatNumber) external {
            require(_seatNumber > 0 && _seatNumber <= totalSeats, "Invalid seat number");
            require(seatToCustomer[_seatNumber] == address(0), "Please select another seat");

            address customer = msg.sender;

            seatToCustomer[_seatNumber] = customer;
            customerToSeat[customer] = _seatNumber;

            emit SeatReserved(customer, _seatNumber);
    }
    
    /**
     * @dev Allows a user to check in, updating attendance records and emitting an Attendance event.
     */
    function checkIn() external {
        require(userBalances[msg.sender] >= monthlySubscriptionFee, "Insufficient funds");
        uint256 currentTime = block.timestamp;
        require(currentTime - lastCheckInDate[msg.sender] >= 1 days, "Already check in");

        if (currentTime - lastCheckInDate[msg.sender] >= 1 days && currentTime - lastCheckInDate[msg.sender] < 2 days) {
            continuousAttendanceDays[msg.sender]++;
        } else {
            continuousAttendanceDays[msg.sender] = 1;
        }

        uint256 percentage = calculatePercentage(continuousAttendanceDays[msg.sender]);
        uint256 reward = calculateReward(percentage);
        userBalances[msg.sender] -= dailySubscriptionFee;
        userPaybackBalances[msg.sender] += reward;

        lastCheckInDate[msg.sender] = currentTime;
        emit Attendance(msg.sender, continuousAttendanceDays[msg.sender], percentage, reward);
    }

    /**
     * @dev Refunds the balance of a customer, restricted to the admin.
     * @param customer The address of the customer to refund.
     */
    function refund(address customer) external onlyAdmin {
        require(userBalances[customer] > 0, "Customer has no balance to refund.");
        payable(address(customer)).transfer(userBalances[customer]);

        // 사용자의 잔고를 0으로 초기화
        userBalances[customer] = 0;
    }

    /**
     * @dev Calculates the payback percentage based on consecutive days attended.
     * @param daysAttended The number of days attended consecutively.
     * @return The calculated payback percentage.
     */
    function calculatePercentage(uint256 daysAttended) internal pure returns (uint256) {
        if (daysAttended % 7 == 0) {
            return 200;
        } else {
            return 10;
        }
    }

    /**
     * @dev Calculates the reward based on the payback percentage.
     * @param percentage The payback percentage.
     * @return The calculated reward value.
     */
    function calculateReward(uint256 percentage) internal view returns (uint256) {
        return percentage * monthlySubscriptionFee / 10000;
    }
}