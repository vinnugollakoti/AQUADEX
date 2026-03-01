module aqua_dex::lp_token {

    use sui::object::{Self, UID};
    use sui::coin::{Self, TreasuryCap, Coin};
    use sui::url;
    use std::option;

    /// One-time witness
    public struct LP_TOKEN has drop {}

    /// Stores treasury cap
    public struct LPTokenCap has key, store {
        id: UID,
        cap: TreasuryCap<LP_TOKEN>
    }

    /// Runs once when package is published
    fun init(witness: LP_TOKEN,ctx: &mut TxContext) {

        let icon = option::some(
            url::new_unsafe_from_bytes(
                b"https://res.cloudinary.com/dxflnmfxl/image/upload/v1772266142/Frame_2_nck3gg.png"
            )
        );

        let (cap, metadata) = coin::create_currency<LP_TOKEN>(
            witness,
            9,
            b"AQUADEX-LP",
            b"AquaDex LP Token",
            b"LP token for Aqua DEX",
            icon,
            ctx
        );

        transfer::public_freeze_object(metadata);

        let cap_obj = LPTokenCap {
            id: object::new(ctx),
            cap
        };

        transfer::public_transfer(cap_obj, tx_context::sender(ctx));
    }

    public fun mint_lp_token(
        cap: &mut LPTokenCap,
        amount: u128,
        ctx: &mut TxContext
    ): Coin<LP_TOKEN> {
        coin::mint(&mut cap.cap, amount as u64, ctx)
    }

    public fun burn_lp_token(
        cap: &mut LPTokenCap,
        coin: Coin<LP_TOKEN>
    ) {
        coin::burn(&mut cap.cap, coin);
    }
}