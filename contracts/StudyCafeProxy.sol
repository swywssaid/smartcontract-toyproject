// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StudyCafeStorage.sol";

contract StudyCafeProxy is StudyCafeStorage {
    address public logicContract;

    // 오너 체크
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // 프록시 계약 생성자
    constructor(address _logicContract) {
        logicContract = _logicContract;
    }

    // fallback 함수: 로직 계약의 함수를 호출하는 데 사용
    fallback() external payable {
        // 로직 계약 주소 설정
        address target = logicContract;

        // 델리게이트 콜을 사용하여 로직 계약의 함수 호출

        // 먼저 새로운 메모리 영역을 할당하고 포인터를 가져옵니다.
        assembly {
            let ptr := mload(0x40)

            // calldatacopy를 사용하여 호출된 데이터를 메모리로 복사합니다.
            calldatacopy(ptr, 0, calldatasize())

            // delegatecall을 호출하고, 호출된 함수에게 복사한 데이터를 전달합니다.
            // gas() 함수를 사용하여 현재 가스 양을 가져옵니다.
            // delegatecall의 결과는 성공(1) 또는 실패(0)입니다.
            let result := delegatecall(gas(), target, ptr, calldatasize(), 0, 0)

            // returndatasize() 함수를 사용하여 반환 데이터의 크기를 가져옵니다.
            let size := returndatasize()

            // returndatacopy를 사용하여 반환된 데이터를 메모리로 복사합니다.
            returndatacopy(ptr, 0, size)

            // 델리게이트 콜의 결과에 따라 처리
            // result가 0인 경우 revert를 호출하고 실패한 이유를 반환합니다.
            switch result
            case 0 { revert(ptr, size) }

            // 성공한 경우, 호출된 함수의 반환 데이터를 호출자에게 반환합니다.
            default { return(ptr, size) }
        }
    }

    // 로직 계약 주소 변경 (오너만 호출 가능)
    function setLogicContract(address _logicContract) external onlyOwner {
        logicContract = _logicContract;
    }
}
