pragma solidity >=0.5.0 <0.6.0;

interface CostInterface {

    //获取当前汇率，1ETH：xx
    function CurrentCostProp() external view returns (uint256);

    //获取对应的erc-20代币手续费值
    function WithdrawCost(uint256 value) external view returns (uint256);
    
}
