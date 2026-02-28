module aqua_dex::events {

    use sui::event;
    use sui::object::ID;

    /// emitted when a pool is created
    public struct PoolCreatedEvent has copy, drop {
        pool_id: ID,
    }

    /// emitted when liquidity is added
    public struct AddLiquidityEvent has copy, drop {
        pool_id: ID,
        amount_a: u64,
        amount_b: u64,
        lp_minted: u64,
    }

    /// emitted when liquidity is removed
    public struct RemoveLiquidityEvent has copy, drop {
        pool_id: ID,
        amount_a: u64,
        amount_b: u64,
        lp_burned: u64,
    }

    /// emitted when a swap happens
    public struct SwapEvent has copy, drop {
        pool_id: ID,
        amount_in: u64,
        amount_out: u64,
        a_to_b: bool,
    }

    public fun emit_pool_created(pool_id: ID) {
        event::emit(PoolCreatedEvent {
            pool_id
        });
    }

    public fun emit_add_liquidity(
        pool_id: ID,
        amount_a: u64,
        amount_b: u64,
        lp_minted: u64
    ) {
        event::emit(AddLiquidityEvent {
            pool_id,
            amount_a,
            amount_b,
            lp_minted
        });
    }

    public fun emit_remove_liquidity(
        pool_id: ID,
        amount_a: u64,
        amount_b: u64,
        lp_burned: u64
    ) {
        event::emit(RemoveLiquidityEvent {
            pool_id,
            amount_a,
            amount_b,
            lp_burned
        });
    }

    public fun emit_swap(
        pool_id: ID,
        amount_in: u64,
        amount_out: u64,
        a_to_b: bool
    ) {
        event::emit(SwapEvent {
            pool_id,
            amount_in,
            amount_out,
            a_to_b
        });
    }

}