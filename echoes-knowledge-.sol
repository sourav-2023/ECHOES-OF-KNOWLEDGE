// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EchoesOfKnowledge is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;

    // Problem difficulty levels
    enum Difficulty { EASY, MEDIUM, HARD }

    // Structure to store problem details
    struct Problem {
        uint256 id;
        string title;
        Difficulty difficulty;
        string category;
        uint256 points;
        bool isActive;
    }

    // Structure to store badge metadata
    struct Badge {
        uint256 problemId;
        address owner;
        uint256 completedAt;
        string ipfsHash;
        uint256 points;
    }

    // Mapping to store problems
    mapping(uint256 => Problem) public problems;
    
    // Mapping to store badges
    mapping(uint256 => Badge) public badges;
    
    // Mapping to track if user has completed a problem
    mapping(address => mapping(uint256 => bool)) public hasCompleted;
    
    // Mapping to store user's completed problems
    mapping(address => uint256[]) public userCompletedProblems;
    
    // Events
    event ProblemAdded(uint256 indexed problemId, string title, uint8 difficulty);
    event ProblemCompleted(address indexed user, uint256 indexed problemId, uint256 tokenId);
    event BadgeMinted(address indexed user, uint256 indexed tokenId, string ipfsHash);

    constructor() ERC721("Echoes of Knowledge", "EOK") Ownable(msg.sender) {}

    // Override required functions for multiple inheritance
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Admin functions
    function addProblem(
        string memory title,
        uint8 difficulty,
        string memory category,
        uint256 points
    ) public onlyOwner {
        require(difficulty <= uint8(Difficulty.HARD), "Invalid difficulty level");
        
        uint256 problemId = _tokenIds.current();
        _tokenIds.increment();
        
        problems[problemId] = Problem({
            id: problemId,
            title: title,
            difficulty: Difficulty(difficulty),
            category: category,
            points: points,
            isActive: true
        });
        
        emit ProblemAdded(problemId, title, difficulty);
    }

    function deactivateProblem(uint256 problemId) public onlyOwner {
        require(problems[problemId].isActive, "Problem already inactive");
        problems[problemId].isActive = false;
    }

    // User functions
    function mintCompletionBadge(
        address user,
        uint256 problemId,
        string memory ipfsHash
    ) public onlyOwner returns (uint256) {
        require(!hasCompleted[user][problemId], "Problem already completed");
        require(problems[problemId].isActive, "Problem is not active");

        uint256 newTokenId = _tokenIds.current();
        _tokenIds.increment();

        _safeMint(user, newTokenId);
        _setTokenURI(newTokenId, ipfsHash);

        // Record completion
        hasCompleted[user][problemId] = true;
        userCompletedProblems[user].push(problemId);

        // Store badge details
        badges[newTokenId] = Badge({
            problemId: problemId,
            owner: user,
            completedAt: block.timestamp,
            ipfsHash: ipfsHash,
            points: problems[problemId].points
        });

        emit ProblemCompleted(user, problemId, newTokenId);
        emit BadgeMinted(user, newTokenId, ipfsHash);

        return newTokenId;
    }

    // View functions
    function getUserCompletedProblems(address user) public view returns (uint256[] memory) {
        return userCompletedProblems[user];
    }

    function getUserBadges(address user) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(user);
        uint256[] memory userBadges = new uint256[](balance);
        
        for (uint256 i = 0; i < balance; i++) {
            userBadges[i] = tokenOfOwnerByIndex(user, i);
        }
        
        return userBadges;
    }

    function getBadgeDetails(uint256 tokenId) public view returns (Badge memory) {
        require(_exists(tokenId), "Badge does not exist");
        return badges[tokenId];
    }

    function getProblemDetails(uint256 problemId) public view returns (Problem memory) {
        require(problems[problemId].isActive, "Problem does not exist");
        return problems[problemId];
    }

    function getUserPoints(address user) public view returns (uint256) {
        uint256 totalPoints = 0;
        uint256[] memory userBadges = getUserBadges(user);
        
        for (uint256 i = 0; i < userBadges.length; i++) {
            totalPoints += badges[userBadges[i]].points;
        }
        
        return totalPoints;
    }

    // Additional helper functions
    function isCompleted(address user, uint256 problemId) public view returns (bool) {
        return hasCompleted[user][problemId];
    }
}
