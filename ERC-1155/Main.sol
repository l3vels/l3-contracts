// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts@4.7.3/utils/Strings.sol";
import "@openzeppelin/contracts@4.7.3/token/common/ERC2981.sol";
import "@openzeppelin/contracts@4.7.3/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts@4.7.3/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";  // {{is_opensea}} then need DefaultOperatorFilterer

import "./Payment.sol";

// {{is_opensea}} then need , DefaultOperatorFilterer
contract Main is ERC1155, ERC2981, Payment, Ownable, DefaultOperatorFilterer {
    //That is sale status, if anyone want to control sale status
    enum SaleStatus{ PAUSED, PRE_SALE, PUBLIC } // {{is_sale_status}}

    uint private constant COLLECTION_SIZE = 10000; //{{COLLECTION_SIZE}, if {{COLLECTION_SIZE} is null, remove that line
    uint public constant MAX_MINT_PER_TRANSACTION = 77; //{{MAX_MINT_PER_TRANSACTION}}, if user does not define it need remove that line completly
    uint public constant MAX_MINT_PER_PLAYER = 77; //{{MAX_MINT_PER_PLAYER}} if {{MAX_MINT_PER_PLAYER}} is not defined then remove that line
    uint private PLAYER_MINT_FEE = 1 ether; //{{PLAYER_MINT_FEE}}, if {{PLAYER_MINT_FEE}} is not defined then remove that line
    SaleStatus private saleStatus = SaleStatus.PAUSED; //Set default sale status {{SaleStatus.PAUSE}},  if {{is_sale_statue}} is not defined then remove that line
    string private _contractURI;

    mapping(address => uint256) private _mintedAmount;
    mapping(uint256 => address) private _tokenCreators;

    event Airdrop(address indexed player, uint256 indexed tokenId, uint256 indexed amount); // {{is_airdrop}} then need define it
    event Award(address indexed player, uint256 indexed tokenId, uint256 indexed amount); // {{is_award}} then need define it
    event PlayerMint(address indexed player, uint256 indexed tokenId, uint256 indexed amount); // {{is_buy}} then need define it
    event PlayerBatchMint(address indexed player, uint256[] indexed tokenIds, uint256[] indexed amounts); // {{is_buy}} then need define it


    // shareAddressList is array of address, where you have to send all revewnue split addresses like [address1, adddress2, address3]
    // shareList is an array of percents, if you have 3 owners and revenue split 20, 30, 50, you have to set [20, 30, 50]
    //_royaltyFeesInBips is royalty pernce, if you want to have roaylty like 10%, just send 1000, you can set empty from the start and set it later
    //_initBaseURI is metadata base url, you can send emty from the start, and after you use setURI method
    //_contURI is json file url, here is example: https://share.cleanshot.com/rtr3DcrS
    constructor(
        address[] memory shareAddressList, 
        uint[] memory shareList, 
        uint96 _royaltyFeesInBips, 
        string memory _initBaseURI,
        string memory _contURI) ERC1155("{{CollectionName}}") Payment(shareAddressList, shareList){
        setRoyaltyInfo(owner(), _royaltyFeesInBips);
        setURI(_initBaseURI);
        setContractURI(_contURI);
    }

    //if {{is_mint_by_admin}} set it
    function _mintToken(address player, uint256 tokenId, uint256 amount, bytes memory data) private {
        require(saleStatus != SaleStatus.PAUSED, "Sales are off"); //if {{is_sale_statue}} is not defined then remove that line
        require(tokenId > 0, "Token doesn't exists");
        require(tokenId <= COLLECTION_SIZE, "Token doesn't exists"); //if {{COLLECTION_SIZE} is null, remove that line

        
        require(_mintedAmount[player] + amount <= MAX_MINT_PER_PLAYER, "{{CollectionName}}: Cannot mint more than allowed limit per player");  // if {{MAX_MINT_PER_PLAYER}} is not defined then remove that line

        _mint(player, tokenId, amount, data);
        _mintedAmount[player] += amount;
        _tokenCreators[tokenId] = player;
    }

    //if {{is_mint_by_admin}} then define that method
    function _mintBatchToken(address player, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data) private {
        require(saleStatus != SaleStatus.PAUSED, "Sales are off"); //if {{is_sale_statue}} is not defined then remove that line

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 0, "Token doesn't exists");
            require(tokenIds[i] <= COLLECTION_SIZE, "Token doesn't exists"); //if {{COLLECTION_SIZE} is null, remove that line
        }

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(_mintedAmount[player] + totalAmount <= MAX_MINT_PER_PLAYER, "{{CollectionName}}: Cannot mint more than allowed limit per player"); //if {{MAX_MINT_PER_PLAYER}} is not null we don't need to check it
        require(totalAmount <= MAX_MINT_PER_TRANSACTION, "{{CollectionName}}: Cannot mint more thab allowed limit per trasaction");  //if {{MAX_MINT_PER_TRANSACTION}} is not defined then remove that line

        _mintBatch(player, tokenIds, amounts, data);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mintedAmount[player] += amounts[i];
            _tokenCreators[tokenIds[i]] = player;
        }
    }

    //if {{is_mint_by_admin}} then define that method
    function mint(address player, uint256 tokenId, uint256 amount, bytes memory data) public onlyOwner {
        _mintToken(player, tokenId, amount, data);
    }

    //if {{is_mint_by_admin}} then define that method
    function mintBatch(address player, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data) public onlyOwner {
        _mintBatchToken(player, tokenIds, amounts, data);
    }

    //if {{is_buy_by_player}} then define that method
    function playerMint(uint256 tokenId, uint256 amount, bytes memory data) public payable {
        require(msg.value >= PLAYER_MINT_FEE, "{{CollectionName}}: Insufficient mint fee");
        _mintToken(msg.sender, tokenId, amount, data);

        emit PlayerMint(msg.sender, tokenId, amount);
	}

    //if {{is_buy_by_player}}  then define that method
    function batchPlayerMint(uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data) public payable
    {      
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(msg.value >= PLAYER_MINT_FEE * totalAmount, "GameCollection: Insufficient mint fee");
        _mintBatchToken(msg.sender, tokenIds, amounts, data);

        emit PlayerBatchMint(msg.sender, tokenIds, amounts);
    }

    //if {{is_award}} then define that method
    function award(address player, uint256 tokenId, uint256 amount, bytes memory data) external onlyOwner {
        _mintToken(player, tokenId, amount, data);

        emit Award(player, tokenId, amount);
    }

    //if {{is_airdrop}} then add that method
    function airdrop(address player, uint256 tokenId, uint256 amount, bytes memory data) external onlyOwner {
        _mintToken(player, tokenId, amount, data);

        emit Airdrop(player, tokenId, amount);
    }

    //if {{is_contract_uri}} then use that method
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    //if {{is_contract_uri}} then use that method
    function setContractURI(string memory newUri) public onlyOwner {
        _contractURI = newUri;
    }

     //if {{is_royalties}} then use that method
    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

     //if {{is_royalties}} then use that method
    function calculateRoyalty(uint256 _salePrice) pure public returns (uint256) {
        return (_salePrice / 10000);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
    
    //if {{is_url_based_on_collection}} Use when we have global URL of Assets folder
    function tokenURI(uint tokenId) public view returns (string memory) {
        string memory baseURI = uri(tokenId);

        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, "/", Strings.toString(tokenId), ".json"))
            : '';
    }

    // if {{is_url_based_on_token_id}}, when you will define that method, call method: tokenURI, I can not here already declared above
    function tokenURIByAsset(uint tokenId) public view returns (string memory) {
        string memory baseURI = uri(tokenId);

        return baseURI;
    }

    //if {{COLLECTION_SIZE} is null, remove that method
    function totalSupply() public pure returns (uint) {
        return COLLECTION_SIZE; 
    }

    /// @notice Update current sale stage
    function setSaleStatus(SaleStatus status) external onlyOwner {
        saleStatus = status;
    }

    /// @notice Update public mint price
    function setPublicMintPrice(uint price) external onlyOwner {
        PLAYER_MINT_FEE = price;
    }

    // {{is_withdraw}} then define that method
    function withdraw() external  {
        _withdraw(payable(msg.sender));
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