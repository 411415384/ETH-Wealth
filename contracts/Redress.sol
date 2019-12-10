pragma solidity >=0.5.0 <0.6.0;

import "./InternalModule.sol";
import "./interface/RedressInterface.sol";
import "./interface/ERC20Interface.sol";

contract Redress is InternalModule, RedressInterface {

    // 锁定补偿结构体
    struct LockedRedress {

        uint256 total;  // 总额

        uint256 withdrawed; // 提取

        uint256 latestWithdrawTime;  // 最后提取时间
    }

    ERC20Interface private _EInc;

     // 补偿提取手续费比例
    uint256 public _withdrawProp = 2;

    // 间隔时间
    uint256 public _freeDuration = 1 days;

    mapping(address => LockedRedress) _lockRedressMapping;


    // 构造函数
    constructor(ERC20Interface einc) public {

        _EInc = einc;
    }

   
     // 设置补偿提取手续费比例
    function Owner_SetRedressProp(uint256 p) public OwnerOnly{
         _withdrawProp = p;
    }

    // 获取补偿信息
    function RedressInfo() external view returns (uint256 total,uint256 withdrawed,uint256 cur) {

        if ( _lockRedressMapping[msg.sender].total == 0 ) {
            return (0, 0, 0);
        }

        LockedRedress memory red = _lockRedressMapping[msg.sender];

        uint256 cwdc = (now - red.latestWithdrawTime) / _freeDuration;

        // 补偿金额
        uint256 amount = red.total * (_withdrawProp * cwdc) / 100;

        if (red.withdrawed + amount > red.total) {
            amount = red.total - red.withdrawed;
        }

        return (red.total,red.withdrawed,amount);
    }

    // 提取补偿
    function WithdrawRedress() external returns (uint256) {

        LockedRedress storage red = _lockRedressMapping[msg.sender];

        if (red.total == 0 || red.total == red.withdrawed) {
            return 0;
        }

        uint256 cwdc = (now - red.latestWithdrawTime) / _freeDuration;
        uint256 amount = red.total * (_withdrawProp * cwdc) / 100;

        if (red.withdrawed + amount > red.total) {
            amount = red.total - red.withdrawed;
        }

        red.withdrawed += amount;

        red.latestWithdrawTime = (now / _freeDuration) * _freeDuration;

        _EInc.API_MoveToken(address(_EInc),msg.sender,amount);

        emit Event_WithdrawRedress(msg.sender,amount,red.withdrawed);

        return amount;
    }

    // 指定地址补偿对应的令牌数量
    function API_AddRedress(address who, uint256 amount) external APIMethod {

        if (_lockRedressMapping[who].total == 0) {

            // new
            _lockRedressMapping[who] = LockedRedress(amount,0,(now / _freeDuration) * _freeDuration);

        } else {

            // append
            _lockRedressMapping[who].total += amount;
        }

        emit Event_AddNewRedress(who, amount, _lockRedressMapping[who].total);
    }

   
}
