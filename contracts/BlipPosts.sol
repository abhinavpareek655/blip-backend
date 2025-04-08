// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract BlipPosts {
    struct Post {
        uint256 id;
        address owner;
        string text;
        bool isPublic;
        uint256 timestamp;
        uint256 likeCount;
        uint256 shareCount;
    }

    struct Comment {
        address commenter;
        string text;
        uint256 timestamp;
    }

    uint256 private postIdCounter;
    mapping(uint256 => Post) public posts;
    mapping(address => uint256[]) public userPosts;

    mapping(uint256 => address[]) public postLikes;
    mapping(uint256 => Comment[]) public postComments;

    event PostCreated(uint256 indexed postId, address indexed owner, string text, bool isPublic);
    event PostLiked(uint256 indexed postId, address indexed user);
    event CommentAdded(uint256 indexed postId, address indexed user, string comment);
    event PostShared(uint256 indexed postId, address indexed user);

    modifier validPost(uint256 postId) {
        require(postId > 0 && postId <= postIdCounter, "Invalid post ID");
        _;
    }

    // Create a text-only post
    function createPost(string memory text, bool isPublic) public {
        require(bytes(text).length > 0, "Post text required");

        uint256 postId = ++postIdCounter;

        posts[postId] = Post({
            id: postId,
            owner: msg.sender,
            text: text,
            isPublic: isPublic,
            timestamp: block.timestamp,
            likeCount: 0,
            shareCount: 0
        });

        userPosts[msg.sender].push(postId);

        emit PostCreated(postId, msg.sender, text, isPublic);
    }

    function likePost(uint256 postId) public validPost(postId) {
        address[] storage likes = postLikes[postId];
        for (uint i = 0; i < likes.length; i++) {
            require(likes[i] != msg.sender, "Already liked");
        }

        likes.push(msg.sender);
        posts[postId].likeCount++;

        emit PostLiked(postId, msg.sender);
    }

    function commentOnPost(uint256 postId, string memory comment) public validPost(postId) {
        require(bytes(comment).length > 0, "Comment required");

        postComments[postId].push(Comment({
            commenter: msg.sender,
            text: comment,
            timestamp: block.timestamp
        }));

        emit CommentAdded(postId, msg.sender, comment);
    }

    function sharePost(uint256 postId) public validPost(postId) {
        posts[postId].shareCount++;
        emit PostShared(postId, msg.sender);
    }

    function getUserPosts(address user) public view returns (uint256[] memory) {
        return userPosts[user];
    }

    function getComments(uint256 postId) public view validPost(postId) returns (Comment[] memory) {
        return postComments[postId];
    }

    function getLikes(uint256 postId) public view validPost(postId) returns (address[] memory) {
        return postLikes[postId];
    }
}
