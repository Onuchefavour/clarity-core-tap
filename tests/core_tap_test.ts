Clarinet.test({
    name: "Test inactive program handling",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const trainer = accounts.get('wallet_1')!;
        const user = accounts.get('wallet_2')!;
        
        // Setup program
        let block = chain.mineBlock([
            Tx.contractCall('core_tap', 'add-trainer',
                [types.principal(trainer.address)],
                deployer.address
            ),
            Tx.contractCall('core_tap', 'create-program',
                [
                    types.ascii("Test Program"),
                    types.utf8("Test Description"),
                    types.uint(1)
                ],
                trainer.address
            )
        ]);
        
        // Deactivate program
        block = chain.mineBlock([
            Tx.contractCall('core_tap', 'deactivate-program',
                [types.uint(0)],
                trainer.address
            )
        ]);
        block.receipts[0].result.expectOk();
        
        // Attempt workout recording
        block = chain.mineBlock([
            Tx.contractCall('core_tap', 'record-workout',
                [types.uint(0)],
                user.address
            )
        ]);
        
        block.receipts[0].result.expectErr(106); // err-inactive-program
    }
});
