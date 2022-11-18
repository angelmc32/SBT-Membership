// SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.13;

contract SoulboundMembershipNFT {
    string public organizationName;

    function setOrganizationName(string memory newOrgName) public {
        organizationName = newOrgName;
    }

    function getOrganizationName() public view returns(string memory){
        return organizationName;
    }
}
