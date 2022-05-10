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

    function getMatchedCount(uint _escrowID, uint[] memory _sellerRandomArray) public view returns(uint){    
        (uint[] memory buyerRandomArray, bool[] memory buyerRandomArrayIsRedeemed, bool isExist) = getBuyerRandomArrayByEscrowID(_escrowID);
        require(isExist, "EscrowID is invaild");
        uint matchedCount = 0;
        for (uint i = 0; i < buyerRandomArray.length; i++)
        {
            for (uint j = 0; j < _sellerRandomArray.length; j++)
            {
                if (buyerRandomArray[i] == _sellerRandomArray[j]){
                    if (buyerRandomArrayIsRedeemed[i] != true){
                         matchedCount += 1;
                    }
                }
            }
        }
        return matchedCount;
    }

    function getMatchedNumbers(uint _escrowID, uint[] memory _sellerRandomArray) public returns(uint[] memory){   

        (uint[] memory buyerRandomArray, bool[] memory buyerRandomArrayIsRedeemed, bool isExist) = getBuyerRandomArrayByEscrowID(_escrowID);
        require(isExist, "EscrowID is invaild");

        uint matchedCount = getMatchedCount(_escrowID, _sellerRandomArray);
        uint[] memory matchedRandomArray = new uint[](matchedCount);
        uint matchedCounttemp = 0;

        for (uint i = 0; i < buyerRandomArray.length; i++)
        {
            for (uint j = 0; j < _sellerRandomArray.length; j++)
            {
                if (buyerRandomArray[i] == _sellerRandomArray[j]){
                    if (buyerRandomArrayIsRedeemed[i] != true){
                        escrowArray[_escrowID].buyerRandomArrayIsRedeemed[i] = true;
                        (address buyerAddress,) = getBuyerAddressByEscrowID(_escrowID);
                        uint index = getBuyerDataBaseIndexByAddress(buyerAddress, _escrowID);
                        buyerDatabase[buyerAddress][index].buyerRandomArrayIsRedeemed[i] = true;
                        matchedRandomArray[matchedCounttemp] = buyerRandomArray[i];
                        matchedCounttemp += 1;
                    }
                }
            }
        }
        return matchedRandomArray;
    }

    function getBuyerDataBaseIndexByAddress(address _buyerAddress, uint _escrowID) public view returns(uint){
        uint index = 0;
        for (uint i = 0; i < buyerDatabase[_buyerAddress].length; i++){
            if (buyerDatabase[_buyerAddress][i].escrowID == _escrowID){
                index = i;
            }
        }
        return index;
    }

    function getBuyerAddressByEscrowID(uint _escrowID) public view returns(address, bool){
        bool isExist = false;
        address buyerAddress;
        for (uint i = 0; i < escrowArray.length; i++)
        {
            if (escrowArray[i].escrowID == _escrowID){
                buyerAddress = escrowArray[i].buyer;
                isExist = true;
            }
        }
        return (buyerAddress, isExist);
    }

    function getBuyerByEscrowID(uint _escrowID) public view returns(uint[] memory,bool[] memory, bool){
        (address buyerAddress,bool isExist) = getBuyerAddressByEscrowID(_escrowID);
        require(isExist, "EscrowID is invaild");
        uint[] memory buyerRandomArray;
        bool[] memory buyerRandomArrayIsRedeemed;
        bool isExistInBuyerDatabase = false;

        for (uint i = 0; i < buyerDatabase[buyerAddress].length; i++){
            if (buyerDatabase[buyerAddress][i].escrowID == _escrowID){
                buyerRandomArray = buyerDatabase[buyerAddress][i].buyerRandomArray;
                buyerRandomArrayIsRedeemed = buyerDatabase[buyerAddress][i].buyerRandomArrayIsRedeemed;
                isExistInBuyerDatabase = true;
            }
        }
        
        return (buyerRandomArray, buyerRandomArrayIsRedeemed,isExistInBuyerDatabase);
    }

    function getEscrowArray() public view returns(EscrowStruct[] memory){
        return escrowArray;
    }

    function getSellerArray() public view returns(SellerStruct[] memory){
        return sellerArray;
    }

}


