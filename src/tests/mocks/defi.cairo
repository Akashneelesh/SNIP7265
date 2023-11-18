use array::SpanSerde;
use starknet::{ContractAddress, get_caller_address, ClassHash};

#[starknet::interface]
trait IMockDefiProtocol<TContractState> {
    fn deposit(ref self: TContractState, token: starknet::ContractAddress, amount: u256);

    fn withdrawal(ref self: TContractState, token: starknet::ContractAddress, amount: u256);

    fn depositNoCircuitBreaker(
        ref self: TContractState, token: starknet::ContractAddress, amount: u256
    );

    fn depositNative(ref self: TContractState, amount: u256);

    fn withdrawalNative(ref self: TContractState, amount: u256);
    fn upgrade(ref self: TContractState, implementation: ClassHash);
}

#[starknet::contract]
mod MockDeFiProtocol {
    use circuitbreaker::protected_contract::protected_contract::IProtectedContract;
    use starknet::{ContractAddress, get_caller_address, ClassHash};
    use starknet::syscalls::replace_class_syscall;
    // use circuitbreaker::protected_contract::protected_contract::ProtectedContract::ProtectedContractTrait;

    use circuitbreaker::tests::mocks::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use circuitbreaker::circuit_breaker::circuit_breaker::CircuitBreaker;
    use circuitbreaker::protected_contract::protected_contract::{
        IProtectedContractDispatcher, IProtectedContractDispatcherTrait
    };

    use starknet::{get_contract_address};
    use super::IMockDefiProtocol;


    #[storage]
    struct Storage {
        token: IERC20Dispatcher,
        ProtectedContract: IProtectedContractDispatcher,
        #[substorage(v0)]
        protected_contract: circuitbreaker::protected_contract::protected_contract::ProtectedContract::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        protected_event: circuitbreaker::protected_contract::protected_contract::ProtectedContract::Event,
    }

    component!(
        path: circuitbreaker::protected_contract::protected_contract::ProtectedContract,
        storage: protected_contract,
        event: protected_event
    );


    impl IProtected =
        circuitbreaker::protected_contract::protected_contract::ProtectedContract::Protected_impl<
            ContractState
        >;

    //
    // Constructor
    //

    #[constructor]
    fn constructor(
        ref self: ContractState, circuit_breaker: starknet::ContractAddress, token: ContractAddress
    ) {
        self.protected_contract.init(circuit_breaker, token);
    }

    #[external(v0)]
    impl MockDeFiProtocolImpl of IMockDefiProtocol<ContractState> {
        fn deposit(ref self: ContractState, token: starknet::ContractAddress, amount: u256) {
            // IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
            let caller = get_caller_address();
            let this = get_contract_address();

            self.protected_contract.cbInflowSafeTransferFrom(token, caller, this, amount);
        // Your logic here
        }

        fn withdrawal(ref self: ContractState, token: starknet::ContractAddress, amount: u256) {
            //  Your logic here

            let caller = get_caller_address();
            let this = get_contract_address();
            self.protected_contract.cbOutflowSafeTransfer(token, caller, amount, false);
        }

        fn depositNoCircuitBreaker(
            ref self: ContractState, token: starknet::ContractAddress, amount: u256
        ) {
            let caller = get_caller_address();
            let this = get_contract_address();
            let ERC20 = IERC20Dispatcher { contract_address: token };
            ERC20.transfer_from(caller, this, amount);
        // Your logic here
        }

        fn depositNative(ref self: ContractState, amount: u256) {
            // let state: CircuitBreaker::ContractState = CircuitBreaker::unsafe_new_contract_state();
            self.protected_contract.cbInflowNative(amount);
        }

        fn withdrawalNative(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            self.protected_contract.cbOutflowNative(caller, amount, false);
        }
        fn upgrade(ref self: ContractState, implementation: ClassHash) {
            // assert(self.ownable_storage.owner() == get_caller_address(), 'Not owner');
            replace_class_syscall(implementation).unwrap();
        }
    }
}
