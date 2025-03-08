module 0x1::suipht_token {
    use sui::tx_context::TxContext;
    use sui::object::{ID, UID, new as new_uid};
    use sui::balance::Balance;
    use sui::coin::Coin;
    use sui::transfer;
    use sui::vector;

    /// Struct representing the admin (owner of the token contract)
    public struct TokenAdmin has key {
        id: UID,
        owner: address,
    }

    /// Struct representing our custom token
    public struct SuiphtToken has key, store {
        id: UID,
        name: vector<u8>,
        symbol: vector<u8>,
        total_supply: u64,
        balance: Balance<SuiphtToken>, // Token balance
    }

    /// Struct representing a liquidity pool for the token
    public struct LiquidityPool has key, store {
        id: UID,
        owner: address,
        token_balance: Balance<SuiphtToken>, // Tokens in the pool
        sui_balance: Coin<SUI>, // SUI coins in the pool
    }

    /// Initializes the token with an admin
    public fun create_token(
        owner: address,
        name: vector<u8>, 
        symbol: vector<u8>, 
        ctx: &mut TxContext
    ): (SuiphtToken, TokenAdmin) {
        (
            SuiphtToken {
                id: new_uid(ctx),
                name,
                symbol,
                total_supply: 0,
                balance: Balance { value: 0 },
            },
            TokenAdmin {
                id: new_uid(ctx),
                owner,
            }
        )
    }

    /// Mints new tokens (only admin can mint)
    public fun mint(
        admin: &TokenAdmin,
        token: &mut SuiphtToken,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(ctx.sender() == admin.owner, 1); // Only admin can mint
        token.total_supply = token.total_supply + amount;
        token.balance.value = token.balance.value + amount;
    }

    /// Transfers tokens to another user
    public fun transfer(
        token: &mut SuiphtToken,
        recipient: address,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(token.balance.value >= amount, 2); // Check balance
        token.balance.value = token.balance.value - amount;
        let sent_token = SuiphtToken {
            id: new_uid(ctx),
            name: token.name,
            symbol: token.symbol,
            total_supply: token.total_supply,
            balance: Balance { value: amount },
        };
        transfer::transfer(sent_token, recipient);
    }

    /// Creates a liquidity pool for the token
    public fun create_liquidity_pool(
        admin: &TokenAdmin,
        token: &mut SuiphtToken,
        initial_token_amount: u64,
        initial_sui_amount: u64,
        ctx: &mut TxContext
    ): LiquidityPool {
        assert!(ctx.sender() == admin.owner, 3); // Only admin can create pool
        assert!(token.balance.value >= initial_token_amount, 4); // Check balance
        token.balance.value = token.balance.value - initial_token_amount;
        let sui_coins = Coin::zero();
        LiquidityPool {
            id: new_uid(ctx),
            owner: admin.owner,
            token_balance: Balance { value: initial_token_amount },
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
        assert!(token.balance.value >= token_amount, 5);
        token.balance.value = token.balance.value - token_amount;
        pool.token_balance.value = pool.token_balance.value + token_amount;
    }

    /// Removes liquidity from the pool (only owner can remove)
    public fun remove_liquidity(
        pool: &mut LiquidityPool,
        token: &mut SuiphtToken,
        token_amount: u64,
        sui_amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(ctx.sender() == pool.owner, 6); // Only pool owner can remove
        assert!(pool.token_balance.value >= token_amount, 7);
        pool.token_balance.value = pool.token_balance.value - token_amount;
        transfer::transfer(token_amount, recipient);
    }
}
