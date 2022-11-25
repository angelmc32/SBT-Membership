// SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.13;

import {SoulboundModERC721} from "./SoulboundModERC721.sol";
import {Context} from "../lib/openzeppelin-contracts/contracts/utils/Context.sol";

contract SoulboundMembershipNFT is SoulboundModERC721 {
    string public _organizationName;

    constructor(string memory organizationName_) SoulboundModERC721("Soulbound Membership Token", "SBMBT", _msgSender()) {
        _organizationName = organizationName_;
    }

    function setOrganizationName(string memory newOrgName) public {
        _organizationName = newOrgName;
    }

    function getOrganizationName() public view returns(string memory){
        return _organizationName;
    }
}
