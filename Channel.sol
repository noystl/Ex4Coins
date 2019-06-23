pragma solidity ^0.5.9;

// this is a skeleton file for the channel contract. Feel free to change as you wish.
contract Channel{

    address payable public owner1;
    address payable public owner2;    // The Person who deployed the contract.
    uint256 owner1Money;
    uint256 owner2Money;
    uint appealPeriod;
    int lastSerial;
    int isClosed;
    uint startAppealBlock;

	//Notice how this modifier is used below to restrict access. Create more if you need them!
    modifier onlyOwners{
        require(msg.sender == owner1 || msg.sender == owner2,
            "Only an owner can call this function.");
        _;
    }

    // modifier notClosed{
    //     require(isClosed == 1, "The channel is allready closed.");
    //     _;
    // }

	//creates a new channel
    constructor(address payable _other_owner, uint _appeal_period_len) payable public{
	    owner1 = _other_owner;
	    owner2 = msg.sender;
	    isClosed = 0;                                // Not closed
	    owner1Money = address(this).balance / 2;    // Default shares
	    owner2Money = address(this).balance / 2;
	    appealPeriod = _appeal_period_len;
	}

    // closes the channel according to a default_split, gives the money to party 1. starts the appeal process.
    function default_split() onlyOwners external{
        startAppealBlock = block.number;
        isClosed = 1;
    }

    function verifySig(uint256 num1, string memory word1, bool b1, uint8 v, bytes32 r,
    bytes32 s, address signerPubKey) pure public returns (bool){
        bytes32 hashMessage = keccak256(abi.encodePacked(num1, word1, b1));
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashMessage));
        return ecrecover(messageDigest, v, r, s) ==signerPubKey;
    }

    //closes the channel based on a message by one party. starts the appeal period
    function one_sided_close(uint256 balance, int serial_num , uint8 v, bytes32 r, bytes32 s) onlyOwners external{
        //TODO: Check signature!
        startAppealBlock = block.number;
        isClosed = 1;
        lastSerial = serial_num;

        if(msg.sender == owner1){
            owner1Money = balance;
        } else{
            owner2Money = balance;
        }
    }

    // appeals a one_sided_close. should show a newer signature. only useful within the appeal period
    function appeal_closure(uint256 balance, int serial_num , uint8 v, bytes32 r, bytes32 s) onlyOwners external{

    }

    //withdraws the money of msg.sender to the address he requested. Only used after appeals are done.
    function withdraw_funds(address payable dest_address) onlyOwners external{
        if(block.number >= (startAppealBlock + appealPeriod)){
                uint256 amountToWithdraw;

                if(msg.sender == owner1){
                    amountToWithdraw = owner1Money;
                    owner1Money = 0;
                } else{
                    amountToWithdraw = owner2Money;
                    owner2Money = 0;
                }
                (bool res,) = dest_address.call.value(amountToWithdraw)("");
        }
    }

    function () external payable{
        revert();  // we make this contract non-payable. Money can only be added at creation.
    }
}