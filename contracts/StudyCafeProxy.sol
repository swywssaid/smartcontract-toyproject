// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title StudyCafeProxy
 * @dev A proxy contract that delegates calls to a logic contract while allowing logic and storage upgrades.
 */
contract StudyCafeProxy {
    address public admin;
    address public currentLogic;
    address public currentStorage;

    event Payment(address indexed sender, uint256 amount);
    event Upgraded(address indexed newLogic, address indexed newStorage);

    /**
     * @dev Modifier to restrict access to the admin only.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    /**
     * @dev Constructor to initialize the proxy with initial logic and storage addresses.
     * @param _logic The initial logic contract address.
     * @param _storage The initial storage contract address.
     */
    constructor(address _logic, address _storage) {
        admin = msg.sender;
        currentLogic = _logic;
        currentStorage = _storage;
    }

    /**
     * @dev Fallback function to receive ether and emit a Payment event.
     */
    receive() external payable {
        emit Payment(msg.sender, msg.value);
    }

    /**
     * @dev Fallback function to delegate calls to the current logic contract.
     * @dev Uses delegatecall to execute the logic contract's code in the context of the proxy.
     * @dev Reverts if the delegatecall to the logic contract fails.
     */
    fallback() external payable {
        (bool success, ) = currentLogic.delegatecall(msg.data);
        require(success, "Delegatecall to logic contract failed");
    }

    /**
     * @dev Function to upgrade the logic and storage addresses.
     * @param _newLogic The new logic contract address.
     * @param _newStorage The new storage contract address.
     * @dev Only accessible by the admin.
     * @dev Emits an Upgraded event after successful upgrade.
     */
    function upgrade(address _newLogic, address _newStorage) external onlyAdmin {
        // Update logic and storage addresses
        currentLogic = _newLogic;
        currentStorage = _newStorage;

        // Emit upgrade event
        emit Upgraded(_newLogic, _newStorage);
    }
}
