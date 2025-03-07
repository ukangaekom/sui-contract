/*
/// Module: suipht_token
module suipht_token::suipht_token;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions


module 0x1::suipht_token {
    use sui::tx_context::TxContext;
    use sui::balance::Balance;
    use sui::object::{ID, new as new_uid};
    
    /// Struct representing our custom token
    public struct SuiphtToken has key, store {
        id: UID,
        name: vector<u8>,
        symbol: vector<u8>,
        total_supply: u64,
        balance: u64,
    }

    /// Initializes the token for a user
    public fun create_token(
        name: vector<u8>, 
        symbol: vector<u8>, 
        ctx: &mut TxContext
    ): SuiphtToken {
        SuiphtToken {
            id: new_uid(ctx),
            name,
            symbol,
            total_supply: 0,
            balance: 0,
        }
    }

    /// Mints new tokens
    public fun mint(
        token: &mut SuiphtToken,
        amount: u64,
        _ctx: &mut TxContext
    ) {
        token.total_supply = token.total_supply + amount;
        token.balance = token.balance + amount;
    }

    /// Transfers tokens to another user
    public fun transfer(
    sender: &mut SuiphtToken,
    recipient: &mut SuiphtToken,
    amount: u64
) {
    // Check that sender has enough balance; use error code 1 on failure.
    assert!(sender.balance >= amount, 1);
    sender.balance = sender.balance - amount;
    recipient.balance = recipient.balance + amount;
    }

    /// Adds liquidity (dummy function, implement based on your needs)
    public fun add_liquidity( 
        token: &mut SuiphtToken,
        amount: u64
    ) {
        assert!(token.balance >= amount, 2);
        token.balance = token.balance - amount;
        // implement liquidity pool integration logic here
    }
}
