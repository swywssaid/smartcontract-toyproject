// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StudyCafeStorage {
    address public owner;
    uint256 public monthlySubscriptionFee;
    uint256 public totalSeats;
    uint256 public dailySubscriptionFee;
    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public userPaybackBalances;
    mapping(address => uint256) public continuousAttendanceDays;
    mapping(address => uint256) public lastCheckInDate;
    mapping(address => uint256) public fixedSeats;
    mapping(uint256 => address) public seatToCustomer;
    mapping(address => uint256) public customerToSeat;
}
