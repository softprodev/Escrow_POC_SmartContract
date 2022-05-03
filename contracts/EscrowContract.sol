// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;
pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface CEth {
    function mint() external payable;
    function exchangeRateCurrent() external returns (uint256);
    function supplyRatePerBlock() external returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function balanceOfUnderlying(address) external returns (uint);
}
contract testEscrow is RandomNumArray, Ownable {
    struct EscrowStruct
    {    
        uint escrowID;
        address buyer;
        uint[] buyerRandomArray;
        bool[] buyerRandomArrayIsRedeemed;
        address[] sellerAddress;
        uint amount;
        uint redeemAmountPerNumber;
        uint createdDate;
        bool isActive;           
    }

    struct SellerStruct
    {    
        uint escrowID;
        address seller;
        uint[] sellerRandomArray;
        uint createdDate;
        uint redeemedAmount; 
    }

    mapping(address => EscrowStruct[]) public buyerDatabase;
    mapping(address => SellerStruct[]) public sellerDatabase;

    EscrowStruct[] public escrowArray;
    SellerStruct[] public sellerArray;
    uint public escrowCount;

    constructor(){
        escrowCount = 0;
    }
    function getCurrentTimeStamp() public view returns(uint){
        return block.timestamp;
    }

    function createNewEscrow(uint[] memory _buyerRandomArray) public payable{
        require(msg.value == 1000000000000000000, "Fund should be 1000000000000000000 wei = 1 ETH");
        require(_buyerRandomArray.length == 10, "Random Array size should be 10.");
        // require(msg.value == 10, "Fund should be 10 wei");
        // require(msg.value == 10000000000000000000, "Fund should be 10 wei");
        EscrowStruct memory newEscrow;
        newEscrow.escrowID = escrowCount;
        escrowCount = escrowCount + 1;
        newEscrow.buyer = msg.sender;
        newEscrow.amount = msg.value;
        newEscrow.buyerRandomArray = _buyerRandomArray;
        bool[] memory _buyerRandomArrayIsRedeemed = new bool[](_buyerRandomArray.length);
        newEscrow.buyerRandomArrayIsRedeemed = _buyerRandomArrayIsRedeemed;
        newEscrow.redeemAmountPerNumber = msg.value/_buyerRandomArray.length;
        newEscrow.createdDate = getCurrentTimeStamp();
        newEscrow.isActive = true;
        escrowArray.push(newEscrow);

        buyerDatabase[msg.sender].push(newEscrow);
    }

    function addNewSeller(uint _escrowID,uint[] memory _sellerRandomArray) public payable returns(string memory){

        (address buyeraddress, bool isExist) = getBuyerAddressByEscrowID(_escrowID);
        require(isExist, "EscrowID is invaild");
        SellerStruct memory newSeller;
        newSeller.escrowID = _escrowID;
        newSeller.sellerRandomArray = _sellerRandomArray;
        newSeller.createdDate = getCurrentTimeStamp();
        newSeller.seller = msg.sender;
        uint[] memory matchedRandomNumbers = getMatchedRandomNumbers(_escrowID,_sellerRandomArray);

        uint index = getBuyerDataBaseIndexByAddress(buyeraddress, _escrowID);

        uint _redeemedAmount = matchedRandomNumbers.length*buyerDatabase[buyeraddress][index].redeemAmountPerNumber;
        newSeller.redeemedAmount = _redeemedAmount;
        sellerArray.push(newSeller);

        sellerDatabase[msg.sender].push(newSeller);
        payable(msg.sender).transfer(_redeemedAmount);

        string memory result;
        if (matchedRandomNumbers.length == 0 ) {
            result = "No Match Found";
        }else{
            result = "Match Found :";
            for (uint i = 0; i<matchedRandomNumbers.length; i++){
                result = append(result,"#",Strings.toString(matchedRandomNumbers[i]), " ,");
            }
        }
        return result;
    }

    function append(string memory a, string memory b, string memory c, string memory d) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d));
    }

    function getRedeemedAmountPerNumberByEscrowID(uint _escrowID) public view returns(uint){
        (address buyeraddress, bool isExist) = getBuyerAddressByEscrowID(_escrowID);
        require(isExist, "EscrowID is invaild");
        uint index = getBuyerDataBaseIndexByAddress(buyeraddress, _escrowID);
        return buyerDatabase[buyeraddress][index].redeemAmountPerNumber;
    }
}
contract EscrowCompound is Ownable {

    event Initiated(string referenceId, address payer, uint256 amount, address payee, address trustedParty, uint256 lastBlock);
    event Signature(string referenceId, address signer, string signedOwner, string signedAgent, uint256 lastBlock);
    event Finalized(string referenceId, address winner, uint256 lastBlock);
    event Disputed(string referenceId, address disputer, uint256 lastBlock);
    event Withdrawn(string referenceId, address payee, uint256 amount, uint256 lastBlock);

    event getAgentLists(AgentList[] agentList);

    CEth cEth;
    struct Record {
        string referenceId;
        address payable owner;
        address payable sender;
        address payable receiver;
        address payable agent;
        uint256 fund;
        bool disputed;
        bool finalized;
        uint256 lastTxBlock;
    }
    mapping(string => Record) public _escrow;

    struct Sign {
        string referenceId;
        bool signerOwner;
        bool signerReceiver;
        bool signerAgent;
        string signedOwner;
        string signedReceiver;
        string signedAgent;
        uint256 releaseCount;
        uint256 revertCount;
    }
    mapping(string => Sign) public _sign;

    struct AgentList {
        address agentAddress;
        bool isAgent;
    }
    
    AgentList[] public agentList;

    struct RefRecord {
        string _referenceId;
        address _sender;
        address _receiver;
        address _agent;
    }
    RefRecord[] public refID;
    RefRecord[] private bufrefID;

    function getEscrowSignbyRef(string memory ref) public view  returns (Record memory, Sign memory){
        return (_escrow[ref], _sign[ref]);
    }

    function getRefID() public view  returns (RefRecord[] memory){
        return refID;
    }

    function addSingleAgent(address newAgent) public {
        require(_msgSender() != address(0), "Sender should not be null");
        require(_msgSender() == owner(), "Sender its not owner");
        for (uint i = 0; i < agentList.length; i ++) {
            require(agentList[i].agentAddress != newAgent, "agent address already added");
        }
        AgentList memory newAgentList;
        newAgentList.agentAddress = newAgent;
        newAgentList.isAgent    = true;
        agentList.push(newAgentList);
    }

    function addCEthAddress(address newCEth) public {
        require(_msgSender() != address(0), "Sender should not be null");
        require(_msgSender() == owner(), "Sender its not owner");
        cEth = CEth(newCEth);
    }

    function getAgentList() public view returns(AgentList[] memory) {
        return agentList;
    }

    function getAgentListEmit() public {
        emit getAgentLists(agentList);
    }

    function getCEthAddress() public view returns(address) {
        return address(cEth);
    }

    modifier multisigcheck(string memory _referenceId) {
        require(bytes(_referenceId).length != 0, "_referenceId should not have empty");
        _;

        Record storage e = _escrow[_referenceId];
        Sign memory s = _sign[_referenceId];
        if(s.releaseCount == 2) {
        transferOwner(e);
        }else if(s.revertCount == 2) {
        finalize(e);
        }else if(s.releaseCount == 1 && s.revertCount == 1) {
        dispute(e); 
        }
    }

    function init(string memory _referenceId, address payable _receiver, address payable _agent) public payable returns(bool) {
        require(_msgSender() != address(0), "Sender should not be null");
        require(_receiver != address(0), "Receiver should not be null");
        Record storage e = _escrow[_referenceId];
        e.referenceId = _referenceId;
        e.owner = payable(_msgSender());
        e.sender = payable(_msgSender());
        e.receiver = _receiver;
        e.agent = _agent;
        e.fund = msg.value;
        e.disputed = false;
        e.finalized = false;
        e.lastTxBlock = block.number;
        Sign storage s = _sign[_referenceId];
        s.referenceId = _referenceId;
        s.signerOwner = true;
        s.signerReceiver = true;
        s.signerAgent  = true;
        s.releaseCount = 0;
        s.revertCount = 0;
        RefRecord memory newRefID;
        newRefID._agent = _agent;
        newRefID._receiver = _receiver;
        newRefID._sender = _msgSender();
        newRefID._referenceId = _referenceId;
        refID.push(newRefID);
        cEth.mint{ value: msg.value, gas: 250000 }();
        emit Initiated(_referenceId, _msgSender(), msg.value, _receiver, _agent, 0);
        return true;
    }

    function releaseOwner(string memory _referenceId) public multisigcheck(_referenceId) returns(bool){
        require(!_escrow[_referenceId].finalized, "Escrow should not be finalized");
        require(_escrow[_referenceId].owner == _msgSender(), "msg sender should be as sender");
        require(_sign[_referenceId].signerOwner, "signer owner must be sign");

        Record memory e = _escrow[_referenceId];
        Sign storage s = _sign[_referenceId];
        s.signedOwner = "RELEASE";
        s.releaseCount++;
        emit Signature(_referenceId, _msgSender(), s.signedOwner, s.signedAgent,e.lastTxBlock); 
        return true;
    }
    function releaseAgent(string memory _referenceId) public multisigcheck(_referenceId) returns(bool){
        require(!_escrow[_referenceId].finalized, "Escrow should not be finalized");
        require(_escrow[_referenceId].agent == _msgSender(), "msg sender should be as agent");
        require(_sign[_referenceId].signerAgent, "signer agent must be sign");

        Record memory e = _escrow[_referenceId];
        Sign storage s = _sign[_referenceId];
        s.signedAgent = "RELEASE";
        s.releaseCount++;
        emit Signature(_referenceId, _msgSender(), s.signedOwner, s.signedAgent,e.lastTxBlock); 
        return true;
    }

    function reverseReceiver(string memory _referenceId) public multisigcheck(_referenceId) returns(bool){
        require(!_escrow[_referenceId].finalized, "Escrow should not be finalized");
        require(_escrow[_referenceId].receiver == _msgSender(), "msg sender should be as sender");
        require(_sign[_referenceId].signerOwner, "signer owner must be sign");

        Record memory e = _escrow[_referenceId];
        Sign storage s = _sign[_referenceId];
        s.signedReceiver = "REVERT";
        s.revertCount++;
        emit Signature(_referenceId, _msgSender(), s.signedOwner, s.signedAgent, e.lastTxBlock);
        return true;
    }
    function reverseAgent(string memory _referenceId) public multisigcheck(_referenceId) returns(bool){
        require(!_escrow[_referenceId].finalized, "Escrow should not be finalized");
        require(_escrow[_referenceId].agent == _msgSender(), "msg sender should be as agent");
        require(_sign[_referenceId].signerAgent, "signer agent must be sign");
        Record memory e = _escrow[_referenceId];
        Sign storage s = _sign[_referenceId];
        s.signedAgent = "REVERT";
        s.revertCount++;
        emit Signature(_referenceId, _msgSender(), s.signedOwner, s.signedAgent, e.lastTxBlock);
        return true;
    }

    function dispute(string memory _referenceId) public returns(bool) {
        Record storage e = _escrow[_referenceId];
        require(!e.finalized, "Escrow should not be finalized");
        require(_msgSender() == e.sender || _msgSender() == e.receiver, "Only sender or receiver can call dispute");
        dispute(e);
        return true;
    }
    
    function withdraw(string memory _referenceId) public returns(bool) {
        Record storage e = _escrow[_referenceId];
        require(e.finalized, "Escrow should be finalized before withdrawal");
        require(_msgSender() == e.owner, "only owner can withdrawfunds");
        require(e.fund <=  cEth.balanceOfUnderlying(address(this)));
        e.lastTxBlock = block.number;
        cEth.redeemUnderlying(e.fund);
        require((e.owner).send(e.fund));
        e.fund = 0;
        for(uint i=0; i < refID.length; i++){
            if(keccak256(bytes(refID[i]._referenceId)) != keccak256(bytes(_referenceId))){
                RefRecord memory newRefID;
                newRefID._agent = refID[i]._agent;
                newRefID._receiver = refID[i]._receiver;
                newRefID._sender = refID[i]._sender;
                newRefID._referenceId = refID[i]._referenceId;
                bufrefID.push(newRefID);
            }
        }
        delete refID;
        refID = bufrefID;
        delete bufrefID;
        emit Withdrawn(_referenceId, _msgSender(), e.fund, e.lastTxBlock);
        return true;
    }

    function transferOwner(Record storage e) internal {
        e.owner = e.receiver;
        finalize(e);
        e.lastTxBlock = block.number;
    }

    function dispute(Record storage e) internal {
        e.disputed = true;
        e.lastTxBlock = block.number;
        emit Disputed(e.referenceId, _msgSender(), e.lastTxBlock);
    }

    function finalize(Record storage e) internal {
        require(!e.finalized, "Escrow should not be finalized");
        e.finalized = true;
        emit Finalized(e.referenceId, e.owner, e.lastTxBlock);
    }



    receive() external payable {}
}