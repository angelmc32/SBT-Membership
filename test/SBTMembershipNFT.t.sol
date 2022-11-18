// SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../src/SBTMembershipNFT.sol";

contract SBTMembershipTest is Test {
    SoulboundMembershipNFT public sbtMembershipNft;

    string myOrgName = "My Organization";
    string newOrgName = "New Organization";

    function setUp() public {
        sbtMembershipNft = new SoulboundMembershipNFT();
        sbtMembershipNft.setOrganizationName(myOrgName);
    }

    function testGetOrgName() public {
        string memory membershipOrgName = sbtMembershipNft.getOrganizationName();
        assertEq(membershipOrgName, myOrgName);
    }

    function testSetOrgName() public {
        sbtMembershipNft.setOrganizationName(newOrgName);
        string memory membershipOrgName = sbtMembershipNft.getOrganizationName();
        assertFalse(keccak256(bytes(membershipOrgName)) == keccak256(bytes(myOrgName)));
    }
}
