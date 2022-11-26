// SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/console.sol";

import "../lib/forge-std/src/Test.sol";
import "../src/SoulboundModERC721.sol";
import {IERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

import {Context} from "../lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {Address} from "../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract SoulboundModERC721_Test is Test, Context {
    using Address for address;
    using Strings for uint256;

    SoulboundModERC721 public sbtModERC721;

    address deployerAddress = address(0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
    address ALICE_ADD = address(0x1);
    address BOB_ADD = address(0x2);
    address CHARLIE_ADD = address(0x3);

    string private myTokenName = "Soulbound Membership Token";
    string private myTokenSymbol = "SBMBT";

    function setUp() public {
        sbtModERC721 = new SoulboundModERC721(myTokenName, myTokenSymbol, deployerAddress);
    }

    function mintMultiple(uint quantity) internal {
        for(uint i = 1; i <= quantity; i++) {
            if(i % 3 == 1) {
                sbtModERC721.safeMint(ALICE_ADD, i);
            }
            if(i % 3 == 2) {
                sbtModERC721.safeMint(BOB_ADD, i);
            }
            if(i % 3 == 0) {
                sbtModERC721.safeMint(CHARLIE_ADD, i);
            }
        }
    }

    function testGetBalanceOf() public {
        mintMultiple(5);
        uint aliceBalance = sbtModERC721.balanceOf(ALICE_ADD);
        uint bobBalance = sbtModERC721.balanceOf(BOB_ADD);
        uint charlieBalance = sbtModERC721.balanceOf(CHARLIE_ADD);

        assertEq(aliceBalance, 2);
        assertEq(bobBalance, 2);
        assertEq(charlieBalance, 1);
    }

    function testGetOwnerOf() public {
        mintMultiple(5);
        address ownerOf_tokenId_1 = sbtModERC721.ownerOf(1);
        address ownerOf_tokenId_2 = sbtModERC721.ownerOf(2);
        address ownerOf_tokenId_3 = sbtModERC721.ownerOf(3);
        address ownerOf_tokenId_4 = sbtModERC721.ownerOf(4);
        address ownerOf_tokenId_5 = sbtModERC721.ownerOf(5);

        assertEq(ownerOf_tokenId_1, ownerOf_tokenId_4);
        assertEq(ownerOf_tokenId_2, ownerOf_tokenId_5);
        assertFalse(ownerOf_tokenId_1 == ownerOf_tokenId_3);
    }

    function testCannotSafeTransferFromNotAdminAddress() public {
        sbtModERC721.safeMint(ALICE_ADD, 1);
        vm.startPrank(ALICE_ADD);
        vm.expectRevert("SoulboundModERC721: msg.sender is not the admin approved for transfer");
        sbtModERC721.safeTransferFrom(ALICE_ADD, BOB_ADD, 1);
        vm.stopPrank();
    }

    function testSafeTransferFromAdminAddress() public {
        sbtModERC721.safeMint(ALICE_ADD, 1);
        sbtModERC721.safeTransferFrom(ALICE_ADD, BOB_ADD, 1);
        assertEq(sbtModERC721.balanceOf(ALICE_ADD), 0);
        assertEq(sbtModERC721.balanceOf(BOB_ADD), 1);
        assertEq(sbtModERC721.ownerOf(1), BOB_ADD);
    }

    function testCannotTransferFromNotAdminAddress() public {
        sbtModERC721.safeMint(ALICE_ADD, 1);
        vm.startPrank(ALICE_ADD);
        vm.expectRevert("SoulboundModERC721: msg.sender is not the admin approved for transfer");
        sbtModERC721.transferFrom(ALICE_ADD, BOB_ADD, 1);
        vm.stopPrank();
    }

    function testTransferFromAdminAddress() public {
        sbtModERC721.safeMint(ALICE_ADD, 1);
        sbtModERC721.transferFrom(ALICE_ADD, BOB_ADD, 1);
        assertEq(sbtModERC721.balanceOf(ALICE_ADD), 0);
        assertEq(sbtModERC721.balanceOf(BOB_ADD), 1);
        assertEq(sbtModERC721.ownerOf(1), BOB_ADD);
    }

    function testCannotApproveUsingNotAdminAddress() public {
        sbtModERC721.safeMint(ALICE_ADD, 1);
        vm.startPrank(ALICE_ADD);
        vm.expectRevert("SoulboundModERC721: msg.sender is not the admin approved for transfer");
        sbtModERC721.approve(BOB_ADD, 1);
        vm.stopPrank();
    }

    function testCannotApproveOwnerAddress() public {
        sbtModERC721.safeMint(ALICE_ADD, 1);
        vm.expectRevert("SoulboundModERC721: Approval to current owner is not allowed");
        sbtModERC721.approve(ALICE_ADD, 1);
    }

    function testCannotApproveForNonExistentToken() public {
        sbtModERC721.safeMint(ALICE_ADD, 1);
        vm.expectRevert("SoulboundModERC721: Token ID does not exist");
        sbtModERC721.approve(ALICE_ADD, 2);
    }

    function testApproveUsingAdminAddress() public {
        sbtModERC721.safeMint(ALICE_ADD, 1);
        sbtModERC721.approve(BOB_ADD, 1);
        assertEq(sbtModERC721.getApproved(1), BOB_ADD);
    }

    function testCannotGetApprovedForNonExistentToken() public {
        sbtModERC721.safeMint(ALICE_ADD, 1);
        vm.expectRevert("SoulboundModERC721: Invalid token ID - token has not been minted");
        sbtModERC721.getApproved(2);
    }

    function testGetApproved() public {
        mintMultiple(3);
        sbtModERC721.approve(deployerAddress, 2);
        assertEq(sbtModERC721.getApproved(2), deployerAddress);
    }

    function testCannotSetApprovalForAllToOwnerAddress() public {
        sbtModERC721.safeMint(ALICE_ADD, 1);
        vm.startPrank(ALICE_ADD);
        vm.expectRevert("SoulboundModERC721: Approval called for owner address");
        sbtModERC721.setApprovalForAll(ALICE_ADD, true);
        vm.stopPrank();
    }

    function testCannotSetApprovalForAllToNotAdminAddress() public {
        sbtModERC721.safeMint(ALICE_ADD, 1);
        vm.startPrank(ALICE_ADD);
        vm.expectRevert("SoulboundModERC721: Only admin of contract can be approved for all");
        sbtModERC721.setApprovalForAll(BOB_ADD, true);
        vm.stopPrank();
    }

    function testSetApprovalForAllToAdminAddress() public {
        sbtModERC721.safeMint(ALICE_ADD, 1);
        vm.startPrank(ALICE_ADD);
        sbtModERC721.setApprovalForAll(deployerAddress, true);
        vm.stopPrank();
        assertTrue(sbtModERC721.isApprovedForAll(ALICE_ADD, deployerAddress));
    }

    function testCannotGetIsApprovedForAll() public {
        assertFalse(sbtModERC721.isApprovedForAll(ALICE_ADD, deployerAddress));
    }

    function testGetIsApprovedForAll() public {
        mintMultiple(5);
        vm.startPrank(CHARLIE_ADD);
        sbtModERC721.setApprovalForAll(deployerAddress, true);
        vm.stopPrank();
        assertFalse(sbtModERC721.isApprovedForAll(ALICE_ADD, deployerAddress));
        assertFalse(sbtModERC721.isApprovedForAll(BOB_ADD, deployerAddress));
        assertTrue(sbtModERC721.isApprovedForAll(CHARLIE_ADD, deployerAddress));
    }

    function testSupportsInterfaces() public {
        assertTrue(sbtModERC721.supportsInterface(0x01ffc9a7));     // IERC165
        assertTrue(sbtModERC721.supportsInterface(0x80ac58cd));     // IERC721
        assertTrue(sbtModERC721.supportsInterface(0x5b5e139f));     // IERC721Metadata
        assertFalse(sbtModERC721.supportsInterface(0xffffffff));    // Invalid interface
    }

    function testOnERC721Received() public {
        bytes4 retValue = sbtModERC721.onERC721Received(deployerAddress, BOB_ADD, 1, "");
        // console.log(retValue);
        assertTrue(retValue == 0x80ac58cd);
    }

    function testGetTokenName() public {
        string memory tokenName = sbtModERC721.name();
        assertEq(tokenName, myTokenName);
    }

    function testGetTokenSymbol() public {
        string memory tokenSymbol = sbtModERC721.symbol();
        assertEq(tokenSymbol, myTokenSymbol);
    }

    function testGetAdminAddress() public {
        address adminAddress = sbtModERC721.admin();
        assertEq(adminAddress, deployerAddress);
    }

    function testGetBaseURI() public {
        assertEq(sbtModERC721.baseURI(), "");
    }

    function testCannotGetTokenURIFromNonExistentToken() public {
        vm.expectRevert("SoulboundModERC721: Invalid token ID - token has not been minted");
        assertEq(sbtModERC721.tokenURI(1), "");
    }

    function testGetTokenURI() public {
        sbtModERC721.safeMint(ALICE_ADD, 1);
        assertEq(sbtModERC721.tokenURI(1), "");
    }

    function testSafeMint() public {
        vm.startPrank(ALICE_ADD);
        sbtModERC721.safeMint(ALICE_ADD, 1);
        vm.stopPrank();
        assertEq(sbtModERC721.ownerOf(1), ALICE_ADD);
    }

    function testMint() public {
        vm.startPrank(ALICE_ADD);
        sbtModERC721.mint(ALICE_ADD, 1);
        vm.stopPrank();
        assertEq(sbtModERC721.ownerOf(1), ALICE_ADD);
    }
}