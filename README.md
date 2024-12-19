# Pegify: Bitcoin-backed Stablecoin Platform

## Overview
Pegify is a decentralized finance (DeFi) platform that enables users to mint stablecoins backed by Bitcoin collateral. The platform features vault management, dynamic interest rates, debt refinancing, and staking rewards.

## Key Features
- Bitcoin-collateralized stablecoin minting
- Flexible vault management
- Liquidation protection mechanisms
- Debt refinancing options
- Staking rewards for overcollateralized vaults
- Oracle-based price feeds

## Core Parameters

### Collateralization
- Minimum Collateralization Ratio: 150%
- Liquidation Threshold: 120%
- Minimum Collateral: 100,000 sats
- Maximum Price: 10,000 USD per sat

### Interest and Rewards
- Stability Fee: 0.5% annual rate
- Staking Reward Rate: 2% annual rate
- Minimum Reward Period: ~1/10th year (5,256 blocks)
- Reward Eligibility Threshold: 200% collateralization

## Key Functions

### Vault Management
- `create-vault`: Create a new vault with initial collateral
- `mint-stablecoin`: Mint stablecoins against collateral
- `withdraw-collateral`: Remove excess collateral
- `repay-stablecoin`: Repay minted stablecoins

### Debt Management
- `repay-interest`: Pay accrued interest separately
- `get-collateral-ratio`: Check current collateralization level
- `get-withdrawable-collateral`: Calculate withdrawable collateral

### Rewards System
- `claim-rewards`: Claim accumulated staking rewards
- `get-pending-rewards`: Check available unclaimed rewards

### Administrative
- `update-price-oracle`: Update the price feed (admin only)
- `liquidate-vault`: Liquidate undercollateralized vaults

## Error Codes
```
ERR-NOT-AUTHORIZED (100): Unauthorized access attempt
ERR-INSUFFICIENT-COLLATERAL (101): Collateral below required ratio
ERR-BELOW-LIQUIDATION (102): Vault eligible for liquidation
ERR-VAULT-NOT-FOUND (103): Vault doesn't exist
ERR-WITHDRAWAL-EXCEEDS-AVAILABLE (104): Insufficient withdrawable collateral
ERR-BELOW-MINIMUM-COLLATERAL (105): Below minimum collateral requirement
ERR-INVALID-AMOUNT (106): Invalid transaction amount
ERR-INVALID-PRICE (107): Invalid oracle price
ERR-INSUFFICIENT-PAYMENT (108): Payment amount too low
ERR-NO-REWARDS-AVAILABLE (109): No rewards to claim
ERR-INELIGIBLE-FOR-REWARDS (110): Not eligible for rewards
ERR-INSUFFICIENT-REWARD-PERIOD (111): Minimum reward period not met
```

## Vault Lifecycle

1. **Creation**
   - User creates vault with minimum collateral
   - Initial debt is zero

2. **Active Usage**
   - Mint stablecoins against collateral
   - Maintain healthy collateralization ratio
   - Earn rewards when overcollateralized
   - Pay interest and manage debt

3. **Maintenance**
   - Monitor collateralization ratio
   - Claim staking rewards
   - Refinance debt as needed
   - Add/withdraw collateral

4. **Closure/Liquidation**
   - Repay all debt to close vault
   - Automatic liquidation if under 120% collateralized

## Best Practices

### For Users
1. Maintain healthy collateralization above 200% to earn rewards
2. Regularly claim rewards to compound returns
3. Monitor interest accrual and refinance when beneficial
4. Keep buffer above liquidation threshold

### For Integrators
1. Always check function return values
2. Implement proper error handling
3. Monitor oracle prices for vault health
4. Calculate total debt including accrued interest

## Smart Contract Security

The contract implements several security measures:
- Strict access controls
- Input validation
- Safe math operations
- Minimum thresholds
- Price caps
- Liquidation safeguards

## Future Development

Planned features and improvements:
- Multiple collateral types
- Governance mechanisms
- Flash loan prevention
- Enhanced reward mechanisms
- Dynamic interest rates
