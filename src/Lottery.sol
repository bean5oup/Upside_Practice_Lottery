// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract Lottery {
    struct Info {
        uint16 number;
        uint256 lastBlockTime;
        bool claim;
    }

    enum State {
        NOP,
        SELL,
        CLAIM
    }

    uint256 sellEndTime;
    uint256 claimEndTime;
    uint16 magic;
    mapping(address => Info) users;
    mapping(uint16 => uint256) list;
    State public state;

    constructor() {
        sellEndTime = block.timestamp + 24 hours;
        state = State.SELL;
    }

    function buy(uint16 number) public payable {
        require(msg.value == 0.1 ether);
        if(state == State.CLAIM && (claimEndTime < block.timestamp || list[magic] == 0)) {
            sellEndTime = block.timestamp + 24 hours;
            state = State.SELL;
            claimEndTime = 0; // need to check underflow claimEndTime - 24 hours
            for(uint16 i = 0; i < 16; i++)
                list[i] = 0;
        }
        Info storage user = users[msg.sender];
        require(block.timestamp < sellEndTime && user.lastBlockTime < (sellEndTime - 24 hours));
        user.lastBlockTime = block.timestamp;
        user.number = number;
        user.claim = false;
        list[number]++;
    }

    function draw() public {
        require(sellEndTime <= block.timestamp);
        require(claimEndTime < block.timestamp);
        claimEndTime = block.timestamp + 24 hours;
        _draw();
    }

    function _draw() internal {
        // bytes32 hash = keccak256(abi.encodePacked(address(this).balance, block.timestamp));
        bytes32 hash = keccak256(abi.encodePacked(block.timestamp));

        // magic = uint16(uint256(hash) % type(uint16).max);
        magic = uint16(uint256(hash) % 16);

        state = State.CLAIM;
    }

    function claim() public {
        require(state == State.CLAIM);
        require(sellEndTime <= block.timestamp && block.timestamp < claimEndTime && block.timestamp >= (claimEndTime - 24 hours));
        Info storage user = users[msg.sender];
        require(!user.claim);
        user.claim = true;

        if(user.number == magic) {
            // require(list[magic] > 0);
            // payable(msg.sender).transfer(address(this).balance); // reverted by gas limit
            (bool success, ) = address(msg.sender).call{value: (address(this)).balance / list[magic]}("");
            list[magic]--;
            require(success);
        }
    }

    function winningNumber() public view returns (uint16) {
        return magic;
    }
}