module aqua_dex::swap {
    use sui::coin::{Self, Coin};
    use aqua_dex::pool::{Self, Pool};
    use aqua_dex::events::{Self};

    const FEE_NUMERATOR: u64 = 997;
    const FEE_DENOMINATOR: u64 = 1000;


    public fun swap_a_for_b<T0, T1>(
        pool: &mut Pool<T0, T1>,
        coin_in: Coin<T0>,
        min_amount_out: u64,
        ctx: &mut TxContext
    ): Coin<T1> {
        let amount_in = coin::value(&coin_in);
        let (reserve_a, reserve_b) = pool::get_reserves(pool);

        assert!(reserve_a > 0 && reserve_b > 0, 700);

        // AMM MATH = x * y = k
        let amount_in_with_fee = (amount_in as u128) * (FEE_NUMERATOR as u128);
        let numerator = amount_in_with_fee * (reserve_b as u128);
        let denominator =(reserve_a as u128) * (FEE_DENOMINATOR as u128) + amount_in_with_fee;
        let amount_out = (numerator / denominator) as u64;

        assert!(amount_out > 0, 701);
        assert!(amount_out >= min_amount_out, 401);

        let balance_in = coin::into_balance<T0>(coin_in);
        pool::add_reserve_a<T0, T1>(pool, balance_in);

        let balance_out = pool::remove_reserve_b<T0, T1>(pool, amount_out);
        events::emit_swap(object::id(pool), amount_in, amount_out, true);
        coin::from_balance(balance_out, ctx)
    }


    public fun swap_b_for_a<T0, T1>(
        pool: &mut Pool<T0, T1>,
        coin_in: Coin<T1>,
        min_amount_out: u64,
        ctx: &mut TxContext
    ): Coin<T0> {
        let amount_in = coin::value(&coin_in);


        let (reserve_a, reserve_b) = pool::get_reserves(pool);
        assert!(reserve_a > 0 && reserve_b > 0, 700);

        let amount_in_with_fee = (amount_in as u128) * (FEE_NUMERATOR as u128);
        let numerator = amount_in_with_fee * (reserve_a as u128);
        let denominator = (reserve_b as u128) * (FEE_DENOMINATOR as u128) + amount_in_with_fee;
        let amount_out =( numerator / denominator) as u64;

        assert!(amount_out > 0, 701);
        assert!(amount_out >= min_amount_out, 401);

        let balance = coin::into_balance<T1>(coin_in);
        pool::add_reserve_b<T0, T1>(pool, balance);

        let balance_out = pool::remove_reserve_a<T0, T1>(pool, amount_out);
        events::emit_swap(object::id(pool), amount_in, amount_out, false);
        coin::from_balance(balance_out, ctx)

    }
}

// Explanation for swap 

// let amount_in_with_fee = (amount_in * FEE_NUMERATOR) / FEE_DENOMINATOR; //9.970 
// let k = reserve_a * reserve_b; 
// let x = reserve_a + amount_in_with_fee; let y = k/x; // y = k/x 
// let amount_out = reserve_b - y; // 18.13...