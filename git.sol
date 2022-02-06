// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract GitToken is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    struct Repo {
        uint256 maxSupply;
        bool maxSet;
        string repo;
        uint256 value;
    }

    uint256 private collectionRate;

    mapping(string => Repo) repos;

    constructor() ERC721("GitToken", "GIT") {}

    // function safeMint(address to, string memory uri) public onlyOwner returns(uint256) {
    //     require(maxSet == true, "Tokens not for trading");
    //     require(totalSupply()+1 <= maxSupply, "Too many tokens distributed");
        
    //     uint256 tokenId = _tokenIdCounter.current();
    //     _tokenIdCounter.increment();
    //     _safeMint(to, tokenId);
    //     _setTokenURI(tokenId, uri);
    //     return totalSupply();
    // }
    function initRepo(string memory link, uint256 max) public {
        require(repos[link].maxSet == false, "Repo already exists");
        repos[link].repo = link;
        setSupply(link, max);
    }

    function setSupply(string memory owner, uint256 total) private onlyOwner {
        require(repos[owner].maxSet == false, "Total supply is already set");
        repos[owner].maxSupply = total;
        repos[owner].maxSet = true;
    }

     function USDWEI(uint dollar) public pure returns (uint256) {
        return (dollar * 330000000000000);
    }
    function value(uint256 stars,uint256 forks,uint256 daysLastcommit,uint256 commits, string memory link) public returns (uint256) {
        require(totalSupply()+1 != repos[link].maxSupply, "All tokens sold");
        repos[link].value = 
          ( ( ( (stars*100)+(forks*100)+(commits*100) ) - (daysLastcommit*100) ) );
        repos[link].value = repos[link].value / (repos[link].maxSupply - totalSupply());
        repos[link].value = USDWEI(repos[link].value) / 2560;
        return repos[link].value;
    }
    function getValue(string memory link) public view returns (uint256) {
        return repos[link].value;
    }

    function mint(string memory link) public payable {
        require(repos[link].value != 0, "Repo is invalid");
        require(totalSupply()+1 != repos[link].maxSupply, "All tokens sold");

        require(msg.value == repos[link].value,string(abi.encodePacked("Required payment due not met.",Strings.toString(repos[link].value))));
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender,tokenId);
        _setTokenURI(tokenId,
            string(abi.encodePacked(link,"#", Strings.toString(tokenId))) 
        );
    }
    function burn(address payable to, string memory link, uint256 index) public {
        tokenOfOwnerByIndex(to,index);
        (bool success, ) = to.call{value: getValue(link) }("");
        require(success, "Failed to send Ether");
        _burn(index);
    }
    function kill(address payable owner) public {
        selfdestruct(owner);
    }
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
