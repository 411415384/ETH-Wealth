pragma solidity >=0.5.0 <0.6.0;

interface RecommendInterface {

    // 获取该级别的所有推荐地址列表
    function RecommendList(address _owner, uint256 depth) external view returns (address[] memory list);

    // 获取我的推荐
    function GetIntroducer(address _owner) external view returns (address);

    // 获取对应的钱包地址绑定推荐码
    function ShortCodeToAddress(bytes6 shortCode) external view returns (address);

    // 检查地址是否与推荐码对应
    function AddressToShortCode(address _addr) external view returns (bytes6);

    // 获取相应地址的团队成员总数
    function TeamMemberTotal(address _addr) external view returns (uint256);

    // 获取团队的有效用户数
    function ValidMembersCountOf(address _addr) external view returns (uint256);

    // 获取一个地址邀请的总数的eth
    function InvestTotalEtherOf(address _addr) external view returns (uint256);

    // 获取一个地址直接邀请的有效用户数
    function DirectValidMembersCount(address _addr) external view returns (uint256);

    // 确定它是否为有效用户
    function IsValidMember(address _addr) external view returns (bool);

    // 将一个标记为有效用户并写入级别合同，并记录该用户投资的ETH总数
    function API_MarkValid(address _addr, uint256 _evalue) external;

    // 绑定重新编译并注册短重新推荐码
    function API_BindEx(address _owner, address _recommer, bytes6 shortCode) external;

}
