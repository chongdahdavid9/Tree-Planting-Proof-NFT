import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet/index.ts';
import { assertEquals } from 'https://deno.land/std/testing/asserts.ts';

Clarinet.test({
    name: "Initialize contract with admin and treasury",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const admin = accounts.get('deployer')!;
        const treasury = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'initialize', [
                types.principal(admin.address),
                types.principal(treasury.address)
            ], admin.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Test setting verifier
        let block2 = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'set-verifier', [
                types.principal(treasury.address),
                types.bool(true)
            ], admin.address)
        ]);
        
        block2.receipts[0].result.expectOk().expectBool(true);
        
        // Verify the verifier was set
        let verifierResult = chain.callReadOnlyFn('tree-planting-proof-nft', 'is-verifier', [
            types.principal(treasury.address)
        ], admin.address);
        
        verifierResult.result.expectBool(true);
    },
});

Clarinet.test({
    name: "Mint tree successfully",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const admin = accounts.get('deployer')!;
        const planter = accounts.get('wallet_1')!;
        
        // Initialize first
        let initBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'initialize', [
                types.principal(admin.address),
                types.principal(admin.address)
            ], admin.address)
        ]);
        
        // Mint a tree
        let block = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'mint-tree', [
                types.ascii("oak"),
                types.ascii("Central Park, NYC"),
                types.some(types.utf8("https://example.com/tree/1"))
            ], planter.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        // Check owner
        let ownerResult = chain.callReadOnlyFn('tree-planting-proof-nft', 'owner-of', [
            types.uint(1)
        ], planter.address);
        
        ownerResult.result.expectOk().expectSome().expectPrincipal(planter.address);
        
        // Check planter stats
        let statsResult = chain.callReadOnlyFn('tree-planting-proof-nft', 'get-planter-stats', [
            types.principal(planter.address)
        ], planter.address);
        
        const stats = statsResult.result.expectTuple();
        assertEquals(stats['planted'], types.uint(1));
        assertEquals(stats['reputation'], types.int(1));
    },
});

Clarinet.test({
    name: "Mint with invalid species should fail",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const admin = accounts.get('deployer')!;
        const planter = accounts.get('wallet_1')!;
        
        // Initialize first
        let initBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'initialize', [
                types.principal(admin.address),
                types.principal(admin.address)
            ], admin.address)
        ]);
        
        // Try to mint with unknown species
        let block = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'mint-tree', [
                types.ascii("unknown"),
                types.ascii("Somewhere"),
                types.none()
            ], planter.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(106);
    },
});

Clarinet.test({
    name: "Verify tree by authorized verifier",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const admin = accounts.get('deployer')!;
        const planter = accounts.get('wallet_1')!;
        const verifier = accounts.get('wallet_2')!;
        
        // Initialize and setup
        let setupBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'initialize', [
                types.principal(admin.address),
                types.principal(admin.address)
            ], admin.address),
            Tx.contractCall('tree-planting-proof-nft', 'set-verifier', [
                types.principal(verifier.address),
                types.bool(true)
            ], admin.address)
        ]);
        
        // Mint tree
        let mintBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'mint-tree', [
                types.ascii("oak"),
                types.ascii("Central Park"),
                types.none()
            ], planter.address)
        ]);
        
        // Verify tree
        let verifyBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'verify-tree', [
                types.uint(1)
            ], verifier.address)
        ]);
        
        verifyBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Check tree is verified
        let treeResult = chain.callReadOnlyFn('tree-planting-proof-nft', 'get-tree', [
            types.uint(1)
        ], admin.address);
        
        const tree = treeResult.result.expectOk().expectSome().expectTuple();
        assertEquals(tree['verified'], types.bool(true));
        
        // Check planter stats updated
        let statsResult = chain.callReadOnlyFn('tree-planting-proof-nft', 'get-planter-stats', [
            types.principal(planter.address)
        ], admin.address);
        
        const stats = statsResult.result.expectTuple();
        assertEquals(stats['verified'], types.uint(1));
        assertEquals(stats['reputation'], types.int(3)); // 1 for planting + 2 for verification
    },
});

