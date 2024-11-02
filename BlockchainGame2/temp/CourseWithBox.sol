// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MyNFT is ERC721Enumerable, Ownable, AccessControl {
    using SafeMath for uint256;

    // Role for admin that can mint, burn, and set minter role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Role for minters that can mint NFTs
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public constant MAX_NFT_SUPPLY = 10000;
    uint256 public constant MAX_BOX_SUPPLY = 1000;
    uint256 public constant BOX_PRICE = 1 ether;


    uint256 public nftSupply;
    uint256 public nftSupply;

    mapping(uint256 => string) private _tokenURIs;

    event BoxBought(
        address indexed owner,
        uint256 indexed boxId,
        address indexed buyer,
        uint256 value
    );
    enum BoxType {
        TypeI,
        TypeII
    }
    enum BoxStatus {
        OnSale,
        InUse
    }
    struct Box {
        BoxType typeOfBox;
        uint256 courseID;
        BoxStatus sttOfBox;
    }
    mapping(uint256 => Box) private _boxes;
    uint256[] private _courses;
    
    struct openingCourseNFT {
        uint256 courseID;
        uint256 expDate;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        // Assign the contract deployer as the initial admin
        _setupRole(ADMIN_ROLE, msg.sender);

        // Assign the contract deployer as the initial minter
        _setupRole(MINTER_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "MyNFT: caller is not an admin"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "MyNFT: caller is not a minter"
        );
        _;
    }

    function grantMinterRole(address account) public onlyAdmin {
        grantRole(MINTER_ROLE, account);
    }

    function addCourse(uint256 courseID) public onlyAdmin {
        _courses.push(courseID);
    }

    function removeCourse(uint256 courseID) public onlyAdmin {
        uint i = 0;
        while (_courses[i] != value) {
            i++;
        }
        for (uint j = i; j < _courses.length - 1; j++) {
            _courses[j] = _courses[j + 1];
        }
        _courses.pop();
    }

    function revokeMinterRole(address account) public onlyAdmin {
        revokeRole(MINTER_ROLE, account);
    }

    // function mint(address to, uint256 tokenId) public onlyMinter {
    function mintBox(BoxType typeOfBox, uint256 courseID) public onlyMinter {
        //_mint(to, tokenId);

        _safeMint(msg.sender, nftSupply);
        _boxes[nftSupply] = Box(typeOfBox, courseID, BoxStatus.OnSale);
    }

    function burn(uint256 tokenId) public onlyAdmin {
        _burn(tokenId);
    }

    // mapping(uint256 => Box) private _boxes;

    // Buy box type 2: Đồng giá, random ra khóa học
    function buyBox(uint256 boxId) external payable {
        require(msg.value >= BOX_PRICE, "Insufficient ether");

        address owner = ownerOf(boxId);
        require(owner != address(0), "Box not minted yet");

        // // Check if the owner is a minter or admin before allowing the purchase
        // require(hasRole(MINTER_ROLE, owner) || hasRole(ADMIN_ROLE, owner), "Only minter or admin can sell boxes");
        Box box = _boxes[boxId];
        require(box.sttOfBox = BoxStatus.OnSale, "This box cannot be bought");

        uint256 price;
        if (box.typeOfBox == BoxType.TypeII) price = BOX_PRICE;
        else if (box.typeOfBox == BoxType.TypeI) {
            // call API to get price of course.
            price = 200;
        }
        payable(owner).transfer(price);

        _safeTransfer(owner, msg.sender, boxId, "");
        emit BoxBought(owner, boxId, msg.sender, price);
    }

    function openBox(uint256 boxId) external {
        require(ownerOf(boxId) == msg.sender, "Not holder of box");
        nftSupply++;
        _safeMint(msg.sender, nftSupply);
        setTokenURI(
            nftSupply,
            msg.sender,
            boxId,
            "NFT #" + Strings.toString(nftSupply)
        );
        _burn(boxId);
    }
}
