const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("StudyCafeLogic", () => {
  let StudyCafeStorage;
  let StudyCafeLogic;
  let owner;
  let customer;

  before(async () => {
    [owner, customer] = await ethers.getSigners();

    // Deploy StudyCafeStorage
    const _StudyCafeStorage = await ethers.getContractFactory(
      "StudyCafeStorage"
    );
    StudyCafeStorage = await _StudyCafeStorage.deploy();
    await StudyCafeStorage.deployed();

    // Deploy StudyCafeLogic
    const _StudyCafeLogic = await ethers.getContractFactory("StudyCafeLogic");
    StudyCafeLogic = await _StudyCafeLogic.deploy(
      ethers.utils.parseEther("1"),
      ethers.utils.parseEther("0.05"),
      10
    );
    await StudyCafeLogic.deployed();
  });

  it("should pay monthly subscription", async () => {
    // Customer pays the monthly subscription
    await StudyCafeLogic.connect(customer).payMonthlySubscription({
      value: ethers.utils.parseEther("1"),
    });

    // Check customer's balance
    const balance = await StudyCafeLogic.userBalances(customer.address);
    expect(balance).to.equal(ethers.utils.parseEther("1"));
  });

  it("should reserve a seat", async () => {
    // Customer reserves a seat
    await StudyCafeLogic.connect(customer).reserveSeat(1);

    // Check seat and customer
    const seatNumber = await StudyCafeLogic.customerToSeat(customer.address);
    const reservedCustomer = await StudyCafeLogic.seatToCustomer(1);

    expect(seatNumber).to.equal(1);
    expect(reservedCustomer).to.equal(customer.address);
  });

  it("should change seat", async () => {
    // Customer changes seat
    await StudyCafeLogic.connect(customer).changeSeat(2);

    // Check seat and customer
    const seatNumber = await StudyCafeLogic.customerToSeat(customer.address);
    const reservedCustomer = await StudyCafeLogic.seatToCustomer(2);

    expect(seatNumber).to.equal(2);
    expect(reservedCustomer).to.equal(customer.address);
  });

  it("should check in and calculate rewards", async () => {
    // Customer checks in
    await StudyCafeLogic.connect(customer).checkInWithGPS(true);

    // Check attendance and reward balance
    const attendanceDays = await StudyCafeLogic.continuousAttendanceDays(
      customer.address
    );
    const rewardBalance = await StudyCafeLogic.userPaybackBalances(
      customer.address
    );

    // Verify attendance and reward balance
    expect(attendanceDays).to.equal(1); // First attendance, so it should be 1.
    expect(rewardBalance).to.equal(ethers.utils.parseEther("0.001")); // Should be 0.1% payback.
  });

  it("should refund balance to the owner", async () => {
    // Check customer's balance after monthly subscription payment
    const afterPaymentBalance = await StudyCafeLogic.userBalances(
      customer.address
    );

    // Verify the balance after monthly subscription payment
    expect(afterPaymentBalance).to.equal(ethers.utils.parseEther("0.95")); // The entire balance in the contract should be refunded to the owner.

    // Owner initiates the refund
    await StudyCafeLogic.refund(customer.address);

    // Check customer's balance after the refund
    const afterRefundBalance = await StudyCafeLogic.userBalances(
      customer.address
    );

    // Verify that the customer's balance is reset to 0 after the refund
    expect(afterRefundBalance).to.equal(0);
  });
});
