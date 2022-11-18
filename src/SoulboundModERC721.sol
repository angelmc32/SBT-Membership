// SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.13;

import {ERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721Metadata} from "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Context} from "../lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract SoulboundModERC721 is Context, ERC165 {
    using Strings for uint256;
    event Transfer(address indexed _from, address indexed _to, uint256 indexed tokenId);
    // Emit event when a SBT Membership is created? "Afiliación"
    // Emit event when a SBT Membership is revoked?

    address public operator;                            // Contract operator has privileges to transfer/recover tokens
    string private _name;                               // Token name
    string private _symbol;                             // Token symbol
    mapping(address => uint256) internal _balances;     // Mapping owner address to token count
    mapping(uint256 => address) internal _owners;       // Mapping from token ID to owner address
    mapping(uint256 => bool) private _isRecoverable;    // Flag for transferable status, in case of key loss or theft

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_)  {
        operator = _msgSender();
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view returns(uint256) {
        require(owner != address(0), "SoulboundModERC721: Address is zero");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns(address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "SoulboundModERC721: Invalid Token ID - token nonexistant/not minted");
        return owner;
    }
// AQUI
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "SoulboundModERC721: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    
    function transferFrom(address from_, address to_, uint256 tokenId_) public {
        address owner = ownerOf(tokenId_);
        require(msg.sender == owner, "msg.sender is not the owner or someone approved for transfer");
        require(owner == from_, "From address is not the owner");
        require(to_ != address(0), "Address is zero");
        require(_owners[tokenId_] != address(0), "Token ID does not exist");
        _balances[from_] -= 1;
        _balances[to_] += 1;
        _owners[tokenId_] = to_;

        emit Transfer(from_, to_, tokenId_);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public {
        transferFrom(from_, to_, tokenId_);
        require(_checkOnERC721Received(), "Receiver not implemented");
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_) public {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _checkOnERC721Received() private pure returns(bool) {
        return true;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}