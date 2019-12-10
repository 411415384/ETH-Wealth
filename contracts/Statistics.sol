pragma solidity >=0.5.0 <0.6.0;

import "./interface/StatisticsInterface.sol";
import "./InternalModule.sol";

contract Statistics is StatisticsInterface, InternalModule {

    // 记录每个地址静态收益
    mapping(address => uint256) _staticProfixTotalMapping;

    // 记录每个地址动态收益
    mapping(address => uint256) _dynamicProfixTotalMapping;

    // 记录每个地址是否参与
    mapping(address => bool) _playerAddresses;

    // 参与玩家总数
    uint256 public JoinedPlayerTotalCount = 0;

    // 参与游戏总次数
    uint256 public JoinedGameTotalCount = 0;

    // 提取所有eth总金额
    uint256 public AllWithdrawEtherTotalCount = 0;

    // 有效玩家总数
    uint256 public ActivateUserCount = 0;

    // 参与游戏结构体
    struct Deposited {

        uint256 startTime;

        uint256 endTime;

        uint256 joinEther;

        bool redressable;
    }

   // 动态利润结构体
    struct DyProfit {
        address formAddress;
        uint256 value;
        bool managerType;
        uint256 time;
    }

    // 记录动态历史列表
    mapping(address => DyProfit[]) _dyHistory;

    // 记录参与历史列表
    mapping(address => Deposited[]) _joinedHistory;

    constructor() public {

    }

    // 获取动态历史记录
    function GetDyHistory(uint256 offset, uint256 size) external view
    returns (
        uint256 len,
        address[] memory froms,
        uint256[] memory values,
        bool[] memory mtypes,
        uint256[] memory times
    ) {

        DyProfit[] memory lists = _dyHistory[msg.sender];
        len = lists.length;

        uint256 rsize = size;

        if (offset + size > len) {
            rsize = len - offset;
        }

        froms = new address[](rsize);
        values = new uint256[](rsize);
        mtypes = new bool[](rsize);
        times = new uint256[](rsize);

        for (uint256 i = offset; (i < offset + rsize && i < len); i++) {
            froms[i] = lists[i].formAddress;
            values[i] = lists[i].value;
            mtypes[i] = lists[i].managerType;
            times[i] = lists[i].time;
        }

    }

    // 获取参与历史记录
    function GetJoinedHistory() external view
    returns (
        uint256 len,
        uint256[] memory stime,
        uint256[] memory etime,
        uint256[] memory values) {

        Deposited[] memory lists = _joinedHistory[msg.sender];
        len = lists.length;

        stime = new uint256[](len);
        etime = new uint256[](len);
        values = new uint256[](len);

        for (uint i = 0; i < len; i++) {
            stime[i] = lists[i].startTime;
            etime[i] = lists[i].endTime;
            values[i] = lists[i].joinEther;
        }

    }

    // 获取静态总利润
    function GetStaticProfitTotalAmount() external view returns (uint256) {
        return _staticProfixTotalMapping[msg.sender];
    }

    // 获取动态总利润
    function GetDynamicProfitTotalAmount() external view returns (uint256) {
        return _dynamicProfixTotalMapping[msg.sender];
    }

    // 记录玩家有效次数
    function API_NewPlayer(address player) external APIMethod {

        if (_playerAddresses[player] == false){
            _playerAddresses[player] = true;
            JoinedPlayerTotalCount ++;
        }
    }

    // 记录参与有效次数
    function API_NewJoin(address who, uint256 when, uint256 value) external APIMethod {

        Deposited[] storage depositList = _joinedHistory[who];

        depositList.push(Deposited(when,0,value,false));

        JoinedGameTotalCount++;
    }

    // 指定地址设置某一轮的结算
    function API_NewSettlement(address who, uint256 when) external APIMethod {

        Deposited[] storage depositList = _joinedHistory[who];

        depositList[depositList.length - 1].endTime = when;
    }

    // 记录静态投入参与总金额
    function API_AddStaticTotalAmount(address player, uint256 value) external APIMethod {
        _staticProfixTotalMapping[player] += value;
        AllWithdrawEtherTotalCount += value;
    }

    // 记录动态参与总金额
    function API_AddDynamicTotalAmount(address player, uint256 value) external APIMethod {
        _dynamicProfixTotalMapping[player] += value;
        AllWithdrawEtherTotalCount += value;
    }

    // 添加新的动态利润记录
    function API_PushNewDyProfit(address who, address where, uint256 value, bool mtype) external APIMethod {
        _dyHistory[who].push(DyProfit(where, value, mtype, now));
    }

    // 激活用户总数
    function API_AddActivate() external APIMethod {
        ActivateUserCount ++;
    }

}
