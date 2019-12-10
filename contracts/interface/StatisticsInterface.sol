pragma solidity >=0.5.0 <0.6.0;

interface StatisticsInterface {

    // 获取邀请利润记录
    function GetDyHistory(uint256 offset, uint256 size) external view
    returns (
        uint256 len,
        address[] memory froms,
        uint256[] memory values,
        bool[] memory mtypes,
        uint256[] memory times);

    // 获取加入历史记录
    function GetJoinedHistory() external view
    returns (
        uint256 len,
        uint256[] memory stime,
        uint256[] memory etime,
        uint256[] memory values);

    // 获取静态利润记录
    function GetStaticProfitTotalAmount() external view returns (uint256);

    // 获取(动态)推荐利润的累计金额
    function GetDynamicProfitTotalAmount() external view returns (uint256);

    // 以下是轮约可以调用的方法，这些方法大多只用于数据统计，与资金无关。
    function API_NewPlayer(address player) external;

    // 当新地址投资时，增加统计数字，谁是正确的投资额
    function API_NewJoin(address who, uint256 when, uint256 value) external;

    // 每当地址被结算时，记录记录哪个地址被结算。
    function API_NewSettlement(address who, uint256 when) external;

    // 添加静态累积数据
    function API_AddStaticTotalAmount(address player, uint256 value) external;

    // 添加动态累积数据
    function API_AddDynamicTotalAmount(address player, uint256 value) external;

    // 用于记录给定地址的动态收入
    function API_PushNewDyProfit(address who, address where, uint256 value, bool mtype) external;

    // 激活新地址时添加新统计信息
    function API_AddActivate() external;
}