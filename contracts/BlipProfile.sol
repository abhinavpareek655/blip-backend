// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract BlipProfile {
    address public admin;

    struct Post {
        string text;
        address owner;
        uint256 timestamp;
        bool isPublic;
    }

    struct Profile {
        string name;
        string email;
        string bio;
        uint256 createdAt;
        address wallet;
        Post[] posts;
        mapping(address => bool) friends;
        address[] friendList;
    }

    mapping(address => Profile) private profiles;
    mapping(string => address) private emailToWallet;
    mapping(address => address[]) private incomingRequests;
    mapping(address => mapping(address => bool)) private hasRequest;
    mapping(address => address[]) private sentRequests;

    Post[] public adminPosts;

    event FriendAdded(address indexed by, address indexed newFriend);
    event FriendRemoved(address indexed by, address indexed exFriend);
    event BioUpdated(address indexed user, string newBio);
    event NameUpdated(address indexed user, string newName);
    event PostAdded(address indexed user, string text, bool isPublic);
    event AdminPostAdded(string text);
    event FriendRequestSent(address indexed from, address indexed to);
    event FriendRequestAccepted(address indexed from, address indexed to);
    event FriendRequestRejected(address indexed from, address indexed to);

    modifier profileExists(address user) {
        require(profiles[user].createdAt != 0, "Profile doesn't exist");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor() {
        admin = msg.sender; // deployer is admin
    }

    function createProfile(string memory name, string memory email, string memory bio) public {
        require(profiles[msg.sender].createdAt == 0, "Profile already exists");

        profiles[msg.sender].name = name;
        profiles[msg.sender].email = email;
        profiles[msg.sender].bio = bio;
        profiles[msg.sender].wallet = msg.sender;
        profiles[msg.sender].createdAt = block.timestamp;

        emailToWallet[email] = msg.sender;
    }

    function getProfile(address user) public view profileExists(user) returns (
        string memory name,
        string memory email,
        string memory bio,
        address wallet,
        uint256 createdAt,
        Post[] memory posts
    ) {
        Profile storage p = profiles[user];
        return (p.name, p.email, p.bio, p.wallet, p.createdAt, p.posts);
    }

    function getProfileByEmail(string memory email) public view returns (
        string memory name,
        string memory emailOut,
        string memory bio,
        address wallet,
        uint256 createdAt,
        Post[] memory posts
    ) {
        address user = emailToWallet[email];
        require(user != address(0), "Email not registered");
        Profile storage p = profiles[user];
        return (p.name, p.email, p.bio, p.wallet, p.createdAt, p.posts);
    }

    function getWalletByEmail(string memory email) public view returns (address) {
        return emailToWallet[email];
    }

    function emailExists(string memory email) public view returns (bool) {
        return emailToWallet[email] != address(0);
    }

    function sendFriendRequest(address to) 
        public 
        profileExists(msg.sender) 
        profileExists(to) 
    {
        require(msg.sender != to, "Cannot friend yourself");
        require(!profiles[msg.sender].friends[to], "Already friends");
        require(!hasRequest[msg.sender][to], "Request already sent");

        incomingRequests[to].push(msg.sender);
        hasRequest[msg.sender][to] = true;
        sentRequests[msg.sender].push(to);
        emit FriendRequestSent(msg.sender, to);
    }

    function listFriendRequests() 
        public 
        view 
        profileExists(msg.sender) 
        returns (address[] memory) 
    {
        return incomingRequests[msg.sender];
    }

    function listSentRequests(address user)
        public
        view
        profileExists(user)
        returns (address[] memory)
    {
        return sentRequests[user];
    }

    function _removePending(address from, address to) internal {
        address[] storage reqs = incomingRequests[to];
        for (uint i = 0; i < reqs.length; i++) {
            if (reqs[i] == from) {
                reqs[i] = reqs[reqs.length - 1];
                reqs.pop();
                break;
            }
        }
    }

    function acceptFriendRequest(address from) 
        public 
        profileExists(msg.sender) 
        profileExists(from) 
    {
        require(hasRequest[from][msg.sender], "No request from this user");
        // remove from pending list
        _removePending(from, msg.sender);
        hasRequest[from][msg.sender] = false;

        // now add as friends
        profiles[msg.sender].friends[from] = true;
        profiles[msg.sender].friendList.push(from);
        profiles[from].friends[msg.sender] = true;
        profiles[from].friendList.push(msg.sender);

        emit FriendRequestAccepted(from, msg.sender);
    }

    function addFriend(address newFriend) public profileExists(msg.sender) profileExists(newFriend) {
        require(!profiles[msg.sender].friends[newFriend], "Already friends");

        profiles[msg.sender].friends[newFriend] = true;
        profiles[msg.sender].friendList.push(newFriend);

        profiles[newFriend].friends[msg.sender] = true;
        profiles[newFriend].friendList.push(msg.sender);

        emit FriendAdded(msg.sender, newFriend);
    }

    function rejectFriendRequest(address from) 
        public 
        profileExists(msg.sender) 
    {
        require(hasRequest[from][msg.sender], "No request from this user");
        _removePending(from, msg.sender);
        hasRequest[from][msg.sender] = false;
        emit FriendRequestRejected(from, msg.sender);
    }

   

    function removeFriend(address exFriend) public profileExists(msg.sender) profileExists(exFriend) {
        require(profiles[msg.sender].friends[exFriend], "Not friends");

        profiles[msg.sender].friends[exFriend] = false;
        profiles[exFriend].friends[msg.sender] = false;

        emit FriendRemoved(msg.sender, exFriend);
    }

    function getFriends(address user) public view profileExists(user) returns (address[] memory) {
        return profiles[user].friendList;
    }

    function isFriend(address user1, address user2) public view returns (bool) {
        return profiles[user1].friends[user2];
    }

    function updateBio(string memory newBio) public profileExists(msg.sender) {
        profiles[msg.sender].bio = newBio;
        emit BioUpdated(msg.sender, newBio);
    }

    function updateName(string memory newName) public profileExists(msg.sender) {
        profiles[msg.sender].name = newName;
        emit NameUpdated(msg.sender, newName);
    }

    function addPost(string memory text, bool isPublic) public profileExists(msg.sender) {
        require(profiles[msg.sender].createdAt != 0, "Profile doesn't exist");

        Post memory newPost = Post({
            text: text,
            owner: msg.sender,
            timestamp: block.timestamp,
            isPublic: isPublic
        });

        profiles[msg.sender].posts.push(newPost);
        emit PostAdded(msg.sender, text, isPublic);

        if (isPublic) {
            adminPosts.push(newPost);
            emit AdminPostAdded(text);
        }
    }

    function getAdminPosts() public view returns (Post[] memory) {
        return adminPosts;
    }

    function getPosts(address user) public view profileExists(user) returns (Post[] memory) {
        return profiles[user].posts;
    }
}
