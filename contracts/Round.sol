pragma solidity >=0.5.0 <0.6.0;

import "./Round.sol";
import "./InternalModule.sol";
import "./ChangerInterface.sol";

contract RoundManager {

    // 轮次历史
    Round[] public RoundHistory;

    // 当前轮次
    Round public CurrenRound;

    // 合约拥有者
    address payable _contractOwner;

    // 最大限额接口
    DepositLimitInterface private _DInc;

    // 统计信息接口
    StatisticsInterface private _SInc;

    // 推荐关系接口
    RecommendInterface private _RInc;

    // 层级接口
    LevelSubInterface private _LInc;

    // 门票接口
    TicketInterface private _TInc;

    // 代币合约接口
    ERC20Interface private _EInc;

    // 手续费接口
    CostInterface private _CInc;

    // 兑换门票接口
    TokenChangerInterface private _changeInc;

    // 静态利润
    uint256 private _staticProfix = 40;

    // 动态利润

    uint256 private _dynamicProfits = 10;

    // 利息利润
    uint256 private _interestProfix = 18;

    // 最低加入限制
    uint256 private _joinMinLimit = 1 ether;

    uint256 private _beforBrokenedCostProp = 0;

    uint256 private _withdrawQuotaMinLimit = 0;

    uint256 private totalWithdraw = 0;

    bool public isBroken;

    modifier OwnerOnly {
        require(msg.sender == _contractOwner);
        _;
    }

    constructor(
        DepositLimitInterface dinc,
        RecommendInterface rinc,
        LevelSubInterface linc,
        TicketInterface tinc,
        ERC20Interface iinc,
        CostInterface cinc,
        StatisticsInterface sinc,
        uint256 s,
        uint256 i,
        TokenChangerInterface changeInc
    ) public {

        _changeInc = changeInc;
        _contractOwner = msg.sender;

        _DInc = dinc;
        _RInc = rinc;
        _LInc = linc;
        _TInc = tinc;
        _EInc = iinc;
        _CInc = cinc;
        _SInc = sinc;

        _staticProfix = s;
        _interestProfix = i;
    }


    // 设置静态利润和动态利润
    function Owner_SetProfitParmas(uint256 st,uint256 dy) external OwnerOnly {
         _staticProfix = st;
         _dynamicProfits = dy;
    }

    // 设置加入最小限制金额
    function Owner_SetJoinMinLimit(uint256 min) external OwnerOnly {
         _joinMinLimit = min;
    }

    // 设置动态利润
    function Owner_SetDynamicProfix(uint256 d,uint256 p) external OwnerOnly {

           _dynamicProfits = d;

           _interestProfix = p;
    }

    // 获取指定游戏轮地址
    function GetRoundHistoryAt(uint256 idx) external view returns (address addr) {
        return address(RoundHistory[idx]);
    }

    // 获取总轮次
    function GetRoundTotal() external view returns (uint256) {
        return RoundHistory.length;
    }

    // 开始新一轮
    function Owner_StartNewRound() external OwnerOnly returns (bool) {
        if (CurrenRound == Round(0x0)) {
            CurrenRound = configNewRound();
            return true;
        } else if (CurrenRound != Round(0x0) && !CurrenRound.isBroken()) {
            return false;
        } else {
            RoundHistory.push(CurrenRound);
            CurrenRound = configNewRound();
            return true;
        }
    }

    // 新一轮配置
    function configNewRound() internal returns (Round newRound) {

        newRound = new Round(_DInc, _RInc, _LInc, _TInc, _EInc, _CInc, _SInc, _staticProfix, _interestProfix);

        InternalModule intermodeule;

        intermodeule.AddAuthAddress(address(newRound));

        return newRound;

    }
}
