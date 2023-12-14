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
     * @dev Emitted when a customer is refunded.
     * @param customer The address of the customer being refunded.
     * @param amount The refunded amount.
     */
    event Refund(address indexed customer, uint256 amount);

    /**
     * @dev Emitted when the total number of seats is updated by the admin.
     * @param admin The address of the admin who updated the total number of seats.
     * @param newTotalSeats The new total number of seats.
     */
    event TotalSeatsUpdated(address indexed admin, uint256 newTotalSeats);

    /**
     * @dev Emitted when a customer checks in, indicating the check-in state.
     * @param customer The address of the customer who checked in.
     * @param checkInState The state of the check-in, true if checked in, false otherwise.
     */
    event CheckIn(address indexed customer, bool checkInState); 

    /**
     * @dev Emitted when admin rights are transferred to a new address.
     * @param previousAdmin The address of the previous admin.
     * @param newAdmin The address of the new admin.
     */
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

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
     * @dev Allows a user to use their payback balances to offset subscription fees.
     */
    function usePaybackBalances() external {
        require(userPaybackBalances[msg.sender] > 0, "No payback balances available");

        uint256 paybackAmount = userPaybackBalances[msg.sender];
        uint256 remainingSubscriptionFee;

        // If payback balances are greater than or equal to the monthly subscription fee
        if (paybackAmount >= monthlySubscriptionFee) {
            remainingSubscriptionFee = 0;
            userPaybackBalances[msg.sender] -= monthlySubscriptionFee;
        } else {
            remainingSubscriptionFee = monthlySubscriptionFee - paybackAmount;
            userPaybackBalances[msg.sender] = 0;
        }

        // Update user balances and emit Payment event
        if (remainingSubscriptionFee > 0) {
            require(userBalances[msg.sender] >= remainingSubscriptionFee, "Insufficient funds");
            userBalances[msg.sender] -= remainingSubscriptionFee;
            emit Payment(msg.sender, remainingSubscriptionFee);
        }

        emit Refund(msg.sender, paybackAmount);
    }    

    /**
     * @dev Sets the total number of seats, restricted to the admin.
     * @param _totalSeats The new total number of seats.
     */
    function setTotalSeats(uint256 _totalSeats) external onlyAdmin {
        totalSeats = _totalSeats;
        emit TotalSeatsUpdated(admin, _totalSeats);
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
            uint256 oldSeat = customerToSeat[customer];

            seatToCustomer[_seatNumber] = customer;
            customerToSeat[customer] = _seatNumber;
            seatToCustomer[oldSeat] = address(0);

            emit SeatReserved(customer, _seatNumber);
    }
    
    /**
     * @dev Allows a user to check in based on GPS check, updating attendance records and emitting an Attendance event.
     * @param gpsCheckResult The result of the GPS check, true if the user is at the study cafe, false otherwise.
     */
    function checkInWithGPS(bool gpsCheckResult) external {
        require(!checkInState[msg.sender], "Already checked in");
        require(userBalances[msg.sender] >= dailySubscriptionFee, "Insufficient funds");

        // Add GPS check condition
        require(gpsCheckResult, "GPS check failed. Please check in at the study cafe.");

        // Convert current UTC time to Korea Standard Time (KST)
        uint256 currentTimeKST = block.timestamp + 9 hours; // UTC to KST

        // Calculate the last midnight in KST
        uint256 lastMidnightKST = (currentTimeKST / 1 days) * 1 days;       

        if (lastMidnightKST - lastCheckInMidnightDate[msg.sender] == 1 days) {
            continuousAttendanceDays[msg.sender]++;
            uint256 percentage = calculatePercentage(continuousAttendanceDays[msg.sender]);
            uint256 reward = calculateReward(percentage);
            userBalances[msg.sender] -= dailySubscriptionFee;
            userPaybackBalances[msg.sender] += reward;

            lastCheckInMidnightDate[msg.sender] = lastMidnightKST;
            emit Attendance(msg.sender, continuousAttendanceDays[msg.sender], percentage, reward);
        } else if (lastMidnightKST - lastCheckInMidnightDate[msg.sender] > 1 days) {
            continuousAttendanceDays[msg.sender] = 1;
            uint256 percentage = calculatePercentage(continuousAttendanceDays[msg.sender]);
            uint256 reward = calculateReward(percentage);
            userBalances[msg.sender] -= dailySubscriptionFee;
            userPaybackBalances[msg.sender] += reward;

            lastCheckInMidnightDate[msg.sender] = lastMidnightKST;
            emit Attendance(msg.sender, continuousAttendanceDays[msg.sender], percentage, reward);
        }

        lastCheckInDate[msg.sender] = currentTimeKST;
        lastCheckInMidnightDate[msg.sender] = lastMidnightKST;
        checkInState[msg.sender] = true;
        emit CheckIn(msg.sender, true);
    }

    /**
     * @dev Allows a user to check out, updating attendance records and emitting an Attendance event.
     */
    function checkOut() external {
        require(checkInState[msg.sender] = true, "Already check out");
        require(userBalances[msg.sender] >= dailySubscriptionFee, "Insufficient funds");
        // Convert current UTC time to Korea Standard Time (KST)
        uint256 currentTimeKST = block.timestamp + 9 hours; // UTC to KST

        // Calculate the last midnight in KST
        uint256 lastMidnightKST = (currentTimeKST / 1 days) * 1 days;       

        if (lastMidnightKST - lastCheckInMidnightDate[msg.sender] == 1 days) {
            continuousAttendanceDays[msg.sender]++;
            uint256 percentage = calculatePercentage(continuousAttendanceDays[msg.sender]);
            uint256 reward = calculateReward(percentage);
            userBalances[msg.sender] -= dailySubscriptionFee;
            userPaybackBalances[msg.sender] += reward;

            lastCheckInMidnightDate[msg.sender] = lastMidnightKST;
            emit Attendance(msg.sender, continuousAttendanceDays[msg.sender], percentage, reward);
        }

        lastCheckInDate[msg.sender] = currentTimeKST;
        lastCheckInMidnightDate[msg.sender] = lastMidnightKST;
        checkInState[msg.sender] = false;
        emit CheckIn(msg.sender, false);
    }

    /**
     * @dev Refunds the balance of a customer, restricted to the admin.
     * @param customer The address of the customer to refund.
     */
    function refund(address customer) external onlyAdmin {
        require(userBalances[customer] > 0, "Customer has no balance to refund.");

        uint256 refundAmount = userBalances[customer];
        require(address(this).balance >= refundAmount, "Insufficient contract balance for refund.");

        payable(customer).transfer(refundAmount);

        emit Refund(customer, refundAmount);
        userBalances[customer] = 0;
    }

    /**
     * @dev Allows the current admin to transfer admin rights to a new address.
     * @param newAdmin The address of the new admin.
     */
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid admin address");
        admin = newAdmin;
        emit AdminTransferred(msg.sender, newAdmin);
    }

    /**
     * @dev Allows the admin to withdraw ether from the contract.
     * @param amount The amount of ether to withdraw.
     */
    function withdrawEther(uint256 amount) external onlyAdmin {
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(admin).transfer(amount);
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