pragma solidity >=0.5.0 <0.6.0;

import "./InternalModule.sol";
import "./interface/ERC20Interface.sol";
import "./interface/ChangerInterface.sol"; 

contract TokenChanger is TokenChangerInterface, InternalModule {

    // 每轮共振数据结构体
    struct ChangeRound {
        uint8   roundID;        // 当前轮ID
        uint256 totalToken;     // 当前循环令牌总数
        uint256 propETH;        // 当前轮 1 ETH可转换代币数量
        uint256 changed;        // 换算数量
    }

    // 声明共振结构体对象
    ChangeRound[] _rounds;

    // 代币对象
    ERC20Interface _ERC20Inc;

    // 当前轮次下标
    uint8 public CurrIdX = 0;

    // 最低兑换数量限制
    uint256 public _changeMinLimit = 10000000000000000;

    // 兑换代币事件
    event Event_ChangedToken(address indexed owner, uint8 indexed round, uint256 indexed value);

    // 合约拥有者 
    address payable private _ownerAddress;

    // 构造函数
    constructor(ERC20Interface erc20inc) public {

        _ownerAddress = msg.sender;

        _ERC20Inc = erc20inc;

        _rounds.push(ChangeRound(1,1000000000000000000000000,3000000000000000000000,0));
    }

    // 获取指定的共振轮信息
    function ChangeRoundAt(uint8 rid) external view returns (uint8 roundID, uint256 total, uint256 prop, uint256 changed) {

        require(rid < _rounds.length, "TC_ERR_004");

        return (
        _rounds[rid].roundID,
        _rounds[rid].totalToken,
        _rounds[rid].propETH,
        _rounds[rid].changed);
    }

    // 当前共振轮信息
    function CurrentRound() external view returns (uint8 roundID, uint256 total, uint256 prop, uint256 changed) {

        if ( CurrIdX >= _rounds.length ) {
            return (0, 0, 0, 0);
        }

        return (
        _rounds[CurrIdX].roundID,
        _rounds[CurrIdX].totalToken,
        _rounds[CurrIdX].propETH,
        _rounds[CurrIdX].changed);

    }

    // 获取总轮次
    function RoundCount() external view returns (uint256) {
        return _rounds.length;
    }

    // 根据当前兑换汇率 把eth to token
    function DoChangeToken() external payable {

        //require(msg.value >= _changeMinLimit, "TC_ERR_001");
        require(msg.value % _changeMinLimit == 0, "TC_ERR_002");
        require(CurrIdX < _rounds.length, "TC_ERR_006");
        // require( _roundContractAddress != address(0x0), "TC_ERR_005" );
        ChangeRound storage currRound = _rounds[CurrIdX];

        uint256 minLimitProp = currRound.propETH / (1 ether / _changeMinLimit);
        uint256 ctoken = (msg.value / _changeMinLimit) * minLimitProp;

        require (currRound.changed + ctoken <= currRound.totalToken, "TC_ERR_003");

        // _ERC20Inc.transfer( msg.sender, ctoken);
        _ERC20Inc.API_MoveToken(address(_ERC20Inc), msg.sender, ctoken);

        /// 兑换合约  1eth = EPK ?
        _ownerAddress.transfer(address(this).balance);

        emit Event_ChangedToken(msg.sender,CurrIdX,msg.value);

        if ((currRound.changed + ctoken + minLimitProp) >= currRound.totalToken) {
            
            CurrIdX++;
        }

        currRound.changed += ctoken;
    }
}
