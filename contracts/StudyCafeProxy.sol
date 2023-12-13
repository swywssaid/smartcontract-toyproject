// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StudyCafeProxy {
    address public admin;
    address public currentLogic;
    address public currentStorage;

    event Payment(address indexed sender, uint256 amount);
    event Upgraded(address indexed newLogic, address indexed newStorage);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor(address _logic, address _storage) {
        admin = msg.sender;
        currentLogic = _logic;
        currentStorage = _storage;
    }
    
    receive() external payable {
        // This function is needed to receive ether
        emit Payment(msg.sender, msg.value);
    }

    fallback() external payable {
        // Delegatecall to logic contract
        (bool success, ) = currentLogic.delegatecall(msg.data);
        require(success, "Delegatecall to logic contract failed");
    }

    function upgrade(address _newLogic, address _newStorage) external onlyAdmin {
        // Update logic and storage addresses
        currentLogic = _newLogic;
        currentStorage = _newStorage;

        // Emit upgrade event
        emit Upgraded(_newLogic, _newStorage);
    }
}
