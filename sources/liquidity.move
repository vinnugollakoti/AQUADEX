module aqua_dex::liquidity{

    use sui::coin::{Self, Coin};
    use aqua_dex::lp_token::{LPToken};
    use aqua_dex::pool::{Self, Pool};
    use sui::balance::{Balance};
    use aqua_dex::events::{Self};
    use aqua_dex::position::{Self, LPPosition};

    public fun add_liquidity<T0, T1>(
        pool: &mut Pool<T0, T1>,
        coin_a: Coin<T0>,
        coin_b: Coin<T1>,
        ctx: &mut TxContext
    ): LPPosition {

        let amount_a = coin::value(&coin_a);
        let amount_b = coin::value(&coin_b);
        assert!(amount_a > 0 && amount_b > 0, 0);

        let (reserve_a, reserve_b) = pool::get_reserves(pool);
        assert!(reserve_a > 0 && reserve_b > 0, 602);
        let total_lp = pool::get_total_liquidity(pool);

        if (total_lp > 0) {
            assert!(
                (amount_a as u128) * (reserve_b as u128)
                    == (amount_b as u128) * (reserve_a as u128),
                600
            );
        };

        let lp_to_mint;

        if (total_lp == 0) {
            lp_to_mint = amount_a as u128;
        } else {
            let lp_a = ((amount_a as u128) * total_lp / (reserve_a as u128));
            let lp_b = ((amount_b as u128) * total_lp / (reserve_b as u128));

            if (lp_a < lp_b) {
                lp_to_mint = lp_a
            } else {
                lp_to_mint = lp_b
            };
        };

        let bal_a = coin::into_balance(coin_a);
        let bal_b = coin::into_balance(coin_b);

        pool::add_reserve_a(pool, bal_a);
        pool::add_reserve_b(pool, bal_b);

        // let position = LPPosition {
        //     id: object::new(ctx),
        //     pool_id: object::id(pool),
        //     liquidity: lp_to_mint
        // };
        pool::increase_liquidity(pool, lp_to_mint);
        let position = position::create_position(object::id(pool), lp_to_mint, ctx);

        events::emit_add_liquidity(
            object::id(pool),
            amount_a,
            amount_b,
            (lp_to_mint) as u64
        );

        position
    }

    public fun remove_liquidity<T0, T1>(
        pool: &mut Pool<T0, T1>,
        full_liquidity: bool,
        amount_a: u64,
        amount_b: u64,
        mut position: LPPosition,
        ctx: &mut TxContext
    ): (Balance<T0>, Balance<T1>, Option<LPPosition>) {

        assert!(
            position::get_pool_id(&position) == object::id(pool),
            500
        );

        let lp_amount = position::get_position_liquidity(&position);

        let (reserve_a, reserve_b) = pool::get_reserves(pool);
        let total_lp = pool::get_total_liquidity(pool);
        
        assert!(total_lp > 0, 482);

        let position_amount_a = ((lp_amount * (reserve_a as u128)) / total_lp) as u64;

        let position_amount_b = ((lp_amount * (reserve_b as u128)) / total_lp) as u64;


        if (full_liquidity) {

            position::destroy_position(position);

            pool::decrease_liquidity(pool, lp_amount);

           
            let balance_a = pool::remove_reserve_a<T0, T1>(pool, position_amount_a);
            let balance_b = pool::remove_reserve_b<T0, T1>(pool, position_amount_b);

            events::emit_remove_liquidity(object::id(pool), position_amount_a, position_amount_b, (lp_amount) as u64);
            (balance_a, balance_b, option::none())

        } else {
            assert!(position_amount_a >= amount_a && position_amount_b >= amount_b, 480);
            assert!(reserve_a > 0 && reserve_b > 0, 481);

            let burn_a = ((amount_a as u128) * total_lp / (reserve_a as u128)) as u64;

            let burn_b = ((amount_b as u128) * total_lp / (reserve_b as u128)) as u64;

            let burn_amount = if (burn_a < burn_b) { burn_a } else { burn_b };
            
            // let burn_lp = coin::split( &mut lp_coin, burn_amount, ctx);
            position::reduce_liquidity(&mut position, (burn_amount as u128));

            pool::decrease_liquidity(pool, (burn_amount as u128));

            let balance_a = pool::remove_reserve_a<T0, T1>(pool, amount_a);
            let balance_b = pool::remove_reserve_b<T0, T1>(pool, amount_b);

            events::emit_remove_liquidity(object::id(pool), amount_a, amount_b, burn_amount);
            (balance_a, balance_b, option::some(position))
        }
    }
}