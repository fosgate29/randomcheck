// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

struct Epoch {
    uint128 randomness;
    uint64 revealBlock;
    bool committed;
    bool revealed;
}

struct CommitRevealEpoch {
    uint64 revealBlock;
    uint256 salty;
    uint256 seed;
}


// ERC1155 using random ways to mint
// 1. A simple and basic using block.number as a random source 
// 2. Commit which block number will be revealled the random source. It is block.number + 5
contract RandomCheck is ERC1155 {

    uint256 public epochIndex = 1;
    mapping(uint256 => Epoch) public epochs;

    mapping(address => CommitRevealEpoch) public commitRevealEpochs;

    constructor(string memory uri_)ERC1155(uri_) {
    }

    // Normal mint
    function mint() external {
        uint256 id = 1;
        uint256 amount = 10;
        _mint(msg.sender, id, amount, "" );
    }

    // Using a random simple logic
    function randomMint() external {
        uint256 id = randomness(10, 8783, block.number);
        uint256 amount = randomness(1000, 8783, block.number);
        _mint(msg.sender, id, amount, "" );
    }

    // Id of the ERC1155 token is going to be a random number between 1 and 10 using CommitReveal
    // Here is commit
    function randomCommitRevealMint1stStep() external {
        CommitRevealEpoch storage commitRevealEpoch = commitRevealEpochs[msg.sender];
        commitRevealEpoch.revealBlock = uint64(block.number + 5);
        commitRevealEpoch.salty = randomness(90000000000, 365355645, block.number);
        commitRevealEpoch.seed = randomness(10000000000, commitRevealEpoch.salty, block.number);
    }

    // Id of the ERC1155 token is going to be a random number between 1 and 10 using CommitReveal
    // Here is reveal
    function randomCommitRevealMint2ndStep() external {
        CommitRevealEpoch memory commitRevealEpoch = commitRevealEpochs[msg.sender];
        require(commitRevealEpoch.revealBlock > 0, "Error: Not committed yet.");
        require(commitRevealEpoch.revealBlock < block.number, "Error: Block not available yet.");

        uint256 id = randomness(10, commitRevealEpoch.seed, commitRevealEpoch.revealBlock);
        uint256 amount = randomness(1000, id, commitRevealEpoch.revealBlock);

        _mint(msg.sender, id, amount, "" );
    }

    // using code from https://twitter.com/_MouseDev/status/1623044314983964682
    function _resolveEpochIfNeeded() public returns (bool) {
        Epoch storage currentEpoch = epochs[epochIndex];

        if(currentEpoch.committed == false || 
            (currentEpoch.revealed == false && currentEpoch.revealBlock < block.number - 256 ))
        {
            currentEpoch.revealBlock = uint64(block.number + 5);
            currentEpoch.committed = true;
        }
        else if(block.number > currentEpoch.revealBlock)
        {
           currentEpoch.randomness = uint128(block.number);
           // commented so it works on Remix
           // currentEpoch.randomness = uint128(uint256(blockhash(currentEpoch.revealBlock)) % (2 ** 128 - 1));
           currentEpoch.revealed = true;
           epochIndex++;

           return _resolveEpochIfNeeded();
        }

        return true;
    }

    function randomness(uint256 _range, uint256 _seed, uint256 _blockNumber) view public returns(uint256 id) {
        unchecked {
            id =
                uint256(
                    keccak256(
                        abi.encode(
                            keccak256(
                                abi.encodePacked(
                                    block.timestamp,
                                    _blockNumber,
                                    blockhash(_blockNumber),
                                    _seed
                                )
                            )
                        )
                    )
                ) %
                _range;
        }
    } 
}
