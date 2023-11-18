#[derive(Drop, Copy, Serde, starknet::Store)]
struct LiqChangeNode {
    next_timestamp: u64,
    amount: u256,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
struct Limiter {
    min_liq_retained_bps: u256,
    limit_begin_threshold: u256,
    liq_total: u256,
    liq_in_period: u256,
    list_head: u64,
    list_tail: u64,
// mapping(uint256 tick => LiqChangeNode node) listNodes;
}
