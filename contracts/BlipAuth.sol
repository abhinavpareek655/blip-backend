// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "hardhat/console.sol";

contract BlipAuth {
    struct User {
        address wallet;
        bytes32 passwordHash;
    }

    mapping(bytes32 => User) public users;

    event UserSignedUp(string email, address wallet);
    event UserLoggedIn(string email, address wallet);

    function signup(string memory email, string memory password) public {
        require(bytes(email).length > 0, "Email is required");
        require(bytes(password).length >= 8, "Password must be at least 8 characters");

        // Use encodePacked for consistency
        bytes32 emailHash = keccak256(abi.encodePacked(email));

        require(users[emailHash].wallet == address(0), "Email already registered");

        users[emailHash] = User({
            wallet: msg.sender,
            passwordHash: keccak256(abi.encodePacked(password))
        });

        emit UserSignedUp(email, msg.sender);

        console.log("[SIGNUP] Email:", email);
        console.log("[SIGNUP] Wallet:", msg.sender);
        console.logBytes32(emailHash);
    }

    function login(string memory email, string memory password) public view returns (bool) {
        // Use encodePacked to match the hashing from signup
        bytes32 emailHash = keccak256(abi.encodePacked(email));

        console.log("[LOGIN] Email:", email);
        console.logBytes32(emailHash);

        if (users[emailHash].wallet == address(0)) {
            console.log("[LOGIN] Email not registered.");
            revert("Email not registered");
        }

        bool isValid = users[emailHash].passwordHash == keccak256(abi.encodePacked(password));
        console.log("[LOGIN] isValid:", isValid);

        return isValid;
    }

    function getWallet(string memory email) public view returns (address) {
        // Use encodePacked for consistency with signup
        bytes32 emailHash = keccak256(abi.encodePacked(email));
        require(users[emailHash].wallet != address(0), "Email not found");
        return users[emailHash].wallet;
    }

    function getUserByEmailHash(bytes32 emailHash) public view returns (address) {
        return users[emailHash].wallet;
    }

}
