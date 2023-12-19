// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Atomic {
    struct Video {
        uint id;
        string title;
        string description;
        string url;
        string thumb_url;
        string[] keywords;
        uint duration;
        uint timestamp;
    }

    struct Comment {
        address poster;
        string message;
        uint amount;
        uint timestamp;
    }

    uint private video_counter = 1;
    uint private comment_counter = 1;

    // VW: getOwner
    address payable private owner;

    // TX: setNearID
    // VW: getAddressNearID
    mapping(address => string) internal user_near_id;
    mapping(string => address[]) internal near_reverse_idx;
    mapping(string => mapping(address => bool))
        internal near_reverse_idx_validation;

    // TX: addVideo, deleteVideo, adminDeleteVideo
    // VW: getUserVideosByNearID, getLatestVideos, getVideo
    mapping(address => uint[]) internal user_videos;
    mapping(uint => address) internal video_owner;
    mapping(uint => Video) internal video_data;

    // TX: addComment
    // VW: getComment
    mapping(uint => uint[]) internal video_comments;
    mapping(uint => Comment) internal comment_data;

    // TX: setAttributions
    // VW: getAttributions
    mapping(uint => uint[]) internal video_attributions;
    mapping(uint => mapping(uint => bool))
        internal video_attributions_validation;

    // TX: addAdmin
    // MD: onlyAdmin
    mapping(string => address[]) internal roles;

    modifier onlyOwner() {
        require(msg.sender == owner, "Access Denied");
        _;
    }

    modifier onlyAdmin() {
        bool allow = false;
        for (uint i = 0; i < roles["admin"].length; i++) {
            if (msg.sender == roles["admin"][i]) {
                allow = true;
                break;
            }
        }
        if (msg.sender == owner) {
            allow = true;
        }
        require(allow, "Access Denied");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function addAdmin(address account) public onlyOwner {
        roles["admin"].push(account);
    }

    function addVideo(
        string calldata _title,
        string calldata _description,
        string calldata _url,
        string calldata _thumb_url,
        uint _duration,
        string[] calldata _keywords
    ) public {
        uint video_id = video_counter++;
        video_data[video_id] = Video({
            id: video_id,
            title: _title,
            description: _description,
            keywords: _keywords,
            url: _url,
            thumb_url: _thumb_url,
            duration: _duration,
            timestamp: block.timestamp
        });
        video_owner[video_id] = msg.sender;
        user_videos[msg.sender].push(video_id);
    }

    function deleteVideo(uint video_id) public {
        require(video_owner[video_id] != address(0), "Video must exist.");
        require(
            video_owner[video_id] == msg.sender,
            "You do not own the video."
        );
        _delete_video(video_id);
    }

    function adminDeleteVideo(uint video_id) public onlyAdmin {
        require(video_owner[video_id] != address(0), "Video must exist.");
        _delete_video(video_id);
    }

    function _delete_video(uint video_id) internal {
        video_owner[video_id] = address(0);
        video_data[video_id] = Video({
            id: video_id,
            title: "[Deleted Video]",
            description: "",
            keywords: new string[](0),
            url: "",
            thumb_url: "",
            duration: 0,
            timestamp: block.timestamp
        });
    }

    function getVideo(uint video_id) public view returns (Video memory) {
        require(video_owner[video_id] != address(0), "Video must exist.");
        return video_data[video_id];
    }

    function setAttributions(
        uint video_id,
        uint[] calldata attributions
    ) public {
        require(
            video_owner[video_id] == msg.sender,
            "You do not own the video."
        );
        require(video_owner[video_id] != address(0), "Video must exist.");
        for (uint i = 0; i < attributions.length; i++) {
            _crawl_attribution(video_id, attributions[i]);
        }
    }

    function _crawl_attribution(uint video_id, uint crawl_id) internal {
        if (!video_attributions_validation[video_id][crawl_id]) {
            video_attributions[video_id].push(crawl_id);
            video_attributions_validation[video_id][crawl_id] = true;
        }
        for (uint i = 0; i < video_attributions[crawl_id].length; i++) {
            _crawl_attribution(video_id, video_attributions[crawl_id][i]);
        }
    }

    function addComment(
        uint video_id,
        string calldata comment_message
    ) public payable {
        require(video_owner[video_id] != address(0), "Video must exist.");
        if (msg.value > 0) {
            require(
                video_owner[video_id] != msg.sender,
                "You cannot superchat on your own video"
            );
            uint256 val = (msg.value * 9) / 10;
            (bool sentOwner, ) = owner.call{value: msg.value - val}("");
            require(sentOwner, "Failed to send Ether to owner");
            uint dividends = video_attributions[video_id].length + 1;
            uint256 split_amount = val / dividends;
            for (uint i = 0; i < video_attributions[video_id].length; i++) {
                uint attributed_video_id = video_attributions[video_id][i];
                address creator = video_owner[attributed_video_id];
                (bool sentAttributedCreator, ) = payable(creator).call{
                    value: split_amount
                }("");
                require(
                    sentAttributedCreator,
                    "Failed to send Ether to a creator"
                );
            }
            (bool sentVideoCreator, ) = payable(video_owner[video_id]).call{
                value: val - (split_amount * (dividends - 1))
            }("");
            require(sentVideoCreator, "Failed to send Ether to the creator");
        }
        uint comment_id = comment_counter++;
        comment_data[comment_id] = Comment({
            timestamp: block.timestamp,
            message: comment_message,
            poster: msg.sender,
            amount: msg.value
        });
        video_comments[video_id].push(comment_id);
    }

    function setNearID(string calldata _near_id) public {
        user_near_id[msg.sender] = _near_id;
        if (!near_reverse_idx_validation[_near_id][msg.sender]) {
            near_reverse_idx[_near_id].push(msg.sender);
            near_reverse_idx_validation[_near_id][msg.sender] = true;
        }
    }

    function getVideoByNearID(
        string memory _near_id
    ) public view returns (Video[] memory) {
        uint len = 0;
        for (uint i = 0; i < near_reverse_idx[_near_id].length; i++) {
            len += user_videos[near_reverse_idx[_near_id][i]].length;
        }
        Video[] memory videos = new Video[](len);
        uint count = 0;
        for (uint i = 0; i < near_reverse_idx[_near_id].length; i++) {
            for (
                uint ii = 0;
                ii < user_videos[near_reverse_idx[_near_id][i]].length;
                ii++
            ) {
                videos[count++] = video_data[
                    user_videos[near_reverse_idx[_near_id][i]][ii]
                ];
            }
        }
        return videos;
    }

    function getLatestVideos(uint size) public view returns (Video[] memory) {
        Video[] memory videos = new Video[](
            video_counter > size ? size : video_counter
        );
        for (uint i = 0; i < videos.length; i++) {
            videos[i] = video_data[video_counter - i - 1];
        }
        return videos;
    }

    function getComments(uint video_id) public view returns (Comment[] memory) {
        require(video_owner[video_id] != address(0), "Video must exist.");
        Comment[] memory comments = new Comment[](
            video_comments[video_id].length
        );
        for (uint i = 0; i < video_comments[video_id].length; i++) {
            comments[i] = comment_data[video_comments[video_id][i]];
        }
        return comments;
    }

    function getAttributions(
        uint video_id
    ) public view returns (uint[] memory) {
        require(video_owner[video_id] != address(0), "Video must exist.");
        return video_attributions[video_id];
    }

    function getAddressNearID(
        address addr
    ) public view returns (string memory) {
        return user_near_id[addr];
    }
}



