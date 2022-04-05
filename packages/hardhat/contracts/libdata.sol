//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Weather {
    function getId(uint256 _locationKey) internal view returns (uint256) {
        if (_locationKey == 197700) {
            return (1);
        }
    }
}
