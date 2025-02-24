// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract ProductContract {
    mapping(address => string[]) private productHashes;

    // Event to notify when a product is added
    event ProductAdded(address indexed user, string productHash);

    // Function to add a product hash
    function addProduct(string memory productHash) public {
        productHashes[msg.sender].push(productHash);
        emit ProductAdded(msg.sender, productHash);
    }

    // Function to get all product hashes for a user
    function getProducts() public view returns (string[] memory) {
        return productHashes[msg.sender];
    }
}
