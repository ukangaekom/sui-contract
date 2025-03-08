module 0x1::suipht_token {
    use sui::tx_context::TxContext;
    use sui::object::{ID, UID, new as new_uid};
    use sui::balance::{Self, Balance};
    use sui::transfer;

    /// Struct representing our custom token
    public struct SuiphtToken has key, store {
        id: UID,
        name: vector<u8>,
        symbol: vector<u8>,
        total_supply: u64,
        balance: Balance<SuiphtToken>, // Use Balance to manage token amounts
    }

    /// Struct representing a liquidity pool for the token
    public struct LiquidityPool has key, store {
        id: UID,
        token_balance: Balance<SuiphtToken>, // Tokens in the pool
        sui_balance: Balance<SUI>, // SUI coins in the pool
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
            balance: balance::zero(), // Initialize balance to zero
        }
    }

    /// Mints new tokens
    public fun mint(
        token: &mut SuiphtToken,
        amount: u64,
        ctx: &mut TxContext
    ) {
        token.total_supply = token.total_supply + amount;
        balance::join(&mut token.balance, balance::create(amount));
    }

    /// Transfers tokens to another user
    public fun transfer(
        token: &mut SuiphtToken,
        recipient: address,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(balance::value(&token.balance) >= amount, 1); // Check balance
        let tokens_to_transfer = balance::split(&mut token.balance, amount);
        transfer::transfer(tokens_to_transfer, recipient); // Transfer tokens
    }

    /// Creates a liquidity pool for the token
    public fun create_liquidity_pool(
        token: &mut SuiphtToken,
        initial_token_amount: u64,
        initial_sui_amount: u64,
        ctx: &mut TxContext
    ): LiquidityPool {
        assert!(balance::value(&token.balance) >= initial_token_amount, 2); // Check token balance
        let tokens_for_pool = balance::split(&mut token.balance, initial_token_amount);
        let sui_coins = balance::create(initial_sui_amount); // Create SUI balance

        LiquidityPool {
            id: new_uid(ctx),
            token_balance: tokens_for_pool,
            sui_balance: sui_coins,
        }
    }

    /// Adds liquidity to the pool
    public fun add_liquidity(
        pool: &mut LiquidityPool,
        token: &mut SuiphtToken,
        token_amount: u64,
        sui_amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(balance::value(&token.balance) >= token_amount, 3); // Check token balance
        let tokens_to_add = balance::split(&mut token.balance, token_amount);
        let sui_to_add = balance::create(sui_amount);

        balance::join(&mut pool.token_balance, tokens_to_add);
        balance::join(&mut pool.sui_balance, sui_to_add);
    }

    /// Removes liquidity from the pool
    public fun remove_liquidity(
        pool: &mut LiquidityPool,
        token_amount: u64,
        sui_amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(balance::value(&pool.token_balance) >= token_amount, 4); // Check pool balances
        assert!(balance::value(&pool.sui_balance) >= sui_amount, 5);

        let tokens_to_remove = balance::split(&mut pool.token_balance, token_amount);
        let sui_to_remove = balance::split(&mut pool.sui_balance, sui_amount);

        transfer::transfer(tokens_to_remove, recipient); // Transfer tokens to recipient
        transfer::transfer(sui_to_remove, recipient); // Transfer SUI to recipient
    }
}
