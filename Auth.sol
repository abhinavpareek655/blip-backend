// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auth {
    struct User {
        string email;
        address userAddress;
    }

    mapping(address => User) public users;

    event UserRegistered(string email, address userAddress);

    // Signup function
    function signup(string memory _email) public {
        require(bytes(users[msg.sender].email).length == 0, "User already exists");
        users[msg.sender] = User(_email, msg.sender);
        emit UserRegistered(_email, msg.sender);
    }

    // Login (Checks if user exists)
    function login() public view returns (string memory) {
        require(bytes(users[msg.sender].email).length != 0, "User not registered");
        return users[msg.sender].email;
    }

    // Check if user exists
    function isUserRegistered(address _userAddress) public view returns (bool) {
        return bytes(users[_userAddress].email).length > 0;
    }
}
