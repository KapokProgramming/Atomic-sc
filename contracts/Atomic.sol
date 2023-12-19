// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Atomic {
    struct VideoAdd {
        string _title;
        string _description;
        string _url;
        string _thumb_url;
        uint _duration;
        string[] _keywords;
    }

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

    struct VideoWithNearID {
        Video video;
        string near_id;
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
    // VW: getUserVideosByNearID, getLatestVideos, getVideo, getVideosByTerm
    mapping(address => uint[]) internal user_videos;
    mapping(uint => address) internal video_owner;
    mapping(uint => Video) internal video_data;
    mapping(string => uint[]) internal term_video_idx;
    mapping(string => mapping(uint => bool)) internal term_video_idx_validation;

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
        VideoAdd calldata _video_add,
        uint[] calldata _attributions,
        string calldata _near_id
    ) public {
        uint video_id = video_counter++;
        video_data[video_id] = Video({
            id: video_id,
            title: _video_add._title,
            description: _video_add._description,
            keywords: _video_add._keywords,
            url: _video_add._url,
            thumb_url: _video_add._thumb_url,
            duration: _video_add._duration,
            timestamp: block.timestamp
        });
        video_owner[video_id] = msg.sender;
        user_videos[msg.sender].push(video_id);
        addTags(video_id, _video_add._keywords);
        if (_attributions.length > 0) {
            setAttributions(video_id, _attributions);
        }
        if (bytes(_near_id).length != 0) {
            _set_near_id(msg.sender, _near_id);
        }
    }

    function addTags(uint _video_id, string[] calldata _keywords) internal {
        for (uint i = 0; i < _keywords.length; i++) {
            if (!term_video_idx_validation[_keywords[i]][_video_id]) {
                term_video_idx[_keywords[i]].push(_video_id);
                term_video_idx_validation[_keywords[i]][_video_id] = true;
            }
        }
    }

    function deleteVideo(uint _video_id) public {
        require(video_owner[_video_id] != address(0), "Video must exist.");
        require(
            video_owner[_video_id] == msg.sender,
            "You do not own the video."
        );
        _delete_video(_video_id);
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

    function _to_video_with_near_id(
        Video memory _video
    ) internal view returns (VideoWithNearID memory) {
        return
            VideoWithNearID({
                video: _video,
                near_id: user_near_id[video_owner[_video.id]]
            });
    }

    function getVideo(
        uint video_id
    ) public view returns (VideoWithNearID memory) {
        require(video_owner[video_id] != address(0), "Video must exist.");
        return _to_video_with_near_id(video_data[video_id]);
    }

    function getVideosByTerm(
        string[] memory terms
    ) public view returns (VideoWithNearID[] memory) {
        uint len = 0;
        for (uint i = 0; i < terms.length; i++) {
            len += term_video_idx[terms[i]].length;
        }
        VideoWithNearID[] memory videos = new VideoWithNearID[](len);
        uint count = 0;
        for (uint i = 0; i < terms.length; i++) {
            for (uint ii = 0; ii < term_video_idx[terms[i]].length; ii++) {
                videos[count++] = _to_video_with_near_id(
                    video_data[term_video_idx[terms[i]][ii]]
                );
            }
        }
        return videos;
    }

    function setAttributions(
        uint video_id,
        uint[] memory attributions
    ) internal {
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
        _set_near_id(msg.sender, _near_id);
    }

    function _set_near_id(address _addr, string memory _near_id) internal {
        user_near_id[_addr] = _near_id;
        if (!near_reverse_idx_validation[_near_id][_addr]) {
            near_reverse_idx[_near_id].push(_addr);
            near_reverse_idx_validation[_near_id][_addr] = true;
        }
    }

    function getVideoByNearID(
        string memory _near_id
    ) public view returns (VideoWithNearID[] memory) {
        uint len = 0;
        for (uint i = 0; i < near_reverse_idx[_near_id].length; i++) {
            len += user_videos[near_reverse_idx[_near_id][i]].length;
        }
        VideoWithNearID[] memory videos = new VideoWithNearID[](len);
        uint count = 0;
        for (uint i = 0; i < near_reverse_idx[_near_id].length; i++) {
            for (
                uint ii = 0;
                ii < user_videos[near_reverse_idx[_near_id][i]].length;
                ii++
            ) {
                videos[count++] = _to_video_with_near_id(
                    video_data[user_videos[near_reverse_idx[_near_id][i]][ii]]
                );
            }
        }
        return videos;
    }

    function getLatestVideos(
        uint size
    ) public view returns (VideoWithNearID[] memory) {
        VideoWithNearID[] memory videos = new VideoWithNearID[](
            video_counter - 1 > size ? size : video_counter - 1
        );
        for (uint i = 0; i < videos.length; i++) {
            videos[i] = _to_video_with_near_id(
                video_data[video_counter - i - 1]
            );
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
