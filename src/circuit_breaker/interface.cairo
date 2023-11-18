use core::traits::TryInto;
use starknet::ContractAddress;
use array::Array;
use starknet::ClassHash;
use circuitbreaker::circuit_breaker::structs::Limiter;

#[starknet::interface]
trait ICircuitBreaker<TCircuit> {
    fn registerAsset(
        ref self: TCircuit,
        _asset: ContractAddress,
        _minLiqRetainedBps: u256,
        _limitBeginThreshold: u256
    );
    fn get_token_limiter(self: @TCircuit, address: ContractAddress) -> Limiter;
    fn updateAssetParams(
        ref self: TCircuit,
        _asset: ContractAddress,
        _minLiqRetainedBps: u256,
        _limitBeginThreshold: u256
    );
    fn onTokenInflow(ref self: TCircuit, _token: ContractAddress, _amount: u256);
    fn onTokenOutflow(
        ref self: TCircuit,
        _token: ContractAddress,
        _amount: u256,
        _recipient: ContractAddress,
        _revertOnRateLimit: bool
    );
    // fn claimLockedFunds(ref self: TCircuit, _asset: ContractAddress, _recipient: ContractAddress);
    fn setAdmin(ref self: TCircuit, _newAdmin: ContractAddress);
    fn overrideRateLimit(ref self: TCircuit);
    fn overrideExpiredRateLimit(ref self: TCircuit);
    fn addProtectedContracts(ref self: TCircuit, _ProtectedContracts: Array<ContractAddress>);
    fn removeProtectedContracts(ref self: TCircuit, _ProtectedContracts: Array<ContractAddress>);
    fn startGracePeriod(ref self: TCircuit, _gracePeriodEndTimestamp: u64);
    fn markAsNotOperational(ref self: TCircuit);
    fn migrateFundsAfterExploit(
        ref self: TCircuit, _assets: Array<ContractAddress>, _recoveryRecipient: ContractAddress
    );
    fn onNativeAssetOutflow(
        ref self: TCircuit, _recipient: ContractAddress, _revertOnRateLimit: bool, amount: u256
    );
    fn onNativeAssetInflow(ref self: TCircuit, _amount: u256);
    // fn lockedFunds(self: @TCircuit, recipient: ContractAddress, asset: ContractAddress) -> u256;
    fn isProtectedContract(self: @TCircuit, account: ContractAddress) -> bool;
    fn admin(self: @TCircuit) -> ContractAddress;
    fn isRateLimited(self: @TCircuit) -> bool;
    fn rateLimitCooldownPeriod(self: @TCircuit) -> u64;
    fn lastRateLimitTimestamp(self: @TCircuit) -> u64;
    fn gracePeriodEndTimestamp(self: @TCircuit) -> u64;
    fn isRateLimitTriggered(self: @TCircuit, _asset: ContractAddress) -> bool;
    fn isInGracePeriod(self: @TCircuit) -> bool;
    fn isOperational(self: @TCircuit) -> bool;
    fn upgrade(ref self: TCircuit, implementation: ClassHash);
}
