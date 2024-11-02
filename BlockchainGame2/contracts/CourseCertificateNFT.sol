// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CourseCertificateNFT is ERC721, AccessControl {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string private _baseTokenURI;

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Role for admin that can mint, burn, and set minter role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Role for minters that can mint NFTs
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(string  => uint256[]) private _courseTokenIds;
    event NFTMinted(string  courseID, address  indexed owner,uint256 tokenID);
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

    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "CCNFT: caller is not an admin"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "CCNFT: caller is not a minter"
        );
        _;
    }

    function grantMinterRole(address account) public onlyAdmin {
        grantRole(MINTER_ROLE, account);
    }

    function revokeMinterRole(address account) public onlyAdmin {
        revokeRole(MINTER_ROLE, account);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function mintCertNFT(
        address to,
        string  memory courseID
    ) public onlyMinter returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId);
        _tokenIds.increment();
        _courseTokenIds[courseID].push(newItemId);
        emit NFTMinted(courseID, to,newItemId);
        return newItemId;
    }

    function ownsCertNFTForCourse(
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
    function getCertNTFforCourse(
         string memory courseID
    ) public view returns ( uint256[] memory) {
        uint256[] memory tokenIds = _courseTokenIds[courseID];
        return tokenIds;
    }
}
