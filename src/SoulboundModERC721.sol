// SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.13;

import {SBT_IERC721} from "./SBT_IERC721.sol";
import {ERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721Metadata} from "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Context} from "../lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {Address} from "../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract SoulboundModERC721 is Context, SBT_IERC721 {
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

    // IERC721 functions implementation

    function balanceOf(address owner) public view virtual override returns(uint256) {
        require(owner != address(0), "SoulboundModERC721: Address zero (0) not valid");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns(address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "SoulboundModERC721: Invalid Token ID - token nonexistant/not minted");
        return owner;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_owners[tokenId] != address(0), "SoulboundModERC721: Token ID does not exist");
        _safeTransfer(from, to, tokenId, data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    function transferFrom(address from, address to, uint256 tokenId) external virtual override {        
        require(_owners[tokenId] != address(0), "SoulboundModERC721: Token ID does not exist");

        _beforeTokenTransfer(from, to, tokenId, 1);

        _transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // IERC165 functions implementation

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    // IERC721Metadata functions implementation

    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : "";
    }

    function safeMint(address to, uint256 tokenId) external virtual {

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        _safeMint(to, tokenId);
    }

    function mint(address to, uint256 tokenId) external virtual {

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        _mint(to, tokenId);
    }

    // IERC721Receiver function implementation
    
    function onERC721Received(
        address operator, 
        address from, 
        uint256 tokenId, 
        bytes calldata data) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    } 

    // SoulboundModERC721 proposed functions implementation

    function baseURI() public view virtual override returns (string memory) {
        return _baseURI;
    }

    function admin() public view virtual override returns (address) {
        return _admin;
    }

    // Internal functions, called by the implemented functions from different interfaces

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "SoulboundModERC721: Transfer to non ERC721Receiver implementer");
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "SoulboundModERC721: Transfer to non ERC721Receiver implementer"
        );
    }

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
        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];
        
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

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "SoulboundModERC721: Mint to the zero address");
        require(!_exists(tokenId), "ERCSoulboundModERC721721: Token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "SoulboundModERC721: Token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = _ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);
        require(_owners[tokenId] != address(0), "SoulboundModERC721: Token ID does not exist");
        require(to != owner, "SoulboundModERC721: Approval to current owner is not allowed");
        require(_msgSender() == _admin, "SoulboundModERC721: msg.sender is not the admin approved for transfer");

        _tokenApprovals[tokenId] = to;
        
        emit Approval(_ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "SoulboundModERC721: Approval called for owner address");
        require(operator == _admin, "SoulboundModERC721: Only admin of contract can be approved for all");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns(bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval ==     IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("SoulboundModERC721: Transfer to non ERC721Receiver implementer");
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

    // Utility functions

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = _ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }
    
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "SoulboundModERC721: Invalid token ID - token has not been minted");
    }
}