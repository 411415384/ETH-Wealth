pragma solidity >=0.5.0 <0.6.0;

import "./interface/LuckAssetsPoolInterface.sol";
import "./InternalModule.sol";

contract LuckAssetsPool is LuckAssetsPoolInterface, InternalModule {

    struct Invest {

        address who;

        uint256 when;

        uint256 amount;

        bool rewardable;
    }

    // 分配比 (%)
    uint256 public _inPoolProp = 5;

    // 投资历史
    Invest[] public _investList;

    // 奖励最后1000人
    uint256 public rewardsCount = 1000;

    // 默认 101-1000 1倍奖励
    uint256 public defualtProp = 1;

    // 特殊排名奖励，使用最后一位数字x，下标0是第一个倒数倍数
    mapping(uint256 => uint256) public specialRewardsDescMapping;

    // 记录可从相应地址提取的eth的数量
    mapping(address => uint256) public rewardsAmountMapping;

    constructor() public {
        // 倒数第一 10倍奖励
        specialRewardsDescMapping[0] = 10;

        // 2-10个玩家，5倍
        for(uint256 i=1;i<10;i++){
            specialRewardsDescMapping[i] = 5;
        }

        // 11-100个玩家，4倍
        for(uint256 i=10;i<100;i++){
            specialRewardsDescMapping[i] = 2;
        }

        // 101-500个玩家，3倍
        // for(uint256 i=100;i<500;i++){
        //     specialRewardsDescMapping[i] = 3;
        // }

        // 501-1000个玩家，2倍
        // for(uint256 i=500;i<1000;i++){
        //     specialRewardsDescMapping[i] = defualtProp;
        // }

    }


    // 设置特殊某个地址的奖励倍数
    function Owner_SetRewardsMulValue(uint256 desci,uint256 mulValue) public OwnerOnly {
            specialRewardsDescMapping[desci] = mulValue;
    }

    // 设置奖金池默认奖励倍数
    function Owner_SetInPoolProp(uint256 p) public OwnerOnly {

         _inPoolProp = p;
    }

     // 设置奖励最后多少人数
    function Owner_SetRewardsCount(uint256 c) public OwnerOnly {
        rewardsCount = c;
    }


    /// 得到我的奖励价格
    function RewardsAmount() external view returns (uint256) {
        return rewardsAmountMapping[msg.sender];
    }

    /// 提取我所有的奖励
    function WithdrawRewards() external returns (uint256) {

        require(rewardsAmountMapping[msg.sender] > 0, "No Rewards");

        // DAO 漏洞防御
        uint256 size;
        address payable safeAddr = msg.sender;
        assembly {size := extcodesize(safeAddr)}
        require(size == 0, "DAO_Warning");

        uint256 amount = rewardsAmountMapping[msg.sender];
        rewardsAmountMapping[msg.sender] = 0;
        safeAddr.transfer(amount);

        return amount;
    }

    // 获取分配比例
    function InPoolProp() external view returns (uint256) {
        return _inPoolProp;
    }

    // 添加到投入历史列表
    function API_AddLatestAddress(address owner, uint256 amount) external APIMethod {
        _investList.push(Invest(owner, now, amount, false));
    }

    // 奖励幸运人员
    function API_WinningThePrize() external APIMethod {

        uint256 contractBalance = address(this).balance;

        for (uint256 i = (_investList.length - 1); !( i <= 1 || i <= (_investList.length - rewardsCount)); i = (i - 1)) {

            uint256 descIndex = (_investList.length - i) - 1;

            Invest storage invest = _investList[i];

            if (invest.rewardable) {
                continue;
            }

            invest.rewardable = true;

            uint256 rewardMul = specialRewardsDescMapping[descIndex];
            if (rewardMul == 0) {
                rewardMul = defualtProp;
            }

            uint256 rewardAmount = invest.amount * rewardMul;

            if (rewardAmount < contractBalance) {

                rewardsAmountMapping[invest.who] = rewardAmount;
                contractBalance -= rewardAmount;

            } else {

                rewardsAmountMapping[invest.who] = contractBalance;
                break;

            }
        }

    }

   

    function () payable external {

    }
}
