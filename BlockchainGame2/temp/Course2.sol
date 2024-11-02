// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CourseNFT is ERC721, AccessControl {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public constant MAX_NFT_SUPPLY = 10000;
    uint256 public constant MAX_BOX_SUPPLY = 1000;
    uint256 public constant BOX_PRICE = 1 ether;

    uint256 public boxSupply;
    uint256 public nftSupply;

    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("CourseNFT", "CNFT") {
        _setupRole(OWNER_ROLE, msg.sender);
    }

    function mintBox() external payable {
        require(
            hasRole(ADMIN_ROLE, msg.sender) || hasRole(OWNER_ROLE, msg.sender),
            "Unauthorized"
        );
        require(boxSupply < MAX_BOX_SUPPLY, "Box supply exceeded");
        require(msg.value >= BOX_PRICE, "Insufficient ether");

        boxSupply++;
        nftSupply++;

        _safeMint(msg.sender, nftSupply);
        setTokenURI(nftSupply, "https://example.com/metadata.json");
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        _tokenURIs[tokenId] = uri;
    }
    function setTokenURI(
        uint256 tokenId,
        address minter,
        uint256 courseId,
        string memory name
    ) public onlyOwner {
        string memory metadata = string(
            abi.encodePacked(
                "https://example.com/metadata.json?",
                "minter=",
                Strings.toHexString(uint160(minter), 20),
                "&courseId=",
                Strings.toString(courseId),
                "&name=",
                name
            )
        );

        _tokenURIs[tokenId] = metadata;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenURIs[tokenId];
    }

    function addAdmin(address account) external onlyOwner {
        grantRole(ADMIN_ROLE, account);
    }

    function removeAdmin(address account) external onlyOwner {
        revokeRole(ADMIN_ROLE, account);
    }

    event BoxBought(
        address indexed minter,
        uint256 indexed boxId,
        address indexed sender,
        uint256 value
    );
    
    struct Box {
        address holder;
    }

    mapping(uint256 => Box) private _boxes;

    function buyBox(uint256 boxId) external payable {
        require(msg.value >= BOX_PRICE, "Insufficient ether");
        require(boxId <= boxSupply, "Invalid box ID");

        address owner = ownerOf(boxId);
        require(owner != address(0), "Box not minted yet");

        payable(owner).transfer(msg.value);

        _safeTransfer(owner, msg.sender, boxId, "");
        _boxes[boxId].holder = msg.sender;
        emit BoxBought(owner, boxId, msg.sender, msg.value);
    }

    function openBox(uint256 boxId) external {
        require(_boxes[boxId].holder == msg.sender, "Not holder of box");
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
