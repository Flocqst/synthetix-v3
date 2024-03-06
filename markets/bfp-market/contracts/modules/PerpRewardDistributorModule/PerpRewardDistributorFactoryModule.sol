//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IRewardDistributor} from "@synthetixio/main/contracts/interfaces/external/IRewardDistributor.sol";
import {IRewardsManagerModule} from "@synthetixio/main/contracts/interfaces/IRewardsManagerModule.sol";
import {OwnableStorage} from "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import {IPerpRewardDistributorFactoryModule} from "../../interfaces/IPerpRewardDistributorFactoryModule.sol";
import {IPerpRewardDistributor} from "../../interfaces/IPerpRewardDistributor.sol";
import {PerpMarketConfiguration} from "../../storage/PerpMarketConfiguration.sol";
import {ErrorUtil} from "../../utils/ErrorUtil.sol";

contract PerpRewardDistributorFactoryModule is IPerpRewardDistributorFactoryModule {
    using Clones for address;

    // --- Mutations --- //

    /**
     * @inheritdoc IPerpRewardDistributorFactoryModule
     */
    function createRewardDistributor(
        IPerpRewardDistributorFactoryModule.CreatePerpRewardDistributorParameters calldata data
    ) external returns (address) {
        OwnableStorage.onlyOwner();
        PerpMarketConfiguration.GlobalData storage globalConfig = PerpMarketConfiguration.load();

        // A reward token to distribute must exist.
        if (data.token == address(0)) {
            revert ErrorUtil.ZeroAddress();
        }

        // Collaterals in a V3 pool can be delegated to a specific market. `collateralTypes` are the pool collateral
        // addresses delegated to this market. They're tracked here so downstream operations post creation can infer
        // pct of `token` to distribute amongst delegated collaterals. For example, during liquidation we calc to total
        // dollar value of delegated collateral and distribute the reward token proportionally to each collateral.
        //
        // There must be at least one pool collateral type available otherwise this reward distribute cannot distribute.
        uint256 collateralTypesLength = data.collateralTypes.length;
        if (collateralTypesLength == 0) {
            revert ErrorUtil.ZeroLength();
        }
        for (uint256 i = 0; i < collateralTypesLength; ) {
            if (data.collateralTypes[i] == address(0)) {
                revert ErrorUtil.ZeroAddress();
            }
            unchecked {
                ++i;
            }
        }

        // Create a new distributor by cloning an existing implementation.
        address distributorAddress = globalConfig.rewardDistributorImplementation.clone();
        IPerpRewardDistributor distributor = IPerpRewardDistributor(distributorAddress);
        distributor.initialize(
            address(globalConfig.synthetix),
            address(this),
            data.poolId,
            data.collateralTypes,
            data.token,
            data.name
        );

        emit RewardDistributorCreated(distributorAddress);
        return distributorAddress;
    }
}
