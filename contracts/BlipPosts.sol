// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract BlipPosts {
    struct Post {
        uint256 id;
        address owner;
        string text;
        string imageHash;
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

    event PostCreated(uint256 indexed postId, address indexed owner, string text, string imageHash, bool isPublic);
    event PostLiked(uint256 indexed postId, address indexed user);
    event CommentAdded(uint256 indexed postId, address indexed user, string comment);
    event PostShared(uint256 indexed postId, address indexed user);

    // Create a post
    function createPost(string memory text, string memory imageHash, bool isPublic) public {
        require(bytes(text).length > 0 || bytes(imageHash).length > 0, "Post content required");

        uint256 postId = ++postIdCounter;

        posts[postId] = Post({
            id: postId,
            owner: msg.sender,
            text: text,
            imageHash: imageHash,
            isPublic: isPublic,
            timestamp: block.timestamp,
            likeCount: 0,
            shareCount: 0
        });

        userPosts[msg.sender].push(postId);

        emit PostCreated(postId, msg.sender, text, imageHash, isPublic);
    }

    // Like a post
    function likePost(uint256 postId) public {
        require(postId > 0 && postId <= postIdCounter, "Invalid post ID");

        address[] storage likes = postLikes[postId];
        for (uint i = 0; i < likes.length; i++) {
            require(likes[i] != msg.sender, "Already liked");
        }

        likes.push(msg.sender);
        posts[postId].likeCount += 1;

        emit PostLiked(postId, msg.sender);
    }

    // Add comment
    function commentOnPost(uint256 postId, string memory comment) public {
        require(bytes(comment).length > 0, "Comment required");
        require(postId > 0 && postId <= postIdCounter, "Invalid post ID");

        postComments[postId].push(Comment({
            commenter: msg.sender,
            text: comment,
            timestamp: block.timestamp
        }));

        emit CommentAdded(postId, msg.sender, comment);
    }

    // Share post (increment counter only)
    function sharePost(uint256 postId) public {
        require(postId > 0 && postId <= postIdCounter, "Invalid post ID");
        posts[postId].shareCount += 1;

        emit PostShared(postId, msg.sender);
    }

    // Get post IDs for user
    function getUserPosts(address user) public view returns (uint256[] memory) {
        return userPosts[user];
    }

    // Get comments on a post
    function getComments(uint256 postId) public view returns (Comment[] memory) {
        return postComments[postId];
    }

    // Get likes on a post
    function getLikes(uint256 postId) public view returns (address[] memory) {
        return postLikes[postId];
    }
}
