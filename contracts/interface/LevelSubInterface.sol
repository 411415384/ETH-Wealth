pragma solidity >=0.5.0 <0.6.0;

interface LevelSubInterface {

    // 获取指定地址的团队领导级别
    function LevelOf(address _owner) external view returns (uint256 lv);

    // 只更新用户自己的游戏等级时，检查他们是否满足更新条件，不牵连游戏等级的推荐。如果他们的推荐符合更新条件，则调用此方法来升级他们的级别。
    function CanUpgradeLv( address _rootAddr ) external view returns (int);

    // 一次只升级一个级别，如果用户满足允许升级两个级别的条件，则调用此方法两次
    function DoUpgradeLv( ) external returns (uint256);

    // 只用于计算利润，不用于发送利润。至于是否发送利润，上述合同定义了不同级别的计算方法，规则定义为：从根地址向上搜索总共u searchlvlayerdepth级别。如果找到更高级别的用户，则会发送利润
    function ProfitHandle( address _owner, uint256 _amount ) external view returns (uint256 len, address[] memory addrs, uint256[] memory profits);
}
