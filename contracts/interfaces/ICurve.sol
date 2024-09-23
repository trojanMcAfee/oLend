// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


interface ICrvRouter {
    function exchange(
        address[11] memory route,
        uint[5][5] memory swap_params,
        uint amount,
        uint expected,
        address[5] memory pools,
        address receiver
    ) external returns(uint);

    function get_dy(
        address[11] memory route,
        uint[5][5] memory swap_params,
        uint amount,
        address[5] memory _pools
    ) external view returns(uint); 
} 

interface ICrvAddressProvider {
    function get_address(uint id) external view returns(address);
}

interface ICrvMetaRegistry {
    function find_pools_for_coins(address from, address to) external view returns(address[] memory);
    function find_pool_for_coins(address from, address to, uint i) external view returns(address);
}

interface IPoolCrv {}