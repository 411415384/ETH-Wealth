pragma solidity >=0.5.0 <0.6.0;

import "./InternalModule.sol";
import "./interface/TicketInterface.sol";
import "./interface/RecommendInterface.sol";
import "./interface/ERC20Interface.sol";
import "./interface/StatisticsInterface.sol";
import "./interface/RoundInterface.sol";

 contract Ticket is TicketInterface, InternalModule {

    uint256 public ticketPrice = 40000000000000000000;

    mapping( address => bool ) private _paymentTicketAddrMapping;

    mapping( address => uint256 ) private _latestDyProfitTime;

    mapping( address => uint256 ) private _latestSettTime;

    mapping( address => uint256 ) private _latestJoinTime;

    mapping( address => bool ) private _needClearHistory;

    uint256 public _dyPropExpTime = 180 days;

    uint256 public _reJoinExpTime = 2 minutes;

    RecommendInterface private _RInc;
    ERC20Interface private _TInc;
    StatisticsInterface private _SInc;
    RoundInterface public _CRInc;

    // 构造函数
    constructor(RecommendInterface rinc, ERC20Interface tinc, StatisticsInterface sinc) public {
        _RInc = rinc;
        _TInc = tinc;
        _SInc = sinc;
    }

    // 重复支付门票
    function RePaymentTicket() external {

        require(_latestSettTime[msg.sender] != 0);

        internalPaymentTicket(msg.sender);

        _CRInc.API_RepaymentTicketDelegate(msg.sender);
    }

    function internalPaymentTicket(address owner) internal {

        require(ticketIsVaild(owner) == false, "ERR_01");
        require(_TInc.balanceOf(owner) >= ticketPrice, "ERR_02");

        _TInc.API_MoveToken(owner, address(0x0), ticketPrice);
        _SInc.API_AddActivate();

        _latestDyProfitTime[msg.sender] = now;
        _latestSettTime[msg.sender] = now;
        _latestJoinTime[msg.sender] = now;

        _paymentTicketAddrMapping[msg.sender] = true;
    }

    // 验证某个地址是否已经支付过门票
    function ticketIsVaild(address ownerAddr) internal view returns (bool) {

        /// Have not purchased tickets yet, return directly without tickets
        if ( !_paymentTicketAddrMapping[ownerAddr] ) {
            return false;
        }

        /// 1.如果门票已经购买，但最后一次产生动态收益的时间已经超过180天，则车票无效
        if (now - _latestDyProfitTime[ownerAddr] > _dyPropExpTime) {
            return false;
        }

        /// 2.如果门票已经购买，但在最后一次结算后，当前时间已超过7天，则门票无效。
        if ( _latestJoinTime[ownerAddr] > _latestSettTime[ownerAddr] ) {

            /// 如果上次投资但时间大于上次结算时间，则表示对应地址为一轮未结算
            return true;

        } else if ( _latestJoinTime[ownerAddr] < _latestSettTime[ownerAddr] ) {

            /// 如果最后一次投资时间小于最后一次结算时间，则意味着用户目前不在轮，即不存在再投资。在当前条件下，如果当前时间距上次结算时间超过7天，则视为无效
            if ( now - _latestSettTime[ownerAddr] > _reJoinExpTime ) {
                return false;
            }
        }

        return true;
    }

    // 获取对应地址的票证信息。已指示是否有票证，vaild指示票证是否有效
    function HasTicket(address ownerAddr) external view returns (bool has, bool isVaild) {
        return (_paymentTicketAddrMapping[ownerAddr],ticketIsVaild(ownerAddr));
    }

    // 激活地址
    function ActivateAddress(address recommAddr, bytes6 shortCode) external {

        internalPaymentTicket(msg.sender);

        _RInc.API_BindEx(msg.sender, recommAddr, shortCode);

        return;
    }

    // 绑定关系时，支付门票40EWT
    function PaymentTicket() external {
        require(_RInc.AddressToShortCode(msg.sender) != bytes6(0x000000000000),"recomm shortCode Not Allowed Empty");
        internalPaymentTicket(msg.sender);
    }

    // 设置当前轮次
    function Owner_SetCurrentRound(address currRoundAddr) public OwnerOnly{

         _authAddress[0][address(this)] = currRoundAddr;
    }

    // 设置门票价格
    function Owner_SetTicketPrices(uint price) public OwnerOnly{
         ticketPrice = price;
    }

    // 设置动态过期时间
    function Owner_SetDyPropExpTime(uint256 expTime) public OwnerOnly {
          _dyPropExpTime = expTime;
    }

    // 设置重新加入过期时间
    function Owner_SetReJoinExpTime(uint256 expTime) public OwnerOnly {
         _reJoinExpTime = expTime;
    }

    // 需要清理历史队列某个人
    function API_NeedClearHistory(address owner) external APIMethod returns (bool) {

        if ( _needClearHistory[owner] ) {
            _needClearHistory[owner] = false;
            return true;
        }
        return false;
    }

    // 更新最后动态利润者
    function API_UpdateLatestDyProfitTime(address owner) external APIMethod {
        _latestDyProfitTime[owner] = now;
    }

    // 指定某个人为最后一个位参与者
    function API_UpdateLatestSettTime(address owner) external APIMethod {
        _latestSettTime[owner] = now;
    }

    // 更新最后加入时间
    function API_UpdateLatestJoinTime(address owner) external APIMethod {
        _latestJoinTime[owner] = now;
    }

}
