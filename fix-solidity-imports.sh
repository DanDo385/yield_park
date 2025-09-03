#!/bin/bash

echo "🔧 Fixing Solidity import issues..."

# Check if we're in the right directory
if [ ! -d "contracts" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

# Check if dependencies are installed
if [ ! -d "contracts/lib/openzeppelin-contracts" ]; then
    echo "📦 Installing OpenZeppelin contracts..."
    cd contracts
    forge install openzeppelin/openzeppelin-contracts@v5.0.2
    forge install foundry-rs/forge-std@v1.9.6
    cd ..
fi

# Verify remappings
echo "🔍 Checking remappings..."
if [ -f "contracts/remappings.txt" ]; then
    echo "✅ remappings.txt exists"
    cat contracts/remappings.txt
else
    echo "❌ remappings.txt not found"
    exit 1
fi

# Test compilation
echo "🔨 Testing compilation..."
cd contracts
if forge build src/; then
    echo "✅ Contracts compile successfully"
else
    echo "❌ Compilation failed"
    exit 1
fi
cd ..

echo ""
echo "🎉 Setup complete! Try these steps:"
echo "1. Close VS Code completely"
echo "2. Open the workspace: yield_park.code-workspace"
echo "3. If errors persist, try:"
echo "   - Command Palette (Cmd+Shift+P) -> 'Solidity: Restart Language Server'"
echo "   - Command Palette -> 'Developer: Reload Window'"
echo ""
echo "📝 Note: The contracts compile fine with Foundry, so the functionality works."
echo "   The IDE errors are just language server configuration issues."
