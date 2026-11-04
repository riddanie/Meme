# Roblox Mutation Game - Week 1 Infrastructure

## Project Structure

```
src/
├── server/
│   ├── services/          # Knit services (DataService, MutationService, ArenaService, AnalyticsService)
│   ├── modules/           # ProfileService wrapper
│   └── init.server.lua    # Server entry point
├── client/
│   ├── controllers/       # Knit controllers (placeholder)
│   ├── ui/                # UI modules (awaiting Designer specs)
│   └── init.client.lua    # Client entry point
└── shared/
    ├── config/            # GameConfig constants
    ├── types/             # PlayerData type definitions
    ├── utils/             # Utility functions
    └── RemoteEvents.lua   # Networking event definitions
```

## Setup Instructions

### Dependencies (Manual Installation Required)

1. **ProfileService** (v1.0.0+)
   - Source: https://madstudiorblx.github.io/ProfileService/
   - Install to: `ServerScriptService.ProfileService`

2. **Knit Framework** (v1.7.0+)
   - Source: https://github.com/Sleitnick/Knit
   - Install via Wally or manual copy to: `ReplicatedStorage.Packages.Knit`

3. **PartCache** (Coming Week 2)
   - Source: https://github.com/xSwezan/PartCache

4. **GameAnalytics SDK** (Coming Week 2)
   - Source: https://gameanalytics.com/docs/item/roblox-sdk

### Implemented Features (Day 1-2)

- ✅ ProfileService schema with PlayerData structure
- ✅ 4 RemoteEvent stubs (MutationApplied, ArenaTimerTick, PlayerDeath, CosmeticEquipped)
- ✅ DataService (profile loading/unloading, DNA management)
- ✅ MutationService (server-authoritative RNG stub)
- ✅ ArenaService (90s timer + 15s mutation cycle)
- ✅ AnalyticsService (GameAnalytics scaffolding)
- ✅ GameConfig constants

### Next Steps (Day 3-5)

- Implement pity system logic in MutationService
- Integrate actual mutation data (variants, rarities)
- Hook Designer UI specs to RemoteEvents
- Add ragdoll physics system
- Integrate PartCache for ragdoll pooling
- Player death detection and DNA reward distribution

## ProfileService Schema

```lua
PlayerData = {
  MutagenDNA: number,           -- Currency
  UnlockedMutations: {string},  -- Collection array
  MasteryLevels: {[string]: number}, -- Per-mutation XP
  PityCounter: number,          -- Spins since last rare (max 20)
  OwnedCosmetics: {string},     -- VFX variants
  GamepassFlags: {
    StarterPack: bool,
    ChaosMaster: bool,
    RoyalePass: bool
  },
  TotalSpins: number,           -- Analytics
  TotalDeaths: number           -- Analytics
}
```

## Testing Checklist

- [ ] ProfileService loads/unloads on player join/leave
- [ ] Arena timer broadcasts every second (90s countdown)
- [ ] Mutation cycle triggers every 15s
- [ ] RemoteEvents fire without errors
- [ ] Server-authoritative RNG generates mutation IDs

## Notes

- PartCache and GameAnalytics SDK not yet installed (Week 2 scope)
- UI hooks generic, awaiting Designer wireframes (Thread 11)
- Pity system logic stubbed, needs full implementation with DataService integration
