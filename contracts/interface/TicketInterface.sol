pragma solidity >=0.5.0 <0.6.0;

import "./RoundInterface.sol";
interface TicketInterface {

    // 一个地址需要有足够的epk来解锁帐户。如果以前有一个帐户已解锁，则此方法将不生效
    function RePaymentTicket(RoundInterface roundAddr) external;

    // 确定地址是否支付并有效
    function HasTicket( address ownerAddr ) external view returns (bool has, bool isVaild);

    // 激活地址
    function ActivateAddress(address recommAddr, bytes6 shortCode) external;

    function API_NeedClearHistory( address owner ) external returns (bool);

    function API_UpdateLatestDyProfitTime( address owner ) external;

    function API_UpdateLatestSettTime( address owner ) external;

    function API_UpdateLatestJoinTime( address owner ) external;
}