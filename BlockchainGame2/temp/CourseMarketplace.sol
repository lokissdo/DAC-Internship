// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";


contract CourseMarketplace {
    address public owner;
    mapping(uint256 => bool) public courses;

    event CoursePurchased(address indexed buyer, uint256 courseId);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function addCourse(uint256 courseId) external onlyOwner {
        courses[courseId] = true;
    }

    function purchaseCourse(uint256 courseId) external payable {
        require(courses[courseId], "Course does not exist");
        // Add your course enrollment logic here
        emit CoursePurchased(msg.sender, courseId);
    }
}
