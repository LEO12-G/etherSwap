// Deposit & Withdraw Funds
// Manage Orders - Make or Cancel
// Handle Trades - Charge fees

//TODO:
//Dopsit Ether
//Withdraw Ether
//Deposit tokens
//Withdraw toekns
//Check balance
//Make order
//Cancel order
//Fill order
//Charge fees

pragma solidity ^0.8.0;

import "./Token.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Exchange {
    using SafeMath for uint;

    address public feeAccount;
    uint256 public feePercent;
    address constant ETHER = address(0);//store Ether in tokens mapping with blank address

    mapping(address =>mapping(address => uint256)) public tokens;
    mapping(uint256 => _Order) public orders;
    uint256 public orderCount;
    mapping(uint256 => bool) public orderCancelled;
    mapping(uint256 => bool) public orderFilled;

    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);
    event Order(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );

    event Cancel(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );

    event Trade(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        address userFill,
        uint256 timestamp
    );



//a way to model the order
//Structs
    struct _Order{
        uint256 id;
        address user;
        address tokenGet;
        uint256 amountGet;
        address tokenGive;
        uint256 amountGive;
        uint256 timestamp;
    }

    
    //a way stroe the order


    //add the order to storage


    constructor (address _feeAccount, uint256 _feePercent) public {
        feeAccount = _feeAccount;
        feePercent = _feePercent;
    }

    fallback() external{
        revert();
    }

    function depositEther() payable public {
        tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].add(msg.value);
        emit Deposit(ETHER, msg.sender, msg.value, tokens[ETHER][msg.sender]);

    }

    function withdrawEther(uint _amount) public {
        
        require(tokens[ETHER][msg.sender] >= _amount);
        tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].sub(_amount);
        payable(msg.sender).transfer(_amount);
        emit Withdraw(ETHER, msg.sender, _amount, tokens[ETHER][msg.sender]);

    }

    function depositToken(address _token, uint _amount) public {
        // TODO: Don't allow Ether deposit
        require(_token != ETHER);
        require(Token(_token).transferFrom(msg.sender, address(this), _amount));
        tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);
        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
        // How much?
        // Manage deposit - update balance
        // Emit event
    }

    function withdrawToken(address _token, uint256 _amount) public {
        tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
        require(Token(_token).transfer(msg.sender, _amount));
        emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function balanceOf(address _token, address _user) public view returns(uint256) {
        return tokens[_token][_user];
    }

    function makeOrder(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) public {
        orderCount = orderCount.add(1);
        orders[orderCount] = _Order(orderCount,msg.sender, _tokenGet,_amountGet,_tokenGive,_amountGive,block.timestamp);
        emit Order(orderCount, msg.sender, _tokenGet,_amountGet,_tokenGive,_amountGive,block.timestamp);
    }

    function cancelOrder(uint256 _id) public {
        _Order storage _order = orders[_id];
        require(address(_order.user) == msg.sender);
        require(_order.id == _id); // The order must exist
        orderCancelled[_id] = true;
        emit Cancel(_order.id, msg.sender, _order.tokenGet, _order.amountGive, _order.tokenGive, _order.amountGive,block.timestamp);
    }

    function fillOrder(uint256 _id) public {
        require(_id > 0 && _id <= orderCount);
        require(!orderFilled[_id]);
        require(!orderCancelled[_id]);
        _Order storage _order = orders[_id]; //Fetch the Order
        _trade(_order.id, _order.user, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive);
        //Mark order as filled
        orderFilled[_order.id] = true;
    }

    function _trade(uint256 _orderId , address _user,address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) internal {
        uint256 _feeAmount = _amountGive.mul(feePercent).div(100);

        //Execute trade
        tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender].sub(_amountGet.add(_feeAmount));
        tokens[_tokenGet][_user] = tokens[_tokenGet][_user].add(_amountGet);
        tokens[_tokenGet][feeAccount] = tokens[_tokenGet][feeAccount].add(_feeAmount);
        tokens[_tokenGive][_user] = tokens[_tokenGive][_user].sub(_amountGive);
        tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender].add(_amountGive);
        //Charge fees

        //Emit trade event
        emit Trade(_orderId, _user, _tokenGet, _amountGet, _tokenGive, _amountGive,msg.sender,block.timestamp);

    }

}