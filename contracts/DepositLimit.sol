pragma solidity >=0.5.0 <0.6.0;

import "./interface/DepositLimitInterface.sol";
import "./InternalModule.sol";

contract DepositLimit is DepositLimitInterface,InternalModule {

    // 地址限额mapping
    mapping (address => uint256) _limitMapping;

    /// 默认限额
    uint256 private _defaultLimit = 10 ether;

    /// 全网每日投资限额
    uint256 public _investEverDayMaxLimit = 1000 ether;

    /// 上次限额重置时间
    uint256 public _investEverDayUTime = now ;

    /// 自上次重置以来累计的金额
    uint256 public _investEverDayTotal = 0;

    // 构造函数
    constructor(uint256 defaultlimit) public {
        _defaultLimit = defaultlimit;
    }

    /// 对指定用户增加保证金限额，只有本轮合同才有操作权
    function API_AddDepositLimit(address ownerAddr, uint256 value, uint256 maxlimit) external APIMethod {

        if (_limitMapping[ownerAddr] == 0) {
            _limitMapping[ownerAddr] = _defaultLimit;
        }

        if (_limitMapping[ownerAddr] + value > maxlimit) {

            _limitMapping[ownerAddr] = maxlimit;

        } else {

            _limitMapping[ownerAddr] += value;

        }
    }

    // 根据地址获取最大限制投入金额
    function DepositLimitOf(address ownerAddr) external view returns (uint256) {

        if ( _limitMapping[ownerAddr] == 0 ) {
            return _defaultLimit;
        }

        return _limitMapping[ownerAddr];
    }

    /// 增加今天的参与配额
    function API_AddDepositLimitAll(uint256 value) external APIMethod  {

        if ( now - _investEverDayUTime > 1 days ) {

            _investEverDayUTime = (now / 1 days) * 1 days;

            _investEverDayTotal = value;

        } else {

            require(_investEverDayMaxLimit >= _investEverDayTotal + value);

            _investEverDayTotal += value;

        }

    }

    // 剩余一天，整个网络都可以参与配额
    function SurplusDepositLimitAll() external view returns (uint256) {

        if ( now - _investEverDayUTime > 1 days ) {

            return _investEverDayMaxLimit;

        } else {

            return _investEverDayMaxLimit - _investEverDayTotal;

        }

    }

    // 设置全网每日投资限额
    function Owner_SetInvestEverDay(uint ethAmount) public OwnerOnly {
         _investEverDayMaxLimit = ethAmount;
    }
}
