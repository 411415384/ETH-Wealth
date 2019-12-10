pragma solidity >=0.5.0 <0.6.0;

interface DepositLimitInterface {

    // 获取指定地址的最大存款限制
    function DepositLimitOf(address ownerAddr) external view returns (uint256);

    // 剩余一天，整个网络都可以参与配额
    function SurplusDepositLimitAll() external view returns (uint256);

    // 对指定用户增加保证金限额，只有本轮合同才有操作权
    function API_AddDepositLimit(address ownerAddr, uint256 value, uint256 maxlimit) external;

    // 增加今天的参与配额
    function API_AddDepositLimitAll(uint256 value) external;

}
