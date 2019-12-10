pragma solidity >=0.5.0 <0.6.0;

interface LuckAssetsPoolInterface {

    /// 得到我的奖励价格
    function RewardsAmount() external view returns (uint256);

    /// 提取我的所有奖励
    function WithdrawRewards() external returns (uint256);

    // 获取分配比例
    function InPoolProp() external view returns (uint256);

    /// 添加用户到最新.
    function API_AddLatestAddress( address owner, uint256 amount ) external;

    /// 中奖 !!!!
    function API_WinningThePrize() external;
}