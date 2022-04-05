pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./base64.sol";
import "./ChainlinkWeather.sol";

contract SVG is ERC721 {
    using Strings for uint256;
    using Weather for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    AccuweatherConsumer public chainlinkweather;

    constructor(address _ChainlinkWeather) ERC721("Weathary", "WDR") {
        chainlinkweather = AccuweatherConsumer(_ChainlinkWeather);
    }

    function mintItem() public {
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        _safeMint(msg.sender, id);
    }

    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_id), "not exist");

        string memory name = string(
            abi.encodePacked("Weathary", _id.toString())
        );

        uint256 locationkey = Weather.getId(_id);

        // if(result ==0){
        string memory image = Base64.encode(bytes(ZeroSVG()));
        // }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                // '", "description":"',
                                // description,
                                // '", "external_url":"https://burnyboys.com/token/',
                                // id.toString(),
                                // '", "attributes": [{"trait_type": "color", "value": "#',
                                // color[id].toColor(),
                                // '"},{"trait_type": "chubbiness", "value": ',
                                // uint2str(chubbiness[id]),
                                // '}], "owner":"',
                                // (uint160(ownerOf(id))).toHexString(20),
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function getlatestweather(uint256 _id) internal returns (uint8) {
        return chainlinkweather.weatherbyId(_id);
    }

    function ZeroSVG() public view returns (bytes memory) {
        bytes memory svg = abi.encodePacked(
            '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
            renderZeroSVG(),
            "</svg>"
        );
        return svg;
    }

    function renderZeroSVG() public view returns (string memory) {
        string memory ren = string(
            abi.encodePacked(
                '<g id="cir">',
                '<circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" />',
                "</g>"
            )
        );
    }
}
