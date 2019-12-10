pragma solidity >=0.5.0 <0.6.0;

import "./interface/LevelSubInterface.sol";
import "./interface/RecommendInterface.sol";
import "./InternalModule.sol";

contract LevelSub is LevelSubInterface, InternalModule {

    RecommendInterface  private _recommendInf;

    // 分层机制最大遍历深度限制
    uint256             public _searchReommendDepth = 20;

    // 差分搜索最大深度
    uint256             public _searchLvLayerDepth = 1024;

    // 步长参数，百分比
    uint256[]           public _subProfits = [0, 5, 5, 5, 5];

    // 固定奖励百分比
    uint256             public _equalLvProp = 5;

    // 等级奖励
    uint256             public _equalLvMaxLimit = 3;

    // 级别奖励搜索深度
    uint256             public _equalLvSearchDepth = 10;

    mapping (address => uint256) _ownerLevelsMapping;

    constructor(RecommendInterface recomm) public {
        _recommendInf = recomm;
    }

    // 获取每层级的利润百分比
    function GetLevelSubValues() external view returns (uint256[] memory _values) {
        return _subProfits;
    }

    // 根据地址获取层级
    function LevelOf(address _owner) public view returns (uint256 lv) {
        return _ownerLevelsMapping[_owner];
    }

    // 是否满足更新用户级别的条件
    function CanUpgradeLv(address _rootAddr) public view returns (int) {

        // 如果它已经是最高级别集，则不允许继续升级
        require(_ownerLevelsMapping[_rootAddr] < _subProfits.length - 1, "Level Is Max");

        uint256 effCount = 0;
        address[] memory referees;

        if (_ownerLevelsMapping[_rootAddr] == 0) {

            referees = _recommendInf.RecommendList(_rootAddr, 0);

            for (uint i = 0; i < referees.length; i++) {

                if ( _recommendInf.IsValidMember(referees[i])) {

                    if ( ++effCount >= 10 ) {
                        break;
                    }
                }
            }

            if ( effCount < 10 ) {
                // 表示不满足第一个条件
                return -1;
            }

            if (_recommendInf.InvestTotalEtherOf(msg.sender) < 10 ether) {
                return -2;
            }

            // 团队中有100个活动地址（20层内）
            if ( _recommendInf.ValidMembersCountOf(msg.sender) < 100 ) {
                return -3;
            }

            return 1;
        }
        // Lv.n(n != 0) -> Lv.(n + 1)
        else {

            uint256 targetLv = _ownerLevelsMapping[_rootAddr] + 1;

            referees = _recommendInf.RecommendList(_rootAddr, 0);

            for (uint i = 0; i < referees.length; i++) {

                if ( LevelOf(referees[i]) >= targetLv - 1 ) {

                    effCount ++;

                    if ( effCount >= 3 ) {
                        break;
                    }

                    continue;

                } else {

                    // 如果直接推送不满足条件，搜索9层，看看是否有符合条件的用户.
                    // 因为已经搜索了一层直接推送，所以这是19层，所以_searchReommendDepth-1
                    for ( uint d = 0; d < _searchReommendDepth - 1; d++ ) {

                        address[] memory grandchildren = _recommendInf.RecommendList(referees[i], d);

                        for (uint256 z = 0; z < grandchildren.length; z++) {

                            if (LevelOf( grandchildren[z]) >= targetLv - 1) {

                                effCount ++;

                                break;
                            }

                        }

                        if ( effCount >= 3 ) {
                            break;
                        }

                    }

                    if ( effCount >= 3 ) {
                        break;
                    }

                }

            }

            if (effCount >= 3) {

                return int(targetLv);

            } else {

                return -1;
            }

        }
    }

    // 设置某个层级分配比
    function Owner_SetLevelSubValues(uint256 lv,uint256 value) public OwnerOnly {
        _subProfits[lv] = value;
    }

    // add function
    function Owner_SetEqualLvRule(uint256 p,uint256 limit,uint256 depth) public OwnerOnly {
          _equalLvProp = p;
          _equalLvMaxLimit = limit;
          _equalLvSearchDepth = depth;
    }

   // 设置最大推荐层级深度
   function Owner_SetSearchRecommendDepth(uint256 d) public OwnerOnly {
       _searchReommendDepth = d;
   }

   // 设置搜素层级深度
   function Owner_SetLevelSearchDepth(uint256 d) public OwnerOnly {
       _equalLvSearchDepth = d;
   }

    //升级
    function DoUpgradeLv( ) external returns (uint256) {

        int canMakeToTargetLv = CanUpgradeLv(msg.sender);

        if ( canMakeToTargetLv > 0 ) {
            _ownerLevelsMapping[msg.sender] = uint256(canMakeToTargetLv);
        }

        return _ownerLevelsMapping[msg.sender];
    }

    //计算收益，不是只发送提供收益计算，
    //
    //差额收入计算，规则定义为：
    //从根地址中搜索整个searchlvlayerdepth层，然后发送
    //如果您发现一个用户的级别高于您自己，则级别差异。
    //v2:添加等级奖励，规则是：结算用户是最近的管理员
    //n级别l，然后manager是起始节点。
    //最多搜索10层，得到0-3层<=l用户发送n个收益的10%
    function ProfitHandle(address _owner, uint256 _amount) external view
    returns (uint256 len, address[] memory addrs, uint256[] memory profits) {

        uint256[] memory tempProfits = _subProfits;

        address parent = _recommendInf.GetIntroducer(_owner);

        if (parent == address(0x0)) {
            return (0, new address[](0), new uint256[](0));
        }

        /// V1
        // len = _subProfits.length;
        // addrs = new address[](len);
        // profits = new uint256[](len);
        len = _subProfits.length + _equalLvMaxLimit;
        addrs = new address[](len);
        profits = new uint256[](len);

        // 当前层级
        uint256 currlv = 0;

        // 获取推荐人的层级
        uint256 plv = _ownerLevelsMapping[parent];

        address nearestAddr;
        uint256 nearestProfit;

        // 循环结束条件为：
        // 查找时，找到第一个级别为4的用户，应立即停止循环
        for ( uint i = 0; i < _searchLvLayerDepth; i++ ) {

            // 级差收益判断
            // 找到第一个级别比自己高的用户
            ///  尚未收到对应级别的级差
            if (plv > currlv && tempProfits[plv] > 0) {

                uint256 psum = 0;

                for (uint x = plv; x > 0; x--) {

                    psum += tempProfits[x];

                    tempProfits[x] = 0;
                }

                if (psum > 0) {

                    if (nearestAddr == address(0x0) && plv > 1) {
                        nearestAddr = parent;
                        nearestProfit = (_amount * psum) / 100;
                    }

                    addrs[plv] = parent;
                    profits[plv] = (_amount * psum) / 100;
                }
            }

            parent = _recommendInf.GetIntroducer(parent);

            //找到了最高的层级，正确地处理了微分增益，直接停止了环路
            if ( plv >= _subProfits.length - 1 || parent == address(0x0) ) {
                break;
            }

            plv = _ownerLevelsMapping[parent];
        }

        // 统一的奖励判断
        // v2: 添加一个等级奖励，规则是：结算用户是最近的管理员n等级l，
        //     然后manager是起始节点.
        //     最多搜索10层，得到0-3层<=l用户发送n收益p的10%
        uint256 L = _ownerLevelsMapping[nearestAddr];

        if ( nearestAddr != address(0x0) && L > 1 && nearestProfit > 0 ) {

            parent = nearestAddr;

            uint256 indexOffset = _subProfits.length - 1;

            for (uint j = 0; j < _equalLvSearchDepth; j++) {

                parent = _recommendInf.GetIntroducer(parent);
                plv = _ownerLevelsMapping[parent];

                if ( plv <= L && plv > 1 ) {

                    // reached
                    addrs[indexOffset] = parent;
                    profits[indexOffset] = (nearestProfit * _equalLvProp) / 100;

                    if ( indexOffset + 1 >= len ) {
                        break;
                    }

                    indexOffset++;
                }
            }

        }

        return (len, addrs, profits);
    }
}
