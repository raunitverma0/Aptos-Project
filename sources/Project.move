module MyModule::TokenStaking {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    
    /// Struct representing a user's staking position.
    struct StakePosition has store, key {
        staked_amount: u64,     // Amount of tokens staked
        stake_timestamp: u64,   // When the stake was created
    }
    
    /// Error codes
    const E_INSUFFICIENT_STAKE: u64 = 1;
    const E_NO_STAKE_FOUND: u64 = 2;
    
    /// Function to stake tokens into the contract.
    public fun stake_tokens(staker: &signer, amount: u64) {
        let staker_addr = signer::address_of(staker);
        
        // Withdraw tokens from staker
        let stake_coins = coin::withdraw<AptosCoin>(staker, amount);
        
        // Create or update stake position
        if (exists<StakePosition>(staker_addr)) {
            let stake_pos = borrow_global_mut<StakePosition>(staker_addr);
            stake_pos.staked_amount = stake_pos.staked_amount + amount;
        } else {
            let stake_position = StakePosition {
                staked_amount: amount,
                stake_timestamp: 0, // In real implementation, use timestamp::now_seconds()
            };
            move_to(staker, stake_position);
        };
        
        // Deposit tokens to contract (in this case, burn them)
        coin::deposit<AptosCoin>(@MyModule, stake_coins);
    }
    
    /// Function to withdraw staked tokens from the contract.
    public fun withdraw_stake(staker: &signer, amount: u64) acquires StakePosition {
        let staker_addr = signer::address_of(staker);
        
        assert!(exists<StakePosition>(staker_addr), E_NO_STAKE_FOUND);
        
        let stake_pos = borrow_global_mut<StakePosition>(staker_addr);
        assert!(stake_pos.staked_amount >= amount, E_INSUFFICIENT_STAKE);
        
        // Update staked amount
        stake_pos.staked_amount = stake_pos.staked_amount - amount;
        
        // Transfer tokens back to staker
        let withdrawal = coin::withdraw<AptosCoin>(@MyModule, amount);
        coin::deposit<AptosCoin>(staker_addr, withdrawal);
        
        // Clean up if no tokens left staked
        if (stake_pos.staked_amount == 0) {
            let StakePosition { staked_amount: _, stake_timestamp: _ } = move_from<StakePosition>(staker_addr);
        };
    }
}