// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract BlipAuth {
    struct User {
        address wallet;
        bytes32 passwordHash;
    }

    mapping(string => User) private users; // email => User

    event UserSignedUp(string email, address wallet);
    event UserLoggedIn(string email, address wallet);

    function signup(string memory email, string memory password) public {
        require(bytes(email).length > 0, "Email is required");
        require(bytes(password).length >= 8, "Password must be at least 8 characters");
        require(users[email].wallet == address(0), "Email already registered");

        users[email] = User(msg.sender, keccak256(abi.encodePacked(password)));
        emit UserSignedUp(email, msg.sender);
    }

    function login(string memory email, string memory password) public view returns (bool) {
        require(users[email].wallet != address(0), "Email not registered");

        return users[email].passwordHash == keccak256(abi.encodePacked(password));
    }

    function getWallet(string memory email) public view returns (address) {
        require(users[email].wallet != address(0), "Email not found");
        return users[email].wallet;
    }
}
