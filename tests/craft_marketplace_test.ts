import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// Previous tests remain...

Clarinet.test({
    name: "Escrow system: Can create and complete escrow transaction",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const seller = accounts.get('wallet_1')!;
        const buyer = accounts.get('wallet_2')!;
        
        // List item
        let block = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'list-item', [
                types.ascii("Handmade Vase"),
                types.ascii("Ceramic vase, hand-painted"),
                types.uint(50000000) // 50 STX
            ], seller.address)
        ]);
        
        // Create escrow
        let escrowBlock = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'create-escrow', [
                types.uint(1)
            ], buyer.address)
        ]);
        
        escrowBlock.receipts[0].result.expectOk().expectUint(1);
        
        // Release escrow
        let releaseBlock = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'release-escrow', [
                types.uint(1)
            ], buyer.address)
        ]);
        
        releaseBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Verify escrow status
        const escrow = chain.callReadOnlyFn(
            'craft_marketplace',
            'get-escrow',
            [types.uint(1)],
            buyer.address
        );
        
        const escrowData = escrow.result.expectSome().expectTuple();
        assertEquals(escrowData['status'], "completed");
    }
});

Clarinet.test({
    name: "Escrow system: Can refund escrow",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const seller = accounts.get('wallet_1')!;
        const buyer = accounts.get('wallet_2')!;
        
        // List item
        chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'list-item', [
                types.ascii("Handmade Bowl"),
                types.ascii("Ceramic bowl"),
                types.uint(30000000) // 30 STX
            ], seller.address)
        ]);
        
        // Create escrow
        chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'create-escrow', [
                types.uint(1)
            ], buyer.address)
        ]);
        
        // Refund escrow
        let refundBlock = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'refund-escrow', [
                types.uint(1)
            ], seller.address)
        ]);
        
        refundBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Verify escrow status
        const escrow = chain.callReadOnlyFn(
            'craft_marketplace',
            'get-escrow',
            [types.uint(1)],
            buyer.address
        );
        
        const escrowData = escrow.result.expectSome().expectTuple();
        assertEquals(escrowData['status'], "refunded");
    }
});
