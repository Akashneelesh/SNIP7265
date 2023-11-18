use starknet::ContractAddress;
use array::Array;

#[starknet::interface]
trait IERC20<TContractState> {
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    );
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);
}

#[starknet::interface]
trait IProtectedContract<TContractState> {
    fn init(ref self: TContractState, _circuitBreaker: ContractAddress, token_: ContractAddress);
    fn cbInflowSafeTransferFrom(
        ref self: TContractState,
        _token: ContractAddress,
        _sender: ContractAddress,
        _recipient: ContractAddress,
        _amount: u256
    );

    fn cbOutflowSafeTransfer(
        ref self: TContractState,
        _token: ContractAddress,
        _recipient: ContractAddress,
        _amount: u256,
        _revertOnRateLimit: bool
    );

    fn cbInflowNative(ref self: TContractState, _amount: u256);

    fn cbOutflowNative(
        ref self: TContractState,
        _recipient: ContractAddress,
        amount: u256,
        _revertOnRateLimit: bool
    );
}


#[starknet::component]
mod ProtectedContract {
    use super::{ContractAddress, Array, IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{get_block_timestamp, get_caller_address, contract_address_const};
    use circuitbreaker::circuit_breaker::interface::{
        ICircuitBreakerDispatcher, ICircuitBreakerDispatcherTrait
    };

    #[storage]
    struct Storage {
        circuitBreaker: ICircuitBreakerDispatcher,
        token: IERC20Dispatcher,
        circuitBreaker_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    #[embeddable_as(Protected_impl)]
    impl ProtectedImpl<
        TContractState, +HasComponent<TContractState>
    > of super::IProtectedContract<ComponentState<TContractState>> {
        fn init(
            ref self: ComponentState<TContractState>,
            _circuitBreaker: ContractAddress,
            token_: ContractAddress
        ) {
            self
                .circuitBreaker
                .write(ICircuitBreakerDispatcher { contract_address: _circuitBreaker });
            self.token.write(IERC20Dispatcher { contract_address: token_ });
            self.circuitBreaker_address.write(_circuitBreaker);
        }

        fn cbInflowSafeTransferFrom(
            ref self: ComponentState<TContractState>,
            _token: ContractAddress,
            _sender: ContractAddress,
            _recipient: ContractAddress,
            _amount: u256
        ) { // // Transfer the tokens safely from sender to recipient
            self.token.read().transfer_from(_sender, _recipient, _amount);
            // Call the circuitBreaker's onTokenInflow
            self.circuitBreaker.read().onTokenInflow(_token, _amount);
        }

        fn cbOutflowSafeTransfer(
            ref self: ComponentState<TContractState>,
            _token: ContractAddress,
            _recipient: ContractAddress,
            _amount: u256,
            _revertOnRateLimit: bool
        ) { // // Transfer the tokens safely to the circuitBreaker
            self.token.read().transfer(self.circuitBreaker_address.read(), _amount);
            // Call the circuitBreaker's onTokenOutflow
            self
                .circuitBreaker
                .read()
                .onTokenOutflow(_token, _amount, _recipient, _revertOnRateLimit);
        }

        fn cbInflowNative(ref self: ComponentState<TContractState>, _amount: u256) {
            // Transfer the tokens safely from sender to recipient
            self.circuitBreaker.read().onNativeAssetInflow(_amount);
        }

        fn cbOutflowNative(
            ref self: ComponentState<TContractState>,
            _recipient: ContractAddress,
            amount: u256,
            _revertOnRateLimit: bool
        ) {
            // Transfer the native tokens safely through the circuitBreaker
            self.circuitBreaker.read().onNativeAssetOutflow(_recipient, _revertOnRateLimit, amount);
        }
    }
}
