pragma solidity >=0.5.0 <0.6.0;

interface RoundInterface {

    event Event_NewDepositJoined(address indexed owner, uint256 indexed amount, uint256 indexed total);

    // 检查当前游戏回合。用户需要发送至少一个eth来加入游戏，并确保他们目前没有参与其他回合
    function Join() external payable;

    // 获取用户当前参与的轮次信息
    function GetCurrentRoundInfo( address owner ) external view returns ( uint256 stime, uint256 etime, uint256 value, bool redressable);

    // 结算时间到，结算一轮利润
    function Settlement() external;

    // 检查一个地址可以获得的推荐利润
    function DynamicAmountOf( address owner ) external view returns (uint256);

    // 提取动态利润
    function WithdrawDynamic() external returns (bool);

    // 一个用户的预期利润
    // v2 unsupport this method
    // function ExpectedRevenue() external view returns (uint256);

    // 获取用户的当前轮ETH的总投入和总提取金额
    function TotalInOutAmount() external view returns (uint256 inEther, uint256 outEther);

    // 获得补偿
    // v2 unsupport this method
    // function WithdrawRedress() external returns (uint256);

    // 获得补偿
    // v2 unsupport this method
    // function WithdrawRedressAmount() external view returns (uint256 e, uint256 t);

    // 当补偿产生时，就需要付出
    function DrawRedress() external returns (bool);

    function GetRedressInfo() external view returns (uint256 total, bool withdrawable);

    function API_RepaymentTicketDelegate( address owner ) external;
}
