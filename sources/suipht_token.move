module 0x1::suipht_token {
    use sui::tx_context;
    use sui::object::{new as new_uid};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::transfer;

    /// Struct representing the token admin
    public struct TokenAdmin has key, store {
        id: UID,
        admin: address,
    }

    /// Struct representing our custom token metadata
    public struct SuiphtToken has key, store {
        id: UID,
        name: vector<u8>,
        symbol: vector<u8>,
        total_supply: u64,
    }

    /// Struct representing a balance of SuiphtToken
    public struct SuiphtTokenBalance has key, store {
        id: UID,
        balance: Balance<SuiphtToken>,
    }

    /// Struct representing a liquidity pool
    public struct LiquidityPool has key, store {
        id: UID,
        token_balance: Balance<SuiphtToken>, // Tokens in the pool
        sui_balance: Balance<sui::SUI>, // SUI coins in the pool
        owner: address, // Owner of the liquidity pool
    }

    /// Initializes the token
    public fun create_token(
        name: vector<u8>, 
        symbol: vector<u8>, 
        _ctx: &mut TxContext
    ): SuiphtToken {
        SuiphtToken {
            id: new_uid(_ctx),
            name,
            symbol,
            total_supply: 0,
        }
    }

    /// Mints new tokens
    public fun mint(
        token: &mut SuiphtToken,
        amount: u64,
        _ctx: &mut TxContext
    ) {
        token.total_supply = token.total_supply + amount; // Increase total supply

        // Create new tokens and add them to the token's balance
        let new_tokens = balance::zero(); // Initialize a zero balance
        balance::join(&mut token.balance, new_tokens); // Add the new tokens to the existing balance
    }

    /// Adds liquidity to the pool
    public fun add_liquidity(
        pool: &mut LiquidityPool,
        token: &mut SuiphtToken,
        token_amount: u64,
        sui_amount: u64,
        ctx: &mut TxContext
    ) {
        // Check that the token balance is sufficient
        assert!(balance::value(&token.balance) >= token_amount, 5); // Error code 5 for insufficient balance

        // Deduct tokens from the token balance
        let tokens_to_add = balance::split(&mut token.balance, token_amount);

        // Deduct SUI coins from the transaction context
        let sui_to_add = coin::take(&mut pool.sui_balance, sui_amount, ctx);

        // Add tokens and SUI to the pool
        balance::join(&mut pool.token_balance, tokens_to_add);
       
