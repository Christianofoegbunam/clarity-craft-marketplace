import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can list a new item for sale",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'list-item', [
                types.ascii("Handmade Scarf"),
                types.ascii("Beautiful wool scarf, hand-knitted"),
                types.uint(100000000) // 100 STX
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        const listing = chain.callReadOnlyFn(
            'craft_marketplace',
            'get-listing',
            [types.uint(1)],
            wallet1.address
        );
        
        const listingData = listing.result.expectSome().expectTuple();
        assertEquals(listingData['title'], "Handmade Scarf");
        assertEquals(listingData['price'], 100000000);
        assertEquals(listingData['available'], true);
    }
});

Clarinet.test({
    name: "Can purchase a listed item",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const seller = accounts.get('wallet_1')!;
        const buyer = accounts.get('wallet_2')!;
        
        // First list an item
        let block = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'list-item', [
                types.ascii("Handmade Vase"),
                types.ascii("Ceramic vase, hand-painted"),
                types.uint(50000000) // 50 STX
            ], seller.address)
        ]);
        
        // Then purchase it
        let purchaseBlock = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'purchase-item', [
                types.uint(1)
            ], buyer.address)
        ]);
        
        purchaseBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Verify listing is no longer available
        const listing = chain.callReadOnlyFn(
            'craft_marketplace',
            'get-listing',
            [types.uint(1)],
            buyer.address
        );
        
        const listingData = listing.result.expectSome().expectTuple();
        assertEquals(listingData['available'], false);
    }
});

Clarinet.test({
    name: "Can create and update seller profile",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const seller = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'create-profile', [
                types.ascii("Artisan Joe"),
                types.ascii("Crafting beautiful items since 2010")
            ], seller.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        const profile = chain.callReadOnlyFn(
            'craft_marketplace',
            'get-seller-profile',
            [types.principal(seller.address)],
            seller.address
        );
        
        const profileData = profile.result.expectSome().expectTuple();
        assertEquals(profileData['name'], "Artisan Joe");
        assertEquals(profileData['rating'], 0);
        assertEquals(profileData['review-count'], 0);
    }
});