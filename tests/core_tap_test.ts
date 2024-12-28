import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test trainer management",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const trainer = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('core_tap', 'add-trainer', 
                [types.principal(trainer.address)],
                deployer.address
            )
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        let checkTrainer = chain.mineBlock([
            Tx.contractCall('core_tap', 'is-trainer',
                [types.principal(trainer.address)],
                deployer.address
            )
        ]);
        
        assertEquals(checkTrainer.receipts[0].result, types.bool(true));
    }
});

Clarinet.test({
    name: "Test program creation and retrieval",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const trainer = accounts.get('wallet_1')!;
        
        // Add trainer first
        chain.mineBlock([
            Tx.contractCall('core_tap', 'add-trainer',
                [types.principal(trainer.address)],
                deployer.address
            )
        ]);
        
        let block = chain.mineBlock([
            Tx.contractCall('core_tap', 'create-program',
                [
                    types.ascii("Core Basics"),
                    types.utf8("Basic core workout routine"),
                    types.uint(1)
                ],
                trainer.address
            )
        ]);
        
        block.receipts[0].result.expectOk().expectUint(0);
        
        let getProgram = chain.mineBlock([
            Tx.contractCall('core_tap', 'get-program',
                [types.uint(0)],
                deployer.address
            )
        ]);
        
        const program = getProgram.receipts[0].result.expectOk().expectSome();
        assertEquals(program['name'], "Core Basics");
    }
});

Clarinet.test({
    name: "Test workout recording",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const user = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('core_tap', 'record-workout',
                [types.uint(0)],
                user.address
            )
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        let progress = chain.mineBlock([
            Tx.contractCall('core_tap', 'get-user-progress',
                [
                    types.principal(user.address),
                    types.uint(0)
                ],
                user.address
            )
        ]);
        
        const userProgress = progress.receipts[0].result.expectOk().expectSome();
        assertEquals(userProgress['completed-workouts'], types.uint(1));
    }
});