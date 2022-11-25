// SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.13;

import {ERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721Metadata} from "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Context} from "../lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {Address} from "../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract SoulboundModERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;               // Token name
    string private _symbol;             // Token symbol
    address private _admin;             // Contract operator has privileges to transfer/recover tokens
    string private _baseURI = "";       // BaseURI for token metadata
    mapping(address => uint256) internal _balances;         // Mapping owner address to token count
    mapping(uint256 => address) internal _owners;           // Mapping from token ID to owner address
    mapping(uint256 => address) private _tokenApprovals;                        // Mapping from token ID to approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals;    // Mapping from owner to operator approvals

    constructor(string memory name_, string memory symbol_, address admin_)  {
        _name = name_;
        _symbol = symbol_;
        _admin = admin_;
    }

    // IERC721 Overrides

    function balanceOf(address owner) public view virtual returns(uint256) {
        require(owner != address(0), "SoulboundModERC721: Address zero (0) not valid");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns(address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "SoulboundModERC721: Invalid Token ID - token nonexistant/not minted");
        return owner;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        require(_owners[tokenId] != address(0), "SoulboundModERC721: Token ID does not exist");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
        require(_checkOnERC721Received(from, to, tokenId, data), "SoulboundModERC721: Transfer to non ERC721Receiver (not implemented)");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    function transferFrom(address from, address to, uint256 tokenId) external virtual {        
        require(_owners[tokenId] != address(0), "SoulboundModERC721: Token ID does not exist");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _beforeTokenTransfer(from, to, tokenId, 1);

        _transfer(from, to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual {
        address owner = _ownerOf(tokenId);
        require(to != owner, "SoulboundModERC721: Approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "SoulboundModERC721: Approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator_, bool approved) external {
        _operatorApprovals[msg.sender][operator_] = approved;
        emit ApprovalForAll(msg.sender, operator_, approved);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // IERC165

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // IERC721Metadata

    function name() public view virtual returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : "";
    }

    // SoulboundModERC721

    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    // Internal functions

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        address owner = _ownerOf(tokenId);
        require(_msgSender() == _admin, "SoulboundModERC721: msg.sender is not the admin approved for transfer");
        require(owner == from, "SoulboundModERC721: From address is not the owner of token");
        require(to != address(0), "SoulboundModERC721: Transfer to address zero (0) not allowed");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(owner == from, "SoulboundModERC721: From address is not the owner of token (changed by _beforeTokenTransfer hook");

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(_ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "SoulboundModERC721: Approval called for owner address");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = _ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns(bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval ==     IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("BrightIDSoulbound: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "SoulboundModERC721: Invalid token ID - token has not been minted");
    }
}