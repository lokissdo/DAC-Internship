// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract CourseOpeningNFT is ERC721, AccessControl {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _baseTokenURI;

    // Role for admin that can mint, burn, and set minter role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Role for minters that can mint NFTs
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "CONFT: caller is not an admin"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "CONFT: caller is not a minter"
        );
        _;
    }

    //-------- events------------
    event CourseBought(
        string  courseID,
        address indexed  buyer,
        uint256 value,
        uint256 tokenID
    );
    event NFTMinted(string  courseID, address indexed   owner,  uint256 tokenID);
    // Define the RewardItem event
    event RewardItem(
        address indexed  to,
        string  courseId,
        uint256 tokenId
    );

    // ----------------variables---------------------
    uint256 public dropCoursePercent = 5; // part per 10000
    struct Course {
        string courseID;
        uint256 price;
    }

    mapping(string => Course) private _courses;

    // Mapping to store token IDs for each course
    mapping(string => uint256[]) private _courseTokenIds;
    mapping(string => uint256[]) private _availTokenIds;
    string[] private _courseIDs;

    // ----------functions---------------
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC721(name, symbol) {
        // Assign the contract deployer as the initial admin
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Assign the contract deployer as the initial minter
        _grantRole(MINTER_ROLE, msg.sender);
        _baseTokenURI = baseURI;
    }

    //--------------- helpers ----------------
    function random(uint256 from, uint256 to) internal view returns (uint256) {
        uint256 seed = block.number +
            block.timestamp +
            block.difficulty +
            gasleft();
        return (seed % (to - from + 1)) + from;
    }

    // -----------admin-----------------
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function grantMinterRole(address account) public onlyAdmin {
        grantRole(MINTER_ROLE, account);
    }

    function addCourse(Course memory course) public onlyAdmin {
        _courses[course.courseID] = course;
        _courseIDs.push(course.courseID);
    }

    function removeCourse(string memory courseID) public onlyAdmin {
        delete _courses[courseID];
        for (uint256 i = 0; i < _courseIDs.length; i++) {
            if (keccak256(bytes(_courseIDs[i])) == keccak256(bytes(courseID))) {
                _courseIDs[i] = _courseIDs[_courseIDs.length - 1];
                _courseIDs.pop();
                break;
            }
        }
    }

    function revokeMinterRole(address account) public onlyAdmin {
        revokeRole(MINTER_ROLE, account);
    }

    function setDropCoursePercent(uint256 percent) public onlyAdmin {
        require(percent <= 10000, "CONFT: Percentage must be <= 10000"); // Percentage is represented as parts per 10,000 (10000 = 100%)
        dropCoursePercent = percent;
    }

    // Function to show the balance (funds) of the contract
    function showFunds() public view returns (uint256) {
        return address(this).balance;
    }

    // Function to withdraw funds from the contract by the admin
    function withDrawFunds(uint256 amount) public onlyAdmin {
        require(amount > 0, "CONFT: Amount should be greater than zero");
        require(address(this).balance >= amount, "CONFT: Insufficient funds");

        address payable adminAddress = payable(msg.sender);
        adminAddress.transfer(amount);
    }

    // ------------------minter------------------
    function mintNFT(
        address to,
        string memory courseID
    ) internal  returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId);
        _tokenIds.increment();
        _courseTokenIds[courseID].push(newItemId); // Store the token ID for the course
        emit NFTMinted(courseID, to,newItemId);
        return newItemId;
    }

    function mintBatch(uint256 number) public onlyMinter {
        uint256 totalCourses = getTotalCourses();
        require(totalCourses > 0, "CONFT: No courses added yet");

        for (uint256 i = 0; i < number; i++) {
            uint256 randomCourseIndex = random(0, totalCourses - 1);
            string memory courseID = _courseIDs[randomCourseIndex];
            if (_availTokenIds[courseID].length < 1000) {
                uint256 newTokenID = mintNFT(address(this), courseID);
                _availTokenIds[courseID].push(newTokenID);
            }
        }
    }

    function rewardItem(address to) public onlyMinter returns (uint256) {
        require(_tokenIds.current() > 0, "CONFT: No NFTs minted yet");

        uint256 probability = random(0, 10000);
        uint256 totalCourses = getTotalCourses();
        if (probability < dropCoursePercent) {
            // 0-5: 5% probability, user gets a courseID
            uint256 randomCourseIndex = random(0, totalCourses - 1);
            string memory courseID = _courseIDs[randomCourseIndex];
            if (_availTokenIds[courseID].length > 0) {
                uint256 tokenId = _availTokenIds[courseID][
                    _availTokenIds[courseID].length - 1
                ];
                _transfer(address(this), to, tokenId);
                _availTokenIds[courseID].pop(); // Remove the transferred token ID from the array
                emit RewardItem(to, courseID, tokenId);
                return tokenId;
            }
        }
        // 5-99: 95% probability, user gets nothing (will return 0)
        // should give user some item equipment for more beauty
        return 0;
    }

    // -----------------public -------------
    function getAllCourseIDs() public view returns (string[] memory) {
        return _courseIDs;
    }

    function getOpenNTFforCourse(
        string memory courseID
    ) public view returns (uint256[] memory) {
        uint256[] memory tokenIds = _courseTokenIds[courseID];
        return tokenIds;
    }

    function getCourseDetails(
        string memory courseID
    ) public view returns (Course memory) {
        return _courses[courseID];
    }

    function getTotalCourses() public view returns (uint256) {
        return _courseIDs.length;
    }

    function ownsNFTForCourse(
        address owner,
        string memory courseID
    ) public view returns (bool) {
        uint256[] storage tokenIds = _courseTokenIds[courseID];

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (owner == ownerOf(tokenIds[i])) {
                return true;
            }
        }

        return false;
    }

    function buyCourse(string memory courseID) public payable {
        // Step 1: Check if the courseID exists
        require(
            bytes(_courses[courseID].courseID).length > 0,
            "CONFT: Course does not exist"
        );

        // Step 2: Ensure the caller has paid the correct amount
        uint256 price = _courses[courseID].price;
        require(msg.value >= price, "CONFT: Insufficient payment");

        // // Step 3: Transfer ether from the caller to the contract
        // (bool transferSuccess, ) = address(this).call{value: price}("");
        // require(transferSuccess, "CONFT: Ether transfer failed");

        // Step 3: Transfer ether from the caller to the contract address
        // address payable contractAddress = payable(address(this));
        // bool transferSuccess = contractAddress.send(price);
        // require(transferSuccess, "CONFT: Ether transfer failed");
        uint256 tokenId;
        if (_availTokenIds[courseID].length > 0) {
            // Transfer an existing NFT to the buyer
             tokenId = _availTokenIds[courseID][
                _availTokenIds[courseID].length - 1
            ];
            _transfer(address(this), msg.sender, tokenId);
            _availTokenIds[courseID].pop(); // Remove the transferred token ID from the array
        } else {
            // Mint a new NFT for the course
           tokenId =  mintNFT(msg.sender, courseID);
        }

        // Step 5: Emit an event with relevant details
        emit CourseBought(courseID, msg.sender, msg.value,tokenId);
    }

    function fundContract() public payable  {
        require(msg.value > 0, "CONFT: Amount should be greater than zero");
    }
}
