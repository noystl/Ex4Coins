pragma solidity ^0.5.9;


contract Channel{

    address payable public owner1;
    address payable public owner2;    // The Person who deployed the contract.
    uint256 public owner1Money;
    uint256 public owner2Money;
    uint public appealPeriod;
    int8 public lastSerial;
    uint256 public lastBalance;
    uint public startAppealBlock;

    event test(uint256 msg);

	// This modifier is used below to restrict access.
    modifier onlyOwners{
        require(msg.sender == owner1 || msg.sender == owner2,
            "Only an owner can call this function.");
        _;
    }


	//creates a new channel
    constructor(address payable _other_owner, uint _appeal_period_len) payable public{
	    owner1 = _other_owner;
	    owner2 = msg.sender;
	    owner1Money = 0;
	    owner2Money = 0;
	    lastSerial = -1;
	    appealPeriod = _appeal_period_len;
	}


    // closes the channel according to a default_split, gives the money to party 1. starts the appeal process.
    function default_split() onlyOwners external{
        owner1Money = 0;    // Default shares
	    owner2Money = address(this).balance;
	    lastSerial = 0;
        startAppealBlock = block.number;
    }


    function verifySig(address contractAddr, address reciver, uint256 balance, int8 serial_num, uint8 v,
    bytes32 r, bytes32 s, address signerPubKey) pure public returns (bool){
        bytes32 hashMessage = keccak256(abi.encodePacked(contractAddr, reciver, balance, serial_num));
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashMessage));
        return ecrecover(messageDigest, v, r, s) == signerPubKey;
    }


    //closes the channel based on a message by one party. starts the appeal period
    function one_sided_close(address contractAddr, address reciver, uint256 balance, int8 serial_num ,
    uint8 v, bytes32 r, bytes32 s) onlyOwners external{

        // Tests the signiture:
        if(msg.sender == owner1){
            require(verifySig(contractAddr, reciver, balance, serial_num, v, r, s, owner2), "Supplied signiture is not valid.");
        } else{
            require(verifySig(contractAddr, reciver, balance, serial_num, v, r, s, owner1), "Supplied signiture is not valid.");
        }

        require(contractAddr == address(this) && serial_num > lastSerial && balance >=0, "Fishy message.");

        // Gives money to the reciver:
        if(reciver == owner1){
            owner1Money = balance;
            owner2Money = address(this).balance - balance;
        }else{
            owner2Money = balance;
            owner1Money = address(this).balance - balance;
        }

        // Starts the appeal period:
        startAppealBlock = block.number;
        lastSerial = serial_num;
    }


    // appeals a one_sided_close. should show a newer signature. only useful within the appeal period
    function appeal_closure(address contractAddr, address reciver, uint256 balance, int8 serial_num ,
    uint8 v, bytes32 r, bytes32 s) onlyOwners external{

        require(block.number - startAppealBlock < appealPeriod, "The appeal period is over.");

        // Checks signiture:
        if(msg.sender == owner1){
            require(verifySig(contractAddr, reciver, balance, serial_num, v, r, s, owner2), "Appeal is illegal.");
        } else{
            require(verifySig(contractAddr, reciver, balance, serial_num, v, r, s, owner1), "Appeal is illegal.");
        }

        require(contractAddr == address(this) && serial_num > lastSerial && balance >=0, "Fishy message.");

        // Gives money to the reciver:
        if(reciver == owner1){
            owner1Money = balance;
            owner2Money = address(this).balance - balance;
        }else{
            owner2Money = balance;
            owner1Money = address(this).balance - balance;
        }

        lastSerial = serial_num;
    }


    //withdraws the money of msg.sender to the address he requested. Only used after appeals are done.
    function withdraw_funds(address payable dest_address) onlyOwners external{

        require(lastSerial >= 0, "Channel is not closed yet.");
        require(block.number >= (startAppealBlock + appealPeriod), "Appeal period is not over yet!");

        uint256 amountToWithdraw;
        if(msg.sender == owner1){
            amountToWithdraw = owner1Money;
            owner1Money = 0;
        } else{
            amountToWithdraw = owner2Money;
            owner2Money = 0;
        }

        (bool res,) = dest_address.call.value(amountToWithdraw)("");
        require(res);
    }

    function () external payable{
        revert();  // we make this contract non-payable. Money can only be added at creation.
    }
}