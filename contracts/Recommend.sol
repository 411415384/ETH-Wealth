pragma solidity >=0.5.0 <0.6.0;

import "./interface/RecommendInterface.sol";
import "./InternalModule.sol";

contract Recommend is RecommendInterface, InternalModule {

    // 最大邀请关系层级
    uint256 private _recommendDepthLimit = 20;

    // 邀请关系绑定(地址对地址)
    mapping (address => address) _recommerMapping;

    // Search structure down
    mapping (address => mapping(uint256 => address[])) _recommerList;

    // 地址有效会员总数
    mapping (address => uint256) _vaildMemberCountMapping;

    // 地址是否有效
    mapping (address => bool) _vaildMembersMapping;

    // 记录该地址投资的ETH总数
    mapping (address => uint256) _despositTotalMapping;

    // 记录该地址邀请人总数
    mapping (address => uint256) _recommerCountMapping;

    // 邀请码对应的地址
    mapping (bytes6 => address) _shortCodeMapping;

    // 地址对应的邀请码
    mapping (address => bytes6) _addressShotCodeMapping;

    // 构造函数
    constructor(uint256 depth) public {

        _recommendDepthLimit = depth;

        address rootAddr = address(0x4013Cbe2F47F06362E7D094bdEe100986eeDe545);
        bytes6 rootCode = 0x303030303030; // 000000

        /// 设置默认的推荐关系
        internalBind(rootAddr,address(0x14));
        _shortCodeMapping[rootCode] = rootAddr;
        _addressShotCodeMapping[rootAddr] = rootCode;
    }

    // 获取最大层级
    function GetDepth() external view returns (uint256 depth) {
      return _recommendDepthLimit;
    }

    // 内部绑定
    function internalBind(address a, address r) internal returns (bool) {

        _recommerMapping[a] = r;

        address parent = r;

        for (uint i = 0; i < _recommendDepthLimit; i++) {

            _recommerList[parent][i].push(a);

            _recommerCountMapping[parent] ++;

            parent = _recommerMapping[parent];

            if (parent == address(0x0)) {
                break;
            }
        }

        return true;
    }

    // 获取我的推荐地址
    function GetIntroducer(address _owner) external view returns (address) {
        return _recommerMapping[_owner];
    }

    // 获取该级别的所有推荐地址列表
    function RecommendList(address _owner, uint256 depth) external view returns ( address[] memory list ) {
        return _recommerList[_owner][depth];
    }

    // 邀请码注册
    function RegisterShortCode(bytes6 shortCode) external returns (bool) {

        require(_shortCodeMapping[shortCode] == address(0x0), "RCM_ERR_001" );

        require(_addressShotCodeMapping[msg.sender] == bytes6(0x0), "RCM_ERR_002" );

        _shortCodeMapping[shortCode] = msg.sender;

        _addressShotCodeMapping[msg.sender] = shortCode;

        return true;
    }

    // 根据推荐码获取对应的钱包地址
    function ShortCodeToAddress(bytes6 shortCode) external view returns (address) {
        return _shortCodeMapping[shortCode];
    }

    // 根据钱包地址获取对应的推荐码
    function AddressToShortCode(address _addr) external view returns (bytes6) {
        return _addressShotCodeMapping[_addr];
    }

    // 获取相应地址的团队成员总数
    function TeamMemberTotal(address _addr) external view returns (uint256) {
        return _recommerCountMapping[_addr];
    }

    // 根据地址检查是否是有效会员
    function IsValidMember(address _addr) external view returns (bool) {
        return _vaildMembersMapping[_addr];
    }

    // 根据地址获取团队的有效用户数
    function ValidMembersCountOf(address _addr) external view returns (uint256) {
        return _vaildMemberCountMapping[_addr];
    }

    // 获取一个地址邀请的投入总数的eth
    function InvestTotalEtherOf(address _addr) external view returns (uint256) {
        return _despositTotalMapping[_addr];
    }

    // 获取一个地址直接邀请的有效用户数
    function DirectValidMembersCount(address _addr) external view returns (uint256){

        uint256 count = 0;

        address[] storage rlist = _recommerList[_addr][0];

        for (uint i = 0; i < rlist.length; i++) {

            if (_vaildMembersMapping[rlist[i]]) {
                count ++;
            }

        }

        return count;
    }

    // 绑定关系
    function Bind(address sender, address _recommer) internal returns (bool) {

        require( _recommer != sender, "RCM_ERR_003" );

        require( _recommerMapping[sender] == address(0x0), "RCM_ERR_004" );

        require( _recommerMapping[_recommer] != address(0x0), "RCM_ERR_005");

        uint256 rsize;
        uint256 ssize;
        address safeAddr = sender;
        assembly {
            rsize := extcodesize(_recommer)
            ssize := extcodesize(safeAddr)
        }

        require(rsize == 0 && ssize == 0, "DAO_Warning");

        _recommerMapping[sender] = _recommer;

        address parent = _recommer;

        for (uint i = 0; i < _recommendDepthLimit; i++) {

            _recommerList[parent][i].push(sender);

            _recommerCountMapping[parent] ++;

            parent = _recommerMapping[parent];

            if (parent == address(0x0)) {
                break;
            }
        }

        return true;
    }

    // 将一个标记为有效用户并写入级别合同，并记录该用户投资的ETH总数
    function API_MarkValid(address _addr, uint256 _evalue) external APIMethod {

        if (_vaildMembersMapping[_addr] == false) {

            address parent = _recommerMapping[_addr];

            for ( uint i = 0; i < _recommendDepthLimit; i++ ) {

                _vaildMemberCountMapping[parent] ++;

                parent = _recommerMapping[parent];

                if ( parent == address(0x0) ) {
                    break;
                }
            }

            _vaildMembersMapping[_addr] = true;
        }

        _despositTotalMapping[_addr] += _evalue;
    }

    // 根据邀请码进行绑定
    function API_BindEx(address _owner, address _recommer, bytes6 shortCode) external {

        require(_shortCodeMapping[shortCode] == address(0x0), "RCM_ERR_001");

        require(_addressShotCodeMapping[_owner] == bytes6(0x0), "RCM_ERR_002");

        _shortCodeMapping[shortCode] = _owner;

        _addressShotCodeMapping[_owner] = shortCode;

        Bind(_owner,_recommer);
    }
}
