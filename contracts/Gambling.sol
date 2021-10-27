pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Gambling is VRFConsumerBase {
    uint256 public minimumStake;
    uint256 public extraAmount;
    uint256 public playersCount;
    uint256 public poolWeight;
    uint256 public playersCounter;
    uint256 public amountCounter;
    address payable public winner;
    
    address public owner;
    address payable[] public players;
    
    struct Player {
        uint256 amountBet;
    }
    
    struct Game {
        uint256 betAmmount;
    }
    
    mapping(address => Player) public playerInfo;
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomResult;
    
    constructor(uint128 _playersCount, uint256 _minimumStake) public VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        ){
        playersCount = _playersCount;
        minimumStake = _minimumStake;
        owner = msg.sender;
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }
    
    function playerStake(uint256 playerAmount) public payable {
        require(msg.sender != owner);
        require(playerAmount >= minimumStake);
        if (playerAmount >= minimumStake) {
            playerInfo[msg.sender].amountBet = msg.value;
            players.push(msg.sender);
            playersCounter += 1;
            amountCounter += minimumStake;
            extraAmount = playerAmount - minimumStake;
        }
    }
    
    function refundAmount(address payable _receiver) public payable {
        require(!checkPlayerExists(msg.sender));
        poolWeight = amountCounter * playersCounter;
        if (poolWeight != (playersCount * minimumStake)) {
            amountCounter -= minimumStake;
            playersCount -= 1;
            _receiver.transfer(minimumStake);
            for(uint i=0; i<players.length; i++) {
                if(players[i] == _receiver) {
                    players.pop();
                }
            }
        }
    }
    
    function checkPlayerExists(address player) public view returns(bool) {
        for(uint256 i=0; i < players.length; i++) {
            if (players[i] == player) return true;
        }
        return false;
    }
    
    function randomGamble() public payable {
        require(playersCount >= 3);
        require(!checkPlayerExists(msg.sender));
        require(poolWeight == (playersCount * minimumStake));
        
        fulfillRandomness;
        winner = players[randomResult];
        uint256 winningAmount = ((playersCount * minimumStake));
        winner.transfer(winningAmount);
    }
    
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness.mod(playersCount);
    }
}