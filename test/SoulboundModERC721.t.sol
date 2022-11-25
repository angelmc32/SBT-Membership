// SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/console.sol";

import "../lib/forge-std/src/Test.sol";
import "../src/SoulboundModERC721.sol";

import {Context} from "../lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {Address} from "../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract SoulboundModERC721_Test is Test, Context {
    using Address for address;
    using Strings for uint256;
    SoulboundModERC721 public sbtModERC721;
    address deployerAddress = address(0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
    string private myTokenName = "Soulbound Membership Token";
    string private myTokenSymbol = "SBMBT";

    function setUp() public {
        sbtModERC721 = new SoulboundModERC721(myTokenName, myTokenSymbol, deployerAddress);
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
}