contract POCEscrow is RandomNumArray, Ownable {
    //Version:  v1.0
       
    address public admin;

    
    //Each buyer address consist of an array of EscrowStruct
    //Used to store buyer's transactions and for buyers to interact with his transactions. (Such as releasing funds to seller)
    struct EscrowStruct
    {    
        address buyer;          //Person who is making payment
        address seller;         //Person who will receive funds
        address escrow_agent;   //Escrow agent to resolve disputes, if any
                                    
        uint escrow_fee;        //Fee charged by escrow
        uint amount;            //Amount of Ether (in Wei) seller will receive after fees

        bool escrow_intervention; //Buyer or Seller can call for Escrow intervention
        bool release_approval;   //Buyer or Escrow(if escrow_intervention is true) can approve release of funds to seller
        bool refund_approval;    //Seller or Escrow(if escrow_intervention is true) can approve refund of funds to buyer 

        bytes32 notes;             //Notes for Seller
        
    }

    struct TransactionStruct
    {                        
        //Links to transaction from buyer
        address buyer;          //Person who is making payment
        uint buyer_nounce;         //Nounce of buyer transaction                            
    }


    
    //Database of Buyers. Each buyer then contain an array of his transactions
    mapping(address => EscrowStruct[]) public buyerDatabase;

    //Database of Seller and Escrow Agent
    mapping(address => TransactionStruct[]) public sellerDatabase;       
    mapping(address => TransactionStruct[]) public escrowDatabase;
            
    //Every address have a Funds bank. All refunds, sales and escrow comissions are sent to this bank. Address owner can withdraw them at any time.
    mapping(address => uint) public Funds;

    mapping(address => uint) public escrowFee;


    //Constructor. Set contract creator/admin
    constructor() {
        admin = msg.sender;
    }

    function fundAccount(address sender_)  public payable
    {
        //LogFundsReceived(msg.sender, msg.value);
        // Add funds to the sender's account
        Funds[sender_] += msg.value;   
        
    }

    function setEscrowFee(uint fee) external{

        //Allowed fee range: 0.1% to 10%, in increments of 0.1%
        require (fee >= 1 && fee <= 100);
        escrowFee[msg.sender] = fee;
    }

    function getEscrowFee(address escrowAddress) internal view returns (uint) {
        return (escrowFee[escrowAddress]);
    }

    
    function newEscrowTransaction(address sellerAddress, address escrowAddress, bytes32 notes) public payable returns (bool) {

        require(msg.value > 0 && msg.sender != escrowAddress);
    
        //Store escrow details in memory
        EscrowStruct memory currentEscrow;
        TransactionStruct memory currentTransaction;
        
        currentEscrow.buyer = msg.sender;
        currentEscrow.seller = sellerAddress;
        currentEscrow.escrow_agent = escrowAddress;

        //Calculates and stores Escrow Fee.
        currentEscrow.escrow_fee = getEscrowFee(escrowAddress)*msg.value/1000;
        
        //0.25% dev fee
        uint dev_fee = msg.value/400;
        Funds[admin] += dev_fee;   

        //Amount seller receives = Total amount - 0.25% dev fee - Escrow Fee
        currentEscrow.amount = msg.value - dev_fee - currentEscrow.escrow_fee;

        //These default to false, no need to set them again
        /*currentEscrow.escrow_intervention = false;
        currentEscrow.release_approval = false;
        currentEscrow.refund_approval = false;  */ 
        
        currentEscrow.notes = notes;

        //Links this transaction to Seller and Escrow's list of transactions.
        currentTransaction.buyer = msg.sender;
        currentTransaction.buyer_nounce = buyerDatabase[msg.sender].length;

        sellerDatabase[sellerAddress].push(currentTransaction);
        escrowDatabase[escrowAddress].push(currentTransaction);
        buyerDatabase[msg.sender].push(currentEscrow);
        
        return true;

    }

    //switcher 0 for Buyer, 1 for Seller, 2 for Escrow
    function getNumTransactions(address inputAddress, uint switcher) external view returns (uint)
    {

        if (switcher == 0) return (buyerDatabase[inputAddress].length);

        else if (switcher == 1) return (sellerDatabase[inputAddress].length);

        else return (escrowDatabase[inputAddress].length);
    }

    //switcher 0 for Buyer, 1 for Seller, 2 for Escrow
    function getSpecificTransaction(address inputAddress, uint switcher, uint ID) external view returns (address, address, address, uint, bytes32, uint, bytes32)

    {
        bytes32 status;
        EscrowStruct memory currentEscrow;
        if (switcher == 0)
        {
            currentEscrow = buyerDatabase[inputAddress][ID];
            status = checkStatus(inputAddress, ID);
        } 
        
        else if (switcher == 1)

        {  
            currentEscrow = buyerDatabase[sellerDatabase[inputAddress][ID].buyer][sellerDatabase[inputAddress][ID].buyer_nounce];
            status = checkStatus(currentEscrow.buyer, sellerDatabase[inputAddress][ID].buyer_nounce);
        }

                    
        else if (switcher == 2)
        
        {        
            currentEscrow = buyerDatabase[escrowDatabase[inputAddress][ID].buyer][escrowDatabase[inputAddress][ID].buyer_nounce];
            status = checkStatus(currentEscrow.buyer, escrowDatabase[inputAddress][ID].buyer_nounce);
        }

        return (currentEscrow.buyer, currentEscrow.seller, currentEscrow.escrow_agent, currentEscrow.amount, status, currentEscrow.escrow_fee, currentEscrow.notes);
    }   


    function buyerHistory(address buyerAddress, uint startID, uint numToLoad) external view returns (address[] memory, address[] memory,uint[] memory, bytes32[] memory){


        uint length;
        if (buyerDatabase[buyerAddress].length < numToLoad)
            length = buyerDatabase[buyerAddress].length;
        
        else 
            length = numToLoad;
        
        address[] memory sellers = new address[](length);
        address[] memory escrow_agents = new address[](length);
        uint[] memory amounts = new uint[](length);
        bytes32[] memory statuses = new bytes32[](length);
        
        for (uint i = 0; i < length; i++)
        {

            sellers[i] = (buyerDatabase[buyerAddress][startID + i].seller);
            escrow_agents[i] = (buyerDatabase[buyerAddress][startID + i].escrow_agent);
            amounts[i] = (buyerDatabase[buyerAddress][startID + i].amount);
            statuses[i] = checkStatus(buyerAddress, startID + i);
        }
        
        return (sellers, escrow_agents, amounts, statuses);
    }


                
    function SellerHistory(address inputAddress, uint startID , uint numToLoad) external view returns (address[] memory, address[] memory, uint[] memory, bytes32[] memory){

        address[] memory buyers = new address[](numToLoad);
        address[] memory escrows = new address[](numToLoad);
        uint[] memory amounts = new uint[](numToLoad);
        bytes32[] memory statuses = new bytes32[](numToLoad);

        for (uint i = 0; i < numToLoad; i++)
        {
            if (i >= sellerDatabase[inputAddress].length)
                break;
            buyers[i] = sellerDatabase[inputAddress][startID + i].buyer;
            escrows[i] = buyerDatabase[buyers[i]][sellerDatabase[inputAddress][startID +i].buyer_nounce].escrow_agent;
            amounts[i] = buyerDatabase[buyers[i]][sellerDatabase[inputAddress][startID + i].buyer_nounce].amount;
            statuses[i] = checkStatus(buyers[i], sellerDatabase[inputAddress][startID + i].buyer_nounce);
        }
        return (buyers, escrows, amounts, statuses);
    }


    function escrowHistory(address inputAddress, uint startID, uint numToLoad) external view returns (address[] memory, address[] memory, uint[] memory, bytes32[] memory){
    
        address[] memory buyers = new address[](numToLoad);
        address[] memory sellers = new address[](numToLoad);
        uint[] memory amounts = new uint[](numToLoad);
        bytes32[] memory statuses = new bytes32[](numToLoad);

        for (uint i = 0; i < numToLoad; i++)
        {
            if (i >= escrowDatabase[inputAddress].length)
                break;
            buyers[i] = escrowDatabase[inputAddress][startID + i].buyer;
            sellers[i] = buyerDatabase[buyers[i]][escrowDatabase[inputAddress][startID +i].buyer_nounce].seller;
            amounts[i] = buyerDatabase[buyers[i]][escrowDatabase[inputAddress][startID + i].buyer_nounce].amount;
            statuses[i] = checkStatus(buyers[i], escrowDatabase[inputAddress][startID + i].buyer_nounce);
        }
        return (buyers, sellers, amounts, statuses);
    }

    function checkStatus(address buyerAddress, uint nounce) internal view returns (bytes32){

        bytes32 status = "";

        if (buyerDatabase[buyerAddress][nounce].release_approval){
            status = "Complete";
        } else if (buyerDatabase[buyerAddress][nounce].refund_approval){
            status = "Refunded";
        } else if (buyerDatabase[buyerAddress][nounce].escrow_intervention){
            status = "Pending Escrow Decision";
        } else
        {
            status = "In Progress";
        }
    
        return (status);
    }

    
    //When transaction is complete, buyer will release funds to seller
    //Even if EscrowEscalation is raised, buyer can still approve fund release at any time
    function buyerFundRelease(uint ID) public
    {
        require(ID < buyerDatabase[msg.sender].length && 
        buyerDatabase[msg.sender][ID].release_approval == false &&
        buyerDatabase[msg.sender][ID].refund_approval == false, 'Invalid request');
        
        //Set release approval to true. Ensure approval for each transaction can only be called once.
        buyerDatabase[msg.sender][ID].release_approval = true;

        address seller = buyerDatabase[msg.sender][ID].seller;
        address escrow_agent = buyerDatabase[msg.sender][ID].escrow_agent;

        uint amount = buyerDatabase[msg.sender][ID].amount;
        uint escrow_fee = buyerDatabase[msg.sender][ID].escrow_fee;

        //Move funds under seller's owership
        Funds[seller] += amount;
        Funds[escrow_agent] += escrow_fee;


    }

    //Seller can refund the buyer at any time
    function sellerRefund(uint ID) public
    {
        address buyerAddress = sellerDatabase[msg.sender][ID].buyer;
        uint buyerID = sellerDatabase[msg.sender][ID].buyer_nounce;

        require(
        buyerDatabase[buyerAddress][buyerID].release_approval == false &&
        buyerDatabase[buyerAddress][buyerID].refund_approval == false); 

        address escrow_agent = buyerDatabase[buyerAddress][buyerID].escrow_agent;
        uint escrow_fee = buyerDatabase[buyerAddress][buyerID].escrow_fee;
        uint amount = buyerDatabase[buyerAddress][buyerID].amount;
    
        //Once approved, buyer can invoke WithdrawFunds to claim his refund
        buyerDatabase[buyerAddress][buyerID].refund_approval = true;

        Funds[buyerAddress] += amount;
        Funds[escrow_agent] += escrow_fee;
        
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