[Previous test content remains unchanged, adding new test:]

Clarinet.test({
    name: "Test inactive program handling",
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
                    types.ascii("Test Program"),
                    types.utf8("Test Description"),
                    types.uint(1)
                ],
                trainer.address
            )
        ]);
        
        // Deactivate program (implementation needed)
        
        // Attempt workout recording
        let block = chain.mineBlock([
            Tx.contractCall('core_tap', 'record-workout',
                [types.uint(0)],
                user.address
            )
        ]);
        
        block.receipts[0].result.expectErr(106); // err-inactive-program
    }
});
