//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract myNFT is ERC721, ERC721URIStorage, Ownable {
    struct Art {
        uint256 id;
        string title;
        string description;
        uint256 price;
        string date;
        string authorName;
        address payable author;
        address payable owner;
        // 1 means token has sale status (or still in selling) and 0 means token is already sold, ownership transferred and moved to off-market gallery
        uint256 status;
        string image;
    }
    struct ArtTxn {
        uint256 id;
        uint256 price;
        address seller;
        address buyer;
        uint256 txnDate;
        uint256 status;
    }
    // gets updated during minting(creation), buying and reselling
    uint256 private pendingArtCount;
    mapping(uint256 => ArtTxn[]) private artTxns;
    uint256 public index; // uint256 value; is cheaper than uint256 value = 0;.
    Art[] public arts;
    // log events back to the user interface
    event LogArtSold(
        uint256 _tokenId,
        string _title,
        string _authorName,
        uint256 _price,
        address _author,
        address _current_owner,
        address _buyer
    );

    event LogArtTokenCreate(
        uint256 _tokenId,
        string _title,
        string _category,
        string _authorName,
        uint256 _price,
        address _author,
        address _current_owner
    );

    event LogArtResell(uint256 _tokenId, uint256 _status, uint256 _price);

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    struct Metadata {
        address owner;
        string data;
    }

    // string  uri = "https://bafybeihxlhsvsawq5mykzdhq2iqp2zy2rb6ppdf7khs2hytjmvbw5agjpi.ipfs.nftstorage.link/metadata/";

    // function changeURI(string memory _uri) public {
    //     uri = _uri;
    // }

    mapping(uint256 => Metadata) NFTs;

    function _baseURI() internal pure override returns (string memory) {
        return
            "https://bafybeihjyplouhig4r77cvqfnpv2e4xxc2yxthhqhile5qe2g2hyyokdfu.ipfs.nftstorage.link/metadata/";
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "https://bafybeihjyplouhig4r77cvqfnpv2e4xxc2yxthhqhile5qe2g2hyyokdfu.ipfs.nftstorage.link/metadata/",
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    /* Create or minting the token */
    function createToken(
        string memory _title,
        string memory _description,
        string memory _date,
        string memory _authorName,
        uint256 _price,
        string memory _image
    ) public onlyOwner {
        require(bytes(_title).length > 0, "The title cannot be empty");
        require(bytes(_date).length > 0, "The Date cannot be empty");
        require(
            bytes(_description).length > 0,
            "The description cannot be empty"
        );
        require(_price > 0, "The price cannot be empty");
        require(bytes(_image).length > 0, "The image cannot be empty");

        Art memory _art = Art({
            id: index,
            title: _title,
            description: _description,
            price: _price,
            date: _date,
            authorName: _authorName,
            author: payable(msg.sender),
            owner: payable(msg.sender),
            status: 1,
            image: _image
        });
        arts.push(_art); // push to the array
        // array length -1 to get the token ID = 0, 1,2 ...
        uint256 tokenId = arts.length - 1;
        _safeMint(msg.sender, tokenId);

        NFTs[tokenId] = Metadata(msg.sender, _image);

        emit LogArtTokenCreate(
            tokenId,
            _title,
            _date,
            _authorName,
            _price,
            msg.sender,
            msg.sender
        );
        index++;
        pendingArtCount++;
    }

    function getMetadata(uint256 _id) public view returns (Metadata memory) {
        return NFTs[_id];
    }

    uint256 comission = 5;

    function buyFinxterArt(uint256 _tokenId) public payable {
        (
            uint256 _id,
            string memory _title,
            ,
            uint256 _price,
            uint256 _status,
            ,
            string memory _authorName,
            address _author,
            address payable _current_owner,

        ) = findFinxterArt(_tokenId);
        require(_current_owner != address(0));
        require(msg.sender != address(0));
        require(msg.sender != _current_owner);
        require(msg.value * 10**18 >= _price);
        require(arts[_tokenId].owner != address(0));
        //approve(msg.sender, _tokenId);
        // transfer ownership of the art
        _safeTransfer(_current_owner, msg.sender, _tokenId, "");
        //return extra payment
        if (msg.value > _price)
            payable(msg.sender).transfer(msg.value - _price);
        //make a payment to the current owner and send royalty to merketplace

        payable(_author).transfer((msg.value / 100) * comission);
        _current_owner.transfer((msg.value / 100) * (100 - comission));

        arts[_tokenId].owner = payable(msg.sender);
        arts[_tokenId].status = 0;

        ArtTxn memory _artTxn = ArtTxn({
            id: _id,
            price: _price,
            seller: _current_owner,
            buyer: msg.sender,
            txnDate: block.timestamp,
            status: _status
        });
        artTxns[_id].push(_artTxn);
        pendingArtCount--;
        emit LogArtSold(
            _tokenId,
            _title,
            _authorName,
            _price,
            _author,
            _current_owner,
            msg.sender
        );
    }

    /* Pass the token ID and get the art Information */
    function findFinxterArt(uint256 _tokenId)
        public
        view
        returns (
            uint256,
            string memory,
            string memory,
            uint256,
            uint256 status,
            string memory,
            string memory,
            address,
            address payable,
            string memory
        )
    {
        Art memory art = arts[_tokenId];
        return (
            art.id,
            art.title,
            art.description,
            art.price,
            art.status,
            art.date,
            art.authorName,
            art.author,
            art.owner,
            art.image
        );
    }

    function resellFinxterArt(uint256 _tokenId, uint256 _price) public payable {
        require(msg.sender != address(0));
        require(isOwnerOf(_tokenId, msg.sender));
        arts[_tokenId].status = 1;
        arts[_tokenId].price = _price;
        pendingArtCount++;
        emit LogArtResell(_tokenId, 1, _price);
    }

    /* returns all the pending arts (status =1) back to the user */
    function findAllPendingFinxterArt()
        public
        view
        returns (
            uint256[] memory,
            address[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        if (pendingArtCount == 0) {
            return (
                new uint256[](0),
                new address[](0),
                new address[](0),
                new uint256[](0)
            );
        }

        uint256 arrLength = arts.length;
        uint256[] memory ids = new uint256[](pendingArtCount);
        address[] memory authors = new address[](pendingArtCount);
        address[] memory owners = new address[](pendingArtCount);
        uint256[] memory status = new uint256[](pendingArtCount);
        uint256 idx = 0;
        for (uint256 i = 0; i < arrLength; ++i) {
            Art memory art = arts[i];
            if (art.status == 1) {
                ids[idx] = art.id;
                authors[idx] = art.author;
                owners[idx] = art.owner;
                status[idx] = art.status;
                idx++;
            }
        }
        return (ids, authors, owners, status);
    }

    /* Return the token ID's that belong to the caller */
    function findMyFinxterArts()
        public
        view
        returns (uint256[] memory _myArts)
    {
        require(msg.sender != address(0));
        uint256 numOftokens = balanceOf(msg.sender);
        if (numOftokens == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory myArts = new uint256[](numOftokens);
            uint256 idx = 0;
            uint256 arrLength = arts.length;
            for (uint256 i = 0; i < arrLength; i++) {
                if (ownerOf(i) == msg.sender) {
                    myArts[idx] = i;
                    idx++;
                }
            }
            return myArts;
        }
    }

    /* return true if the address is the owner of the token or else false */
    function isOwnerOf(uint256 tokenId, address account)
        public
        view
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        require(owner != address(0));
        return owner == account;
    }

    function get_symbol() external view returns (string memory) {
        return symbol();
    }

    function get_name() external view returns (string memory) {
        return name();
    }
} // End of contract
