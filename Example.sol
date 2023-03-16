
                        
/*
 /$$$$$$$$                                /$$$$$$                  /$$           /$$   /$$ /$$$$$$$$ /$$$$$$$$
|_____ $$                                /$$__  $$                | $$          | $$$ | $$| $$_____/|__  $$__/
     /$$/   /$$$$$$   /$$$$$$   /$$$$$$ | $$  \__/  /$$$$$$   /$$$$$$$  /$$$$$$ | $$$$| $$| $$         | $$
    /$$/   /$$__  $$ /$$__  $$ /$$__  $$| $$       /$$__  $$ /$$__  $$ /$$__  $$| $$ $$ $$| $$$$$      | $$
   /$$/   | $$$$$$$$| $$  \__/| $$  \ $$| $$      | $$  \ $$| $$  | $$| $$$$$$$$| $$  $$$$| $$__/      | $$
  /$$/    | $$_____/| $$      | $$  | $$| $$    $$| $$  | $$| $$  | $$| $$_____/| $$\  $$$| $$         | $$
 /$$$$$$$$|  $$$$$$$| $$      |  $$$$$$/|  $$$$$$/|  $$$$$$/|  $$$$$$$|  $$$$$$$| $$ \  $$| $$         | $$
|________/ \_______/|__/       \______/  \______/  \______/  \_______/ \_______/|__/  \__/|__/         |__/

Drop Your NFT Collection With ZERO Coding Skills at https://zerocodenft.com
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Giga is ERC721, Ownable, DefaultOperatorFilterer {
    using Strings for uint;
    using Counters for Counters.Counter;
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC }

    Counters.Counter private _tokenIds;

    uint public constant COLLECTION_SIZE = 892;
    
    
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 77;
    
    
    uint public MINT_PRICE = 0.2 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    
    string private _baseURL;
    string public preRevealURL = "ipfs://QmdaWN3TtT1UTGssGuoTo7SvpRQtLs7ADaX1h5jgSMHFCu";
    mapping(address =&gt; uint) private _mintedCount;
    

    constructor() ERC721("Giga", "BOBO"){}
    
    
    function contractURI() public pure returns (string memory) {
        return "data:application/json;base64,eyJuYW1lIjoiR29vZ2Rkd2RhZCIsImRlc2NyaXB0aW9uIjpudWxsLCJleHRlcm5hbF91cmwiOiJodHRwczovL3Rlc3RuZXRzLm9wZW5zZWEuaW8vY29sbGVjdGlvbi8iLCJmZWVfcmVjaXBpZW50IjoiMHg4RTIwOUE4YWVmYTY2Njg0MDhhZDM0MDhjQzYwODBmOEQ1MzlDMDY4Iiwic2VsbGVyX2ZlZV9iYXNpc19wb2ludHMiOjB9";
    }
    
    
    /// @notice Reveal metadata for all the tokens
    function reveal(string calldata url) external onlyOwner {
        _baseURL = url;
    }
    
    /// @notice Set Pre Reveal URL
    function setPreRevealUrl(string calldata url) external onlyOwner {
        preRevealURL = url;
    }
    

    function totalSupply() external view returns (uint) {
        return _tokenIds.current();
    }

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    /// @notice Update current sale stage
    function setSaleStatus(SaleStatus status) external onlyOwner {
        saleStatus = status;
    }

    /// @notice Update public mint price
    function setPublicMintPrice(uint price) external onlyOwner {
        MINT_PRICE = price;
    }

    /// @notice Withdraw contract balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance &gt; 0, "No balance");
        
        payable(0x8E209A8aefa6668408ad3408cC6080f8D539C068).transfer((balance * 10000)/10000);
    }

    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(_tokenIds.current() + count &lt;= COLLECTION_SIZE, "Request exceeds collection size");
        _mintTokens(to, count);
    }

    /// @notice Get token URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        return bytes(baseURI).length &gt; 0 
            ? string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json")) 
            : preRevealURL;
    }
    
    function calcTotal(uint count) public view returns(uint) {
        require(saleStatus != SaleStatus.PAUSED, "Giga: Sales are off");

        

        
        uint price = MINT_PRICE;

        return count * price;
    }
    
    
    
    /// @notice Mints specified amount of tokens
    /// @param count How many tokens to mint
    function mint(uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "Giga: Sales are off");
        require(_tokenIds.current() + count &lt;= COLLECTION_SIZE, "Giga: Number of requested tokens will exceed collection size");
        
        require(_mintedCount[msg.sender] + count &lt;= TOKENS_PER_PERSON_PUB_LIMIT, "Giga: Number of requested tokens exceeds allowance (77)");
        require(msg.value &gt;= calcTotal(count), "Giga: Ether value sent is not sufficient");
        _mintedCount[msg.sender] += count;
        _mintTokens(msg.sender, count);
    }
    /// @dev Perform actual minting of the tokens
    function _mintTokens(address to, uint count) internal {
        for(uint index = 0; index &lt; count; index++) {

            _tokenIds.increment();
            uint newItemId = _tokenIds.current();

            _safeMint(to, newItemId);
        }
    }

    /// @notice DefaultOperatorFilterer OpenSea overrides    
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

                    