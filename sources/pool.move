module aqua_dex::pool {


    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::math::{Self};
    use aqua_dex::lp_token::{Self, LPTokenCap, LP_TOKEN};
    use aqua_dex::events::{Self};

    public struct Pool<phantom T0, phantom T1> has key, store {
        id: UID,
        reserve_a : Balance<T0>,
        reserve_b : Balance<T1>,
        lp_supply: u128,
        lp_cap: LPTokenCap
    }


    public fun create_pool<T0, T1>(
        coin_a :  Coin<T0>,
        coin_b : Coin<T1>,
        mut lp_cap: LPTokenCap,
        ctx: &mut TxContext
    ) {

        let amount_a = coin::value(&coin_a);
        let amount_b = coin::value(&coin_b);

        let reserve_a = coin::into_balance(coin_a);
        let reserve_b = coin::into_balance(coin_b);


        let initial_lp = std::u128::sqrt((amount_a as u128) * (amount_b as u128));

        let lp_coin = lp_token::mint_lp_token(&mut lp_cap, initial_lp, ctx);
        let pool = Pool<T0, T1> {
            id: object::new(ctx),
            reserve_a,
            reserve_b,
            lp_supply: initial_lp,
            lp_cap
        };

        events::emit_pool_created(object::id(&pool));

        transfer::public_share_object(pool);

        transfer::public_transfer(lp_coin, tx_context::sender(ctx));
    }

    public fun get_reserves<T0, T1> (
        pool : &Pool<T0, T1>
    ): (u64, u64) {
        let reserve_x = balance::value(&pool.reserve_a);
        let reserve_y = balance::value(&pool.reserve_b);

        (reserve_x, reserve_y)
    }

    public fun get_price<T0, T1> (
        pool : &Pool<T0, T1>
    ): u64 {
        let reserve_x = balance::value(&pool.reserve_a);
        let reserve_y = balance::value(&pool.reserve_b);


        reserve_y / reserve_x
    }

    public fun get_lp_supply<T0, T1>(
        pool:&Pool<T0, T1>,
    ): u128 {
        pool.lp_supply
    }

    public(package) fun add_reserve_a<T0, T1>(
        pool: &mut Pool<T0, T1>,
        amount: Balance<T0>
    ) {
        balance::join(&mut pool.reserve_a, amount);
    }

    public(package) fun add_reserve_b<T0, T1>(
        pool:&mut Pool<T0, T1>,
        amount: Balance<T1>
    ) {
        balance::join(&mut pool.reserve_b, amount);
    }


    public(package) fun remove_reserve_a<T0, T1>(
        pool:&mut Pool<T0, T1>,
        amount: u64
    ): Balance<T0> {
        balance::split(&mut pool.reserve_a, amount)
    }

    public(package) fun remove_reserve_b<T0, T1>(
        pool: &mut Pool<T0, T1>,
        amount: u64
    ): Balance<T1> {
        balance::split(&mut pool.reserve_b, amount)
    }

    public(package) fun increase_lp_supply<T0, T1>(
        pool: &mut Pool<T0, T1>,
        amount: u128
    ) {
        pool.lp_supply = pool.lp_supply + amount;
    }


    public(package) fun decrease_lp_supply<T0, T1>(
        pool: &mut Pool<T0, T1>,
        amount: u128
    ) {
        pool.lp_supply = pool.lp_supply - amount;
    }

    public(package) fun mint_lp<T0, T1>(
        pool: &mut Pool<T0, T1>,
        amount: u128,
        ctx: &mut TxContext
    ): Coin<LP_TOKEN> {
        lp_token::mint_lp_token(&mut pool.lp_cap, amount, ctx)
    }

    public(package) fun burn_lp<T0, T1>(
        pool: &mut Pool<T0, T1>,
        coin: Coin<LP_TOKEN>
    ) {
        lp_token::burn_lp_token(&mut pool.lp_cap, coin)
    }
}