// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts@4.7.3/utils/Strings.sol";
import "@openzeppelin/contracts@4.7.3/token/common/ERC2981.sol";
import "@openzeppelin/contracts@4.7.3/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts@4.7.3/access/Ownable.sol";
import {DefaultOperatorFilterer} from "../DefaultOperatorFilterer.sol";
import "./Payment.sol";

contract Example1155 is ERC1155, ERC2981, Payment, Ownable, DefaultOperatorFilterer {
    enum SaleStatus{ PAUSED, PUBLIC }

    mapping(uint256 => bool) private _mintedIds;

    uint private constant MAX_SUPPLY = 10000; //[MAX_SUPPLY]
    uint private constant TOKENS_PER_TRAN_LIMIT = 20; // 20 tokens per transaction [TOKENS_PER_TRAN_LIMIT]
    uint private MINT_PRICE = 1 ether; // 1 ETH [MINT_PRICE]
    SaleStatus private saleStatus = SaleStatus.PAUSED; 
    mapping(address => uint) private _mintedCount;
    string private _contractURI;

    event Withdraw();

    constructor(
        address[] memory shareAddressList, 
        uint[] memory shareList, 
        uint96 _royaltyFeesInBips, 
        string memory _initBaseURI,
        string memory _contURI) ERC1155("Example1155") Payment(shareAddressList, shareList){
        setRoyaltyInfo(owner(), _royaltyFeesInBips);
        setURI(_initBaseURI);
        setContractURI(_contURI);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory newUri) public onlyOwner {
        _contractURI = newUri;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function calculateRoyalty(uint256 _salePrice) pure public returns (uint256) {
        return (_salePrice / 10000);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /// @notice Get token URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view returns (string memory) {
        string memory baseURI = uri(tokenId);

        return string(abi.encodePacked(baseURI, "/", Strings.toString(tokenId), ".json"));
    }

    function totalSupply() public pure returns (uint) {
        return MAX_SUPPLY;
    }

    function isMinted(uint256 id) public view returns (bool) {
        return _mintedIds[id] == true;
    }

    /// @notice Update current sale stage
    function setSaleStatus(SaleStatus status) external onlyOwner {
        saleStatus = status;
    }

    /// @notice Update public mint price
    function setPublicMintPrice(uint price) external onlyOwner {
        MINT_PRICE = price;
    }

    function airdrop(address to, uint256 id) external onlyOwner {
        require(saleStatus != SaleStatus.PAUSED, " Sales are off");
        require(id > 0, "Token doesn't exists");
        require(id <= MAX_SUPPLY, "Token doesn't exists");

        require(_mintedIds[id] != true, "Token already minted" );

        _mint(to, id, 1, "");


        _mintedIds[id] = true;
    }

    function mint(uint256 id) public payable {
        require(saleStatus != SaleStatus.PAUSED, " Sales are off");
        require(id > 0, "Token doesn't exists");
        require(id <= MAX_SUPPLY, "Token doesn't exists");

        require(_mintedIds[id] != true, "Token already minted" );

        uint price = calcFamilynamePrice(id);
        require(msg.value >= MINT_PRICE, "ETH input is wrong");
       
        require(msg.value >= calcFamilynamePrice(id), " Ether value sent is not sufficient");  

        _mint(msg.sender, id, 1, "");

        _mintedIds[id] = true;
	}


    function mintBatch(uint256[] memory ids) public payable
    {
        require(saleStatus != SaleStatus.PAUSED, "Sales are off");
        require(ids.length <= TOKENS_PER_TRAN_LIMIT, "Number of requested tokens exceeds allowance (20)");
        
        require(msg.value >= MINT_PRICE * ids.length, "ETH input is wrong");

        uint[] memory amounts = new uint[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            require(id > 0, "Token doesn't exists");
            require(id <= MAX_SUPPLY, "Token doesn't exists");
            require(_mintedIds[id] != true, "Some tokens already minted" );
            amounts[i] = 1;
        }

        _mintBatch(msg.sender, ids, amounts, "");

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            _mintedIds[id] = true;
        }       
    }

    function withdraw() external  {
        _withdraw(payable(msg.sender));
        emit Withdraw();
	}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}