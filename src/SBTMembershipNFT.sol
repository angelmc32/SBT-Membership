// SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.13;

import {IERC721Receiver} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {SoulboundModERC721} from "./SoulboundModERC721.sol";

contract SoulboundMembershipNFT is IERC721Receiver {
    string public _organizationName;

    function setOrganizationName(string memory newOrgName) public {
        _organizationName = newOrgName;
    }

    function getOrganizationName() public view returns(string memory){
        return _organizationName;
    }
    
    function onERC721Received(
        address operator_,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external virtual returns (bytes4) {}
}
