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
    name: "Test achievement creation and earning",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const trainer = accounts.get('wallet_1')!;
        const user = accounts.get('wallet_2')!;
        
        // Setup program
        chain.mineBlock([
            Tx.contractCall('core_tap', 'add-trainer',
                [types.principal(trainer.address)],
                deployer.address
            ),
            Tx.contractCall('core_tap', 'create-program',
                [
                    types.ascii("Core Basics"),
                    types.utf8("Basic core workout routine"),
                    types.uint(1)
                ],
                trainer.address
            )
        ]);
        
        // Create achievement
        let createAchievement = chain.mineBlock([
            Tx.contractCall('core_tap', 'create-achievement',
                [
                    types.ascii("Beginner Core"),
                    types.utf8("Complete 5 core workouts"),
                    types.uint(0),
                    types.uint(5),
                    types.some(types.utf8("ipfs://Qm..."))
                ],
                trainer.address
            )
        ]);
        
        createAchievement.receipts[0].result.expectOk().expectUint(0);
        
        // Complete workouts
        for(let i = 0; i < 5; i++) {
            chain.mineBlock([
                Tx.contractCall('core_tap', 'record-workout',
                    [types.uint(0)],
                    user.address
                )
            ]);
        }
        
        // Check achievement status
        let achievementStatus = chain.mineBlock([
            Tx.contractCall('core_tap', 'get-user-achievement-status',
                [
                    types.principal(user.address),
                    types.uint(0)
                ],
                user.address
            )
        ]);
        
        const status = achievementStatus.receipts[0].result.expectOk().expectSome();
        assertEquals(status['earned'], types.bool(true));
    }
});
