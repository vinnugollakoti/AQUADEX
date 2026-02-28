module aqua_dex::lp_token {


    use sui::object::{Self, UID};
    use sui::coin::{Self, TreasuryCap, Coin};
    use std::u64;


    public struct LPToken<phantom T0, phantom T1> has drop {}

    public struct LPTokenCap<phantom T0, phantom T1> has key {
        id: UID,
        cap: TreasuryCap<LPToken<T0, T1>>
    }


    public fun create_lp_token<T0, T1>(
        witness: LPToken<T0, T1>,
        ctx: &mut TxContext
    ): LPTokenCap<T0, T1> {
        

        let (treasury_cap, metadata) = coin::create_currency<LPToken<T0, T1>>(
            witness,
            9,
            b"AQUACOIN",
            b"Aqua coin",
            b"LP token for AMM pool",
            option::none(),
            ctx
        );

        transfer::public_freeze_object(metadata);

        LPTokenCap {
            id: object::new(ctx),
            cap: treasury_cap
        }
    }

    public fun mint_lp_token<T0, T1> (
        cap: &mut LPTokenCap<T0, T1>,
        amount: u128,
        ctx: &mut TxContext
    ): Coin<LPToken<T0, T1>> {
        coin::mint(&mut cap.cap, amount as u64, ctx)
    }

    public fun burn_lp_token<T0, T1> (
        cap: &mut LPTokenCap<T0, T1>,
        coin: Coin<LPToken<T0, T1>>
    ) {
        coin::burn(&mut cap.cap, coin);
    }
    
}