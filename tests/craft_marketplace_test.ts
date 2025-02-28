import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged...]

Clarinet.test({
    name: "Ensures proper price validation when listing items",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const seller = accounts.get('wallet_1')!;
        
        // Test zero price
        let block = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'list-item', [
                types.ascii("Test Item"),
                types.ascii("Description"),
                types.uint(0)
            ], seller.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(108);
        
        // Test maximum price
        block = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'list-item', [
                types.ascii("Expensive Item"),
                types.ascii("Description"),
                types.uint(1000000000001)
            ], seller.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(108);
    }
});

// [Remaining tests unchanged...]
