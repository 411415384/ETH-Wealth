pragma solidity >=0.5.0 <0.6.0;

interface TokenChangerInterface {

    // 获取指定的共振轮信息
    function ChangeRoundAt(uint8 rid) external view returns (uint8 roundID, uint256 total, uint256 prop, uint256 changed);

    // 当前共振轮信息
    function CurrentRound() external view returns (uint8 roundID, uint256 total, uint256 prop, uint256 changed);

    // 根据当前兑换汇率 把eth to token
    function DoChangeToken() external payable;

    // 转换成功时事件的定义
    event Event_ChangedToken(address indexed owner, uint8 indexed round, uint256 indexed value);
}
