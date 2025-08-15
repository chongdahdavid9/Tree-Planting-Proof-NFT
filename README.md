# 🌳 Tree Planting Proof NFT

A Clarity smart contract that creates verifiable proof of tree planting activities through NFTs on the Stacks blockchain.

## 🌟 Features

- 🏷️ **NFT Certificates**: Mint unique NFTs as proof of tree planting
- 🗺️ **Location Tracking**: Record GPS coordinates for each planted tree
- ✅ **Verification System**: Authorized verifiers can validate tree plantings
- 🌱 **Species Tracking**: Support for multiple tree species with different carbon offset rates
- 📊 **Environmental Impact**: Calculate carbon sequestration and environmental benefits
- 🏆 **Reputation System**: Track planter statistics and reputation scores
- 💰 **Reward System**: Earn rewards for verified tree plantings
- 🔄 **Survival Monitoring**: Update tree survival status over time

## 🛠️ Contract Functions

### Core Functions

#### `plant-tree`
Mint a new NFT representing a planted tree.
```clarity
(plant-tree "oak" 40123456 -74567890 block-height)
```

#### `verify-tree`
Verify a planted tree (authorized verifiers only).
```clarity
(verify-tree u1)
```

#### `transfer`
Transfer an NFT to another address.
```clarity
(transfer u1 'SP123... 'SP456...)
```

### Administrative Functions

#### `add-authorized-verifier`
Add a new authorized verifier (admin only).
```clarity
(add-authorized-verifier 'SP123...)
```

#### `initialize-species-rates`
Initialize carbon offset rates for different tree species.
```clarity
(initialize-species-rates)
```

### Read-Only Functions

#### `get-tree-metadata`
Get detailed information about a planted tree.
```clarity
(get-tree-metadata u1)
```

#### `get-planter-stats`
Get statistics for a specific planter.
```clarity
(get-planter-stats 'SP123...)
```

#### `calculate-environmental-impact`
Calculate environmental impact metrics.
```clarity
(calculate-environmental-impact 'SP123...)
```

## 🌿 Supported Tree Species

| Species | Carbon Offset (kg CO2/year) |
|---------|----------------------------|
| Oak     | 48                        |
| Maple   | 42                        |
| Cedar   | 38                        |
| Pine    | 35                        |
| Other   | 30                        |
| Birch   | 25                        |
| Willow  | 20                        |

## 📋 Usage Instructions

### 1. Deploy the Contract
```bash
clarinet deploy --testnet
```

### 2. Plant a Tree
```bash
clarinet console
(contract-call? .Tree-Planting-Proof-NFT plant-tree "oak" 40123456 -74567890 block-height)
```

### 3. Verify a Tree (as authorized verifier)
```bash
(contract-call? .Tree-Planting-Proof-NFT verify-tree u1)
```

### 4. Check Your Stats
```bash
(contract-call? .Tree-Planting-Proof-NFT get-planter-stats tx-sender)
```

## 🏗️ Development Setup

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet)
- Node.js (for testing)

### Installation
```bash
git clone <repository-url>
cd Tree-Planting-Proof-NFT
clarinet check
```

### Testing
```bash
npm install
npm test
```

## 📊 Data Structure

### Tree Metadata
```clarity
{
  planter: principal,
  tree-species: (string-ascii 50),
  latitude: int,
  longitude: int,
  planted-date: uint,
  verified: bool,
  verifier: (optional principal),
  carbon-offset: uint,
  survival-status: (string-ascii 20)
}
```

### Planter Stats
```clarity
{
  trees-planted: uint,
  trees-verified: uint,
  total-carbon-offset: uint,
  reputation-score: uint
}
```

## 🌍 Environmental Impact

This contract helps track and incentivize reforestation efforts by:

- 📈 **Carbon Tracking**: Calculating CO2 sequestration rates
- 🫁 **Oxygen Production**: Estimating oxygen generation
- 🌬️ **Air Purification**: Measuring air quality improvements
- 🏆 **Gamification**: Rewarding environmental stewardship

## 🔒 Security Features

- ✅ **Authorization Checks**: Only authorized verifiers can verify trees
- 🚫 **Duplicate Prevention**: Prevents multiple trees at same location
- 📅 **Date Validation**: Prevents future-dated plantings
- 🌍 **Coordinate Validation**: Ensures valid GPS coordinates


## 📄 License

This project is licensed under the MIT License.

## 🌱 Environmental Mission

Together, we can create a transparent and verifiable system for global reforestation efforts. Every NFT represents a real tree contributing to our planet's health! 🌍💚