Clarinet.test({
    name: "Non-verifier cannot verify tree",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const admin = accounts.get('deployer')!;
        const planter = accounts.get('wallet_1')!;
        const nonVerifier = accounts.get('wallet_2')!;
        
        // Initialize
        let initBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'initialize', [
                types.principal(admin.address),
                types.principal(admin.address)
            ], admin.address)
        ]);
        
        // Mint tree
        let mintBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'mint-tree', [
                types.ascii("pine"),
                types.ascii("Forest"),
                types.none()
            ], planter.address)
        ]);
        
        // Try to verify without being a verifier
        let verifyBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'verify-tree', [
                types.uint(1)
            ], nonVerifier.address)
        ]);
        
        verifyBlock.receipts[0].result.expectErr().expectUint(101);
    },
});

Clarinet.test({
    name: "List tree for adoption and adopt it",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const admin = accounts.get('deployer')!;
        const planter = accounts.get('wallet_1')!;
        const verifier = accounts.get('wallet_2')!;
        const adopter = accounts.get('wallet_3')!;
        
        // Setup
        let setupBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'initialize', [
                types.principal(admin.address),
                types.principal(admin.address)
            ], admin.address),
            Tx.contractCall('tree-planting-proof-nft', 'set-verifier', [
                types.principal(verifier.address),
                types.bool(true)
            ], admin.address)
        ]);
        
        // Mint and verify tree
        let treeBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'mint-tree', [
                types.ascii("maple"),
                types.ascii("Garden"),
                types.none()
            ], planter.address),
            Tx.contractCall('tree-planting-proof-nft', 'verify-tree', [
                types.uint(1)
            ], verifier.address)
        ]);
        
        // List for adoption
        let listBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'list-for-adoption', [
                types.uint(1),
                types.uint(1000000) // 1 STX
            ], planter.address)
        ]);
        
        listBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Adopt tree
        let adoptBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'adopt-tree', [
                types.uint(1)
            ], adopter.address)
        ]);
        
        adoptBlock.receipts[0].result.expectOk().expectUint(1);
        
        // Check tree has adopter and no adoption price
        let treeResult = chain.callReadOnlyFn('tree-planting-proof-nft', 'get-tree', [
            types.uint(1)
        ], admin.address);
        
        const tree = treeResult.result.expectOk().expectSome().expectTuple();
        assertEquals(tree['adopter'], types.some(types.principal(adopter.address)));
        assertEquals(tree['adoption-price'], types.none());
    },
});

Clarinet.test({
    name: "Transfer tree ownership",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const admin = accounts.get('deployer')!;
        const planter = accounts.get('wallet_1')!;
        const recipient = accounts.get('wallet_2')!;
        
        // Initialize
        let initBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'initialize', [
                types.principal(admin.address),
                types.principal(admin.address)
            ], admin.address)
        ]);
        
        // Mint tree
        let mintBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'mint-tree', [
                types.ascii("birch"),
                types.ascii("Backyard"),
                types.none()
            ], planter.address)
        ]);
        
        // Transfer tree
        let transferBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'transfer', [
                types.uint(1),
                types.principal(recipient.address)
            ], planter.address)
        ]);
        
        transferBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Check new owner
        let ownerResult = chain.callReadOnlyFn('tree-planting-proof-nft', 'owner-of', [
            types.uint(1)
        ], admin.address);
        
        ownerResult.result.expectOk().expectSome().expectPrincipal(recipient.address);
    },
});

Clarinet.test({
    name: "Carbon calculation updates over time",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const admin = accounts.get('deployer')!;
        const planter = accounts.get('wallet_1')!;
        
        // Initialize
        let initBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'initialize', [
                types.principal(admin.address),
                types.principal(admin.address)
            ], admin.address)
        ]);
        
        // Mint tree
        let mintBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'mint-tree', [
                types.ascii("oak"), // 48 kg per year coefficient
                types.ascii("Location"),
                types.none()
            ], planter.address)
        ]);
        
        // Fast forward some blocks (simulate time passing)
        chain.mineEmptyBlockUntil(52560 + 1); // More than 1 year
        
        // Update carbon
        let updateBlock = chain.mineBlock([
            Tx.contractCall('tree-planting-proof-nft', 'update-carbon', [
                types.uint(1)
            ], planter.address)
        ]);
        
        // Should return calculated carbon (48 kg for 1+ years)
        updateBlock.receipts[0].result.expectOk().expectUint(48);
        
        // Check tree carbon updated
        let treeResult = chain.callReadOnlyFn('tree-planting-proof-nft', 'get-tree', [
            types.uint(1)
        ], admin.address);
        
        const tree = treeResult.result.expectOk().expectSome().expectTuple();
        assertEquals(tree['carbon-kg'], types.uint(48));
    },
});
