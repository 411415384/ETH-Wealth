pragma solidity >=0.5.0 <0.6.0;

import "./interface/CostInterface.sol";
import "./InternalModule.sol";

contract Cost is CostInterface, InternalModule {

    // 当前手续费百分比
    uint256 public _costProp = 3;

    // 当前汇率
    uint256 public _prop = 3000 ether;

    // 构造函数
    constructor(uint256 defaultProp, uint256 costprop) public {

        _prop = defaultProp;

        _costProp = costprop;
    }

    // 当前手续费百分比
    function CurrentCostProp() external view returns (uint256) {
        return _costProp;
    }

    // 提取收益所需要消耗的手续费EWT
    function WithdrawCost(uint256 value) external view returns (uint256) {
        return ((value * _costProp / 100) * _prop) / 1 ether;
    }

    // 设置手续费百分币
    function Owner_SetChangeProp(uint256 p) public OwnerOnly {
        _prop = p;
    }

    // 设置当前汇率
    function Owner_SetCostProp(uint256 newProp) public OwnerOnly {
       _costProp = newProp;
    }


}
