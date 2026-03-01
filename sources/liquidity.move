module aqua_dex::liquidity{


    use sui::coin::{Self, Coin};

    use aqua_dex::lp_token::{Self, LPToken};
    use aqua_dex::pool::{Self, Pool};
    use sui::balance::{Balance};
    use aqua_dex::lp_token::LPTokenCap;
    use aqua_dex::events::{Self};
    use sui::event;


    public fun add_liquidity<T0, T1>(
        pool: &mut Pool<T0, T1>,
        coin_a: Coin<T0>,
        coin_b: Coin<T1>,
        cap: &mut LPTokenCap<T0, T1>,
        ctx: &mut TxContext
    ): Coin<LPToken<T0, T1>> {

        let amount_a = coin::value(&coin_a);
        let amount_b = coin::value(&coin_b);

        let (reserve_a, reserve_b) = pool::get_reserves(pool);
        let total_lp = pool::get_lp_supply(pool);


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


        pool::increase_lp_supply<T0, T1>(pool, lp_to_mint);
        let lp_coin = lp_token::mint_lp_token<T0, T1>(cap, lp_to_mint, ctx);

        events::emit_add_liquidity(
            object::id(pool),
            amount_a,
            amount_b,
            (lp_to_mint) as u64
        );

        lp_coin
    }

    public fun remove_liquidity<T0, T1>(
        pool: &mut Pool<T0, T1>,
        full_liquidity: bool,
        amount_a: u64,
        amount_b: u64,
        lp_coin: Coin<LPToken<T0, T1>>,
        cap: &mut LPTokenCap<T0, T1>,
        ctx: &mut TxContext
    ): (Balance<T0>, Balance<T1>, Option<Coin<LPToken<T0, T1>>>) {
        let mut lp_coin = lp_coin;
        let lp_amount = coin::value(&lp_coin);

        let (reserve_a, reserve_b) = pool::get_reserves(pool);
        let total_lp = pool::get_lp_supply(pool);


        let position_amount_a = lp_amount * reserve_a / (total_lp as u64);
        let position_amount_b = lp_amount * reserve_b / (total_lp as u64);

        if (full_liquidity) {
            lp_token::burn_lp_token(cap, lp_coin);

            pool::decrease_lp_supply<T0, T1>(pool, (lp_amount as u128));

            let balance_a = pool::remove_reserve_a<T0, T1>(pool, position_amount_a);
            let balance_b = pool::remove_reserve_b<T0, T1>(pool, position_amount_b);

            events::emit_remove_liquidity(object::id(pool), position_amount_a, position_amount_b, lp_amount);
            (balance_a, balance_b, option::none<Coin<LPToken<T0, T1>>>())
        } else {
            assert!(position_amount_a >= amount_a && position_amount_b >= amount_b, 480);
            assert!(reserve_a > 0 && reserve_b > 0, 481);

            let burn_a = amount_a * (total_lp as u64) / reserve_a;
            let burn_b = amount_b * (total_lp as u64) / reserve_b;

            let burn_amount = if (burn_a < burn_b) { burn_a } else { burn_b };
            
            let burn_lp = coin::split( &mut lp_coin, burn_amount, ctx);

            lp_token::burn_lp_token(cap, burn_lp);
            pool::decrease_lp_supply(pool, burn_amount as u128);

            let balance_a = pool::remove_reserve_a<T0, T1>(pool, amount_a);
            let balance_b = pool::remove_reserve_b<T0, T1>(pool, amount_b);

            events::emit_remove_liquidity(object::id(pool), amount_a, amount_b, burn_amount);
            (balance_a, balance_b, option::some(lp_coin))
        }
    }
}