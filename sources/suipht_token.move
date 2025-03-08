module 0x1::suipht_token {
    use sui::tx_context::TxContext;
    use sui::object::{ID, UID, new as new_uid};
    use sui::balance::{Balance, withdraw, deposit, zero};
    use sui::coin::Coin;
    use sui::transfer;
    use sui::error::abort;
    use sui::math::safe_add;

    /// Admin struct to manage minting and liquidity pools
    public struct TokenAdmin has key {
        id: UID,
        admin: address,
    }

    /// Struct representing our custom token
    public struct SuiphtToken has key, store {
        id: UID,
        name: vector<u8>,
        symbol: vector<u8>,
        total_supply: u64,
        balance: Balance<SuiphtToken>,
    }

    /// Struct representing a liquidity pool for the token
    public struct LiquidityPool has key, store {
        id: UID,
        token_balance: Balance<SuiphtToken>,
        sui_balance: Balance<SUI>,
        owner: address,
    }

    /// Initializes token admin
    public fun create_admin(admin: address, ctx: &mut TxContext): TokenAdmin {
        TokenAdmin { id: new_uid(ctx), admin }
    }

    /// Initializes the token (only admin can call this)
    public fun create_token(
        admin: &TokenAdmin,
        name: vector<u8>,
        symbol: vector<u8>,
        ctx: &mut TxContext
    ): SuiphtToken {
        SuiphtToken {
            id: new_uid(ctx),
            name,
            symbol,
            total_supply: 0,
            balance: zero(),
        }
    }

    /// Mints new tokens (only admin can call this)
    public fun mint(
        admin: &TokenAdmin,
        token: &mut SuiphtToken,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(ctx.sender() == admin.admin, 1); // Only admin can mint
        token.total_supply = safe_add(token.total_supply, amount);
        deposit(&mut token.balance, amount);
    }

    /// Transfers tokens to another user
    public fun transfer(
        token: &mut SuiphtToken,
        recipient: address,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(withdraw(&mut token.balance, amount), 2);
        let new_balance = Balance { value: amount };
        transfer::transfer(new_balance, recipient);
    }

    /// Creates a liquidity pool (only admin can call this)
    public fun create_liquidity_pool(
        admin: &TokenAdmin,
        token: &mut SuiphtToken,
        initial_token_amount: u64,
        initial_sui_amount: u64,
        ctx: &mut TxContext
    ): LiquidityPool {
        assert!(ctx.sender() == admin.admin, 3);
        assert!(withdraw(&mut token.balance, initial_token_amount), 4);
        let sui_coins = Balance { value: initial_sui_amount };
        LiquidityPool {
            id: new_uid(ctx),
            token_balance: Balance { value: initial_token_amount },
            sui_balance: sui_coins,
            owner: ctx.sender(),
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
        assert!(withdraw(&mut token.balance, token_amount), 5);
        deposit(&mut pool.token_balance, token_amount);
        deposit(&mut pool.sui_balance, sui_amount);
    }

    /// Removes liquidity (only owner can remove liquidity)
    public fun remove_liquidity(
        pool: &mut LiquidityPool,
        token_amount: u64,
        sui_amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(ctx.sender() == pool.owner, 6);
        assert!(withdraw(&mut pool.token_balance, token_amount), 7);
        assert!(withdraw(&mut pool.sui_balance, sui_amount), 8);

        let tokens_to_transfer = Balance { value: token_amount };
        let sui_to_transfer = Balance { value: sui_amount };

        transfer::transfer(tokens_to_transfer, recipient);
        transfer::transfer(sui_to_transfer, recipient);
    }
}
