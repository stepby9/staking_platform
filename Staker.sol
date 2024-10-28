// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

    // Instance of the external contract
    ExampleExternalContract public exampleExternalContract;

    // Mapping to keep track of each address's balance
    mapping(address => uint256) public balances;

    // Constants and variables for the threshold and deadline
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;

    // Boolean to indicate if funds are open for withdrawal
    bool public openForWithdraw;

    // Event to track staking activities
    event Stake(address indexed sender, uint256 amount);

    // Modifier to check if the external contract is not completed
    modifier notCompleted() {
        require(!exampleExternalContract.completed(), "Contract already completed");
        _;
    }

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    // Payable function to allow users to stake ETH
    function stake() public payable {
        require(block.timestamp < deadline, "Staking period is over");

        // Update the balance for the sender
        balances[msg.sender] += msg.value;

        // Emit the Stake event for frontend tracking
        emit Stake(msg.sender, msg.value);
    }

    // Function to execute and send funds to the ExampleExternalContract if the threshold is met
    function execute() public notCompleted {
        require(block.timestamp >= deadline, "Deadline has not been reached yet");

        // Check if the balance meets the threshold
        if (address(this).balance >= threshold) {
            // Send the entire contract balance to the ExampleExternalContract
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            // Open funds for withdrawal if threshold is not met
            openForWithdraw = true;
        }
    }

    // Function to withdraw funds if the threshold was not met
    function withdraw() public notCompleted {
        require(openForWithdraw, "Withdrawals are not allowed yet");
        require(balances[msg.sender] > 0, "No balance to withdraw");

        // Store the amount to transfer, then set sender's balance to 0
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;

        // Transfer the amount back to the sender
        payable(msg.sender).transfer(amount);
    }

    // View function to show time left until the deadline
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    // Special receive function to accept ETH and call the stake function
    receive() external payable {
        stake();
    }
}
