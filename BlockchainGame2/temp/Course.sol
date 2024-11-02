// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Box is the NFT representing a course access
contract Box is ERC721Enumerable, Ownable {
    struct CourseMetadata {
        string name;
        string description;
        uint256 price;
    }

    CourseMetadata[] public courses;

    // Token used for purchasing boxes
    IERC20 public token;

    event BoxMinted(address indexed owner, uint256 indexed tokenId, uint256 courseId);

    constructor(address _tokenAddress) ERC721("Course Box", "CBOX") {
        token = IERC20(_tokenAddress);
    }

    // Mint a box representing a course with specific metadata
    function mintBox(
        string memory _name,
        string memory _description,
        uint256 _price
    ) external onlyOwner {
        uint256 courseId = courses.length;
        courses.push(CourseMetadata(_name, _description, _price));
        uint256 tokenId = totalSupply();
        _mint(owner(), tokenId);
        emit BoxMinted(owner(), tokenId, courseId);
    }

    // Get the total number of courses available
    function getTotalCourses() external view returns (uint256) {
        return courses.length;
    }

    // Get course metadata by course ID
    function getCourseMetadata(uint256 courseId)
        external
        view
        returns (CourseMetadata memory)
    {
        return courses[courseId];
    }

    // Buy a box representing a course with a given course ID
    function buyBox(uint256 courseId) external {
        require(courseId < courses.length, "Invalid course ID");
        CourseMetadata memory course = courses[courseId];
        require(
            token.balanceOf(msg.sender) >= course.price,
            "Insufficient balance"
        );
        token.transferFrom(msg.sender, address(this), course.price);
        _safeMint(msg.sender, totalSupply());
    }
}

