pragma solidity ^0.8.0;

interface ILand {
    function mint(address _recipient, uint256 _tokenId)
        external
        returns (uint256 tokenId);
}
