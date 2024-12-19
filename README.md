# Pegify: Bitcoin-backed Stablecoin Platform

## Overview
Pegify is a decentralized finance (DeFi) platform that enables users to mint stablecoins backed by Bitcoin collateral on the Stacks blockchain. The platform implements an over-collateralized lending mechanism where users can lock their Bitcoin as collateral to mint PUSD (Pegify USD) stablecoins.

## Key Features
- Mint stablecoins backed by Bitcoin collateral
- 150% minimum collateralization ratio
- Liquidation threshold at 120% collateral ratio
- Decentralized price oracle integration
- Liquidation mechanism for undercollateralized positions
- 0.5% annual stability fee

## Smart Contract Functions

### User Functions

#### `create-vault`
Creates a new vault for the user with initial collateral.
```clarity
(create-vault (collateral-amount uint))
```

#### `mint-stablecoin`
Mints new stablecoins against deposited collateral.
```clarity
(mint-stablecoin (amount uint))
```

#### `repay-stablecoin`
Repays minted stablecoins to reduce debt.
```clarity
(repay-stablecoin (amount uint))
```

#### `liquidate-vault`
Liquidates an undercollateralized vault.
```clarity
(liquidate-vault (owner principal))
```

### Read-Only Functions

#### `get-vault`
Returns vault information for a given owner.
```clarity
(get-vault (owner principal))
```

#### `get-collateral-ratio`
Calculates the current collateralization ratio for a vault.
```clarity
(get-collateral-ratio (owner principal))
```

## Security Considerations
1. The contract implements strict collateralization requirements
2. Liquidation mechanism protects system solvency
3. Admin controls limited to price oracle updates
4. Critical operations protected by assertion checks

## Requirements
- Stacks blockchain environment
- Clarity smart contract support
- Price oracle integration

## Testing
To test the contract:
1. Deploy to testnet
2. Create a vault with test BTC
3. Mint stablecoins
4. Verify collateral ratios
5. Test liquidation scenarios


## Contributing
We welcome contributions! Please submit pull requests for any improvements.

