// SPDX-License-Identifier: MIT

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.18;

library CollateralManager {
    /**
     * @dev Checks if the given collateral is in the aloowed collateral list.
     * @param allowedCollaterals Array of allowed collateral tokens.
     * @param collateral The collateral token to check.
     * @return bool True if the collateral is allowed, otherwise false.
     */
    function isAllowedCollaterals(IERC20[] storage allowedCollaterals, IERC20 collateral)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < allowedCollaterals.length; i++) {
            if (allowedCollaterals[i] == collateral) return true;
        }
        return false;
    }

    /**
     * @dev Calculate the total collateral locked by user accross all allowed collaterals.
     * @param userCollateralBalances Mapping of user addresses to their collateral balances.
     * @param allowedCollaterals Array of collateral tokens.
     * @param user The addresses of the user to calculate the total collateral for.
     * @return totalCollateral Total collateral locked by user.
     */
    function getUserTotalCollateral(
        mapping(address => mapping(IERC20 => uint256)) storage userCollateralBalances,
        IERC20[] storage allowedCollaterals,
        address user
    ) internal view returns (uint256 totalCollateral) {
        for (uint256 i = 0; i < allowedCollaterals.length; i++) {
            totalCollateral += userCollateralBalances[user][allowedCollaterals[i]];
        }
        return totalCollateral;
    }
}
