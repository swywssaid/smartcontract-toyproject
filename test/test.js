const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("StudyCafeLogic", () => {
  let studyCafeLogic;
  let owner;
  let customer;

  before(async () => {
    [owner, customer] = await ethers.getSigners();

    // 배포된 컨트랙트 인스턴스 생성
    const StudyCafeLogic = await ethers.getContractFactory("StudyCafeLogic");
    studyCafeLogic = await StudyCafeLogic.deploy(
      ethers.utils.parseEther("1"),
      ethers.utils.parseEther("0.05"),
      10
    );
  });

  it("should pay monthly subscription", async () => {
    // customer가 월 구독료 지불
    await studyCafeLogic
      .connect(customer)
      .payMonthlySubscription({ value: ethers.utils.parseEther("1") });

    // customer의 잔고 확인
    const balance = await studyCafeLogic.userBalances(customer.address);
    expect(balance).to.equal(ethers.utils.parseEther("1"));
  });

  it("should reserve a seat", async () => {
    // customer가 좌석 예약
    await studyCafeLogic.connect(customer).reserveSeat(1);

    // 좌석 및 고객 확인
    const seatNumber = await studyCafeLogic.customerToSeat(customer.address);
    const reservedCustomer = await studyCafeLogic.seatToCustomer(1);

    expect(seatNumber).to.equal(1);
    expect(reservedCustomer).to.equal(customer.address);
  });

  it("should change seat", async () => {
    // customer가 좌석 변경
    await studyCafeLogic.connect(customer).changeSeat(2);

    // 좌석 및 고객 확인
    const seatNumber = await studyCafeLogic.customerToSeat(customer.address);
    const reservedCustomer = await studyCafeLogic.seatToCustomer(2);

    expect(seatNumber).to.equal(2);
    expect(reservedCustomer).to.equal(customer.address);
  });

  it("should check in and calculate rewards", async () => {
    // customer가 출석체크
    await studyCafeLogic.connect(customer).checkIn();

    // 출석체크 결과 확인
    const attendanceDays = await studyCafeLogic.continuousAttendanceDays(
      customer.address
    );
    const rewardBalance = await studyCafeLogic.userPaybackBalances(
      customer.address
    );

    // 출석체크 결과에 따른 값 검증
    expect(attendanceDays).to.equal(1); // 첫 출석이므로 1이어야 합니다.
    expect(rewardBalance).to.equal(ethers.utils.parseEther("0.001")); // 0.1%에 해당하는 페이백이어야 합니다.
  });

  it("should refund balance to the owner", async () => {
    // 한달 이용료 입급 후 잔액
    const afterPaymentBalance = await studyCafeLogic.userBalances(
      customer.address
    );

    expect(afterPaymentBalance).to.equal(ethers.utils.parseEther("0.95")); // 컨트랙트에 있는 잔고 전액이 owner에게 환불되어야 합니다.

    // owner가 환불 실행
    await studyCafeLogic.refund(customer.address);
    const afterRefundBalance = await studyCafeLogic.userBalances(
      customer.address
    );

    // 해당 고객의 잔고가 초기화되었는지 확인
    expect(afterRefundBalance).to.equal(0);
  });
});
