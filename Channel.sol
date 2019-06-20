pragma solidity ^0.5.9;

// this is a skeleton file for the channel contract. Feel free to change as you wish.
contract Channel{

    address payable public owner1;
    address payable public owner2;    // The Person who deployed the contract.
    uint appealPeriod;

	//Notice how this modifier is used below to restrict access. Create more if you need them!
    modifier onlyOwners{
        require(msg.sender == owner1 || msg.sender == owner2,
            "Only an owner can call this function.");
        _;
    }

	//creates a new channel
    constructor(address payable _other_owner, uint _appeal_period_len) payable public{
	    owner1 = _other_owner;
	    owner2 = msg.sender;
	    appealPeriod = _appeal_period_len;
	}

    // closes the channel according to a default_split, gives the money to party 1. starts the appeal process.
    function default_split() onlyOwners external{
        uint256 currBalance = address(this).balance;
        owner1.call.value(currBalance / 2)(""); // What if this fails? can owner1 call this again from it's fallback function? Do we need to think about such things?
        owner2.call.value(currBalance / 2)("");
    }

    //closes the channel based on a message by one party. starts the appeal period
    function one_sided_close(uint256 balance, int serial_num , uint8 v, bytes32 r, bytes32 s) onlyOwners external{
    }

    function appeal_closure(uint256 balance, int serial_num , uint8 v, bytes32 r, bytes32 s) onlyOwners external{
        // appeals a one_sided_close. should show a newer signature. only useful within the appeal period
    }

    function withdraw_funds(address payable dest_address) onlyOwners external{
        //withdraws the money of msg.sender to the address he requested. Only used after appeals are done.
    }

    function () external payable{
        revert();  // we make this contract non-payable. Money can only be added at creation.
    }
}