// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract BlipProfile {
    struct Profile {
        string name;
        string email;
        string avatar;
        string bio;
        uint256 createdAt;
        address wallet;
        address[] posts;
        address[] blippers; // followers
        address[] bliping;  // following
        mapping(address => bool) isBlipping; // fast lookup for unfollow
    }

    mapping(address => Profile) private profiles;

    event ProfileCreated(address indexed user, string name, string email);
    event AvatarUpdated(address indexed user, string avatar);
    event BioUpdated(address indexed user, string bio);
    event Blipped(address indexed by, address indexed to);
    event Unblipped(address indexed by, address indexed to);
    event PostAdded(address indexed user, address postContract);
    event NameUpdated(address indexed user, string newName);

    modifier onlyUser() {
        require(msg.sender == tx.origin, "No contracts allowed");
        _;
    }

    modifier profileExists(address user) {
        require(profiles[user].createdAt != 0, "Profile doesn't exist");
        _;
    }

    function createProfile(
        string memory name,
        string memory email,
        string memory avatar,
        string memory bio
    ) public onlyUser {
        require(profiles[msg.sender].createdAt == 0, "Profile already exists");

        address[] memory empty;

        Profile storage p = profiles[msg.sender];
        p.name = name;
        p.email = email;
        p.avatar = avatar;
        p.bio = bio;
        p.wallet = msg.sender;
        p.createdAt = block.timestamp;
        p.posts = empty;
        p.blippers = empty;
        p.bliping = empty;

        emit ProfileCreated(msg.sender, name, email);
    }

    function blip(address userToBlip) public profileExists(msg.sender) profileExists(userToBlip) {
        require(userToBlip != msg.sender, "Cannot blip yourself");
        require(!profiles[msg.sender].isBlipping[userToBlip], "Already blipping this user");

        profiles[msg.sender].bliping.push(userToBlip);
        profiles[userToBlip].blippers.push(msg.sender);
        profiles[msg.sender].isBlipping[userToBlip] = true;

        emit Blipped(msg.sender, userToBlip);
    }

    function unblip(address userToUnblip) public profileExists(msg.sender) profileExists(userToUnblip) {
        require(profiles[msg.sender].isBlipping[userToUnblip], "Not blipping this user");

        _removeFromArray(profiles[msg.sender].bliping, userToUnblip);
        _removeFromArray(profiles[userToUnblip].blippers, msg.sender);
        profiles[msg.sender].isBlipping[userToUnblip] = false;

        emit Unblipped(msg.sender, userToUnblip);
    }

    function addPost(address postAddress) public profileExists(msg.sender) {
        profiles[msg.sender].posts.push(postAddress);
        emit PostAdded(msg.sender, postAddress);
    }

    function getProfile(address user) public view returns (
        string memory name,
        string memory email,
        string memory avatar,
        string memory bio,
        address wallet,
        uint256 createdAt,
        address[] memory posts,
        address[] memory blippers,
        address[] memory bliping
    ) {
        Profile storage p = profiles[user];
        return (p.name, p.email, p.avatar, p.bio, p.wallet, p.createdAt, p.posts, p.blippers, p.bliping);
    }

    function _removeFromArray(address[] storage array, address addr) internal {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; ++i) {
            if (array[i] == addr) {
                array[i] = array[length - 1];
                array.pop();
                break;
            }
        }
    }

    function isUserBlipping(address from, address to) public view returns (bool) {
        return profiles[from].isBlipping[to];
    }

    function profileExistsFor(address user) public view returns (bool) {
        return profiles[user].createdAt != 0;
    }

    function updateName(string memory newName) public {
        require(profiles[msg.sender].createdAt != 0, "Profile doesn't exist");
        profiles[msg.sender].name = newName;
        emit NameUpdated(msg.sender, newName);
    }

    function updateAvatar(string memory newAvatar) public {
        require(profiles[msg.sender].createdAt != 0, "Profile doesn't exist");
        profiles[msg.sender].avatar = newAvatar;
        emit AvatarUpdated(msg.sender, newAvatar);
    }

    function updateBio(string memory newBio) public {
        require(profiles[msg.sender].createdAt != 0, "Profile doesn't exist");
        profiles[msg.sender].bio = newBio;
        emit BioUpdated(msg.sender, newBio);
    }
}
