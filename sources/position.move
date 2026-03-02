module aqua_dex::position {
    use sui::object::UID;
    use aqua_dex::pool::{Self, Pool};

    public struct LPPosition has key, store {
        id: UID,
        pool_id: ID,
        liquidity: u128
    }

    public fun create_position(
        pool_id: ID,
        liquidity: u128,
        ctx: &mut TxContext
    ): LPPosition {
        let position = LPPosition {
            id : object::new(ctx),
            pool_id,
            liquidity
        };
        position
    } 

    public fun get_position_liquidity(
        position: &LPPosition
    ): u128 {
        position.liquidity
    }
    

    public fun reduce_liquidity(
        position: &mut LPPosition,
        amount: u128
    ) {
        position.liquidity = position.liquidity - amount;
    }

    public fun get_id(position: &LPPosition): ID {
        object::id(position)
    }

    public fun destroy_position(position: LPPosition) {
        let LPPosition {id, pool_id: _, liquidity: _} = position;
        object::delete(id);
    }

    public fun get_pool_id(position: &LPPosition): ID {
        position.pool_id
    }


}