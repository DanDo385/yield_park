# Yield Park - Troubleshooting Guide

This guide helps resolve common issues when setting up and running Yield Park.

## IDE/Language Server Issues

### TypeScript Errors

#### Error: "Cannot find type definition file for 'node'"

**Solution:**
```bash
cd web
pnpm add -D @types/node
```

### Solidity Language Server Errors

#### Error: "Source 'openzeppelin-contracts/...' not found"

**Root Cause:** The IDE's Solidity language server doesn't know about the remappings.

**Solutions:**

1. **Run the fix script:**
   ```bash
   ./fix-solidity-imports.sh
   ```

2. **Use the workspace file:**
   - Open `yield_park.code-workspace` in VS Code
   - This configures the remappings automatically

3. **Restart VS Code language server:**
   - Command Palette (Cmd+Shift+P) → "Solidity: Restart Language Server"
   - Command Palette → "Developer: Reload Window"

4. **Manual VS Code configuration:**
   - The `.vscode/settings.json` files are already created
   - Restart VS Code after opening the workspace

5. **Verify remappings:**
   ```bash
   cd contracts
   cat remappings.txt
   # Should show:
   # openzeppelin-contracts/=lib/openzeppelin-contracts/contracts/
   # forge-std/=lib/forge-std/src/
   ```

6. **Check dependencies are installed:**
   ```bash
   cd contracts
   ls lib/
   # Should show openzeppelin-contracts and forge-std directories
   ```

**Important Note:** These are IDE display errors only. The contracts compile and work fine with Foundry. The functionality is not affected.

## Build Issues

### "Stack too deep" Compilation Errors

**Solution:** The `foundry.toml` already has `via_ir = true` enabled, which resolves this.

### Import Resolution Errors

**Check:**
1. Dependencies are installed: `forge install openzeppelin/openzeppelin-contracts@v5.0.2`
2. Remappings are correct in `foundry.toml`
3. File paths match the import statements

## Runtime Issues

### "pnpm: command not found"

**Solution:**
```bash
npm install -g pnpm
```

### Deployment Script Errors

**Use the minimal deployment script:**
```bash
cd contracts
export PRIVATE_KEY=0xYOURANVILPK
forge script script/DeployMinimal.s.sol:DeployMinimal --broadcast --rpc-url http://127.0.0.1:8545
```

### Anvil Connection Issues

**Check:**
1. Anvil is running: `anvil`
2. RPC URL is correct: `http://127.0.0.1:8545`
3. Private key matches anvil account

## Common Warnings (Non-Critical)

### Solidity Warnings

These are non-critical and can be ignored:

- **"Function state mutability can be restricted to pure"** - These are in adapter `currentApr()` functions that return 0
- **"Unused function parameter"** - Some deployment script parameters are unused

### TypeScript Warnings

- **"Package version updates available"** - These are just notifications about newer versions

## Quick Fixes

### Reset Everything
```bash
# Clean and reinstall
cd contracts
forge clean
forge install openzeppelin/openzeppelin-contracts@v5.0.2
forge install foundry-rs/forge-std@v1.9.6

# Reinstall dependencies
cd ../agent && pnpm install
cd ../web && pnpm install
```

### Verify Setup
```bash
# Test contracts compile
cd contracts
forge build src/

# Test deployment
export PRIVATE_KEY=0xYOURANVILPK
forge script script/DeployMinimal.s.sol:DeployMinimal --dry-run
```

## IDE Recommendations

### VS Code Extensions
Install these extensions for the best experience:

- **Solidity** (JuanBlanco.solidity)
- **TypeScript and JavaScript Language Features** (built-in)
- **Tailwind CSS IntelliSense** (bradlc.vscode-tailwindcss)
- **Prettier** (esbenp.prettier-vscode)

### Workspace Setup
1. Open `yield_park.code-workspace` in VS Code
2. This automatically configures:
   - Solidity remappings
   - TypeScript settings
   - Multi-root workspace
   - Recommended extensions

## Getting Help

If you're still having issues:

1. **Check the logs:** Look at the specific error messages
2. **Verify dependencies:** Ensure all packages are installed
3. **Test minimal setup:** Try the `DeployMinimal.s.sol` script first
4. **Check versions:** Ensure you're using compatible versions

## Environment Checklist

Before running, verify:

- [ ] Node.js installed (v18+)
- [ ] pnpm installed globally
- [ ] Foundry installed
- [ ] Anvil running (for local testing)
- [ ] All dependencies installed (`pnpm install` in each workspace)
- [ ] OpenZeppelin contracts installed (`forge install` in contracts/)
- [ ] VS Code workspace opened (`yield_park.code-workspace`)
