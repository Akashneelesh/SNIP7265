use core::clone::Clone;
use snforge_std::forge_print::PrintTrait;
use core::result::ResultTrait;
use starknet::ContractAddress;

use snforge_std::{declare, ContractClass, ContractClassTrait};
use starknet::contract_address_const;

use circuitbreaker::account::interface::IAccountSafeDispatcher;
use circuitbreaker::account::interface::IAccountSafeDispatcherTrait;
use circuitbreaker::circuit_breaker::interface::{
    ICircuitBreakerSafeDispatcher, ICircuitBreakerSafeDispatcherTrait
};

use circuitbreaker::tests::mocks::defi::{
    IMockDefiProtocolSafeDispatcher, IMockDefiProtocolSafeDispatcherTrait
};
use circuitbreaker::tests::mocks::erc20::{IERC20SafeDispatcher, IERC20SafeDispatcherTrait};
use array::ArrayTrait;
use snforge_std::{start_prank, start_warp, stop_prank};

// fn setup() -> (
//     IMockDefiProtocolSafeDispatcher,
//     ICircuitBreakerSafeDispatcher,
//     ContractAddress,
//     IERC20SafeDispatcher
// ) {
//     let alice: ContractAddress = contract_address_const::<123>();
//     let token1 = deploy_token_contract('ERC20', 'Akash1', 'AK1');
//     let token2 = deploy_token_contract('ERC20c', 'Neelesh1', 'NH1');
//     let circuitBreaker = deploy_circuit_breaker(
//         'CircuitBreaker', alice, 259200_u64, 14400_u64, 300_u64
//     );
//     let mockdefi = deploy_defi('MockDeFiProtocol', circuitBreaker, token1);

//     let mut address: Array<ContractAddress> = ArrayTrait::new();
//     address.append(mockdefi);

//     start_prank(circuitBreaker, alice);
//     let circuit_breaker = get_circuit_breaker(circuitBreaker);
//     circuit_breaker.addProtectedContracts(address);
//     circuit_breaker.registerAsset(token1, 7000, 1000);
//     circuit_breaker.registerAsset(token2, 7000, 1000);
//     start_warp(circuitBreaker, 3600);
//     let mock_defi = get_defi_contract(mockdefi);
//     let token_imp = get_token_contract(token1);
//     return (mock_defi, circuit_breaker, mockdefi, token_imp);
// }

fn setup() {
    let declare = declare_token_contract('ERC20');
    let token = deploy_token_contract(declare, 'USDC', 'USDC');
    let admin: ContractAddress = contract_address_const::<53>();
    let alice: ContractAddress = contract_address_const::<123>();
    let circuitbreaker = deploy_circuit_breaker(
        'CircuitBreaker', admin, 259200_u64, 14400_u64, 300_u64
    );
    let defi = deploy_defi('MockDeFiProtocol', circuitbreaker, token);
    let mut addresses: Array<ContractAddress> = ArrayTrait::new();
    addresses.append(defi);
    let circuit_breaker = get_circuit_breaker(circuitbreaker);

    start_prank(circuitbreaker, admin);
    circuit_breaker.addProtectedContracts(addresses);

    start_prank(circuitbreaker, admin);
    circuit_breaker.registerAsset(token, 7000_u256, 1000_u256);
    start_prank(circuitbreaker, admin);
    circuit_breaker.registerAsset(contract_address_const::<1>(), 7000_u256, 1000_u256);
    start_warp(circuitbreaker, 3600);

    let secondToken = deploy_token_contract(declare, 'DAI', 'DAI');
    start_prank(circuitbreaker, admin);
    circuit_breaker.registerAsset(secondToken, 7000_u256, 1000_u256);
}

// fn setup() {
//     let alice: ContractAddress = contract_address_const::<123>();
//     let declare = declare_token_contract('ERC20');
//     let token1 = deploy_token_contract(declare, 'Akash1', 'AK1');
//     let token2 = deploy_token_contract(declare, 'Neelesh1', 'NH1');
//     let circuitBreaker = deploy_circuit_breaker(
//         'CircuitBreaker', alice, 259200_u64, 14400_u64, 300_u64
//     );
//     let mockdefi = deploy_defi('MockDeFiProtocol', circuitBreaker, token1);

//     let mut address: Array<ContractAddress> = ArrayTrait::new();
//     address.append(mockdefi);

//     start_prank(circuitBreaker, alice);
//     let circuit_breaker = get_circuit_breaker(circuitBreaker);
//     start_prank(circuitBreaker, alice);
//     circuit_breaker.addProtectedContracts(address);
//     start_prank(circuitBreaker, alice);
//     circuit_breaker.registerAsset(token1, 7000, 1000);
//     circuit_breaker.registerAsset(token2, 7000, 1000);
//     start_warp(circuitBreaker, 3600);
// // let mock_defi = get_defi_contract(mockdefi);
// // let token_imp = get_token_contract(token1);
// // return (mock_defi, circuit_breaker, mockdefi, token_imp);
// }

#[test]
fn test_deposit_withdrawNoLimitTokenShouldBeSuccessful() {
    let alice: ContractAddress = contract_address_const::<123>();
    let declare = declare_token_contract('ERC20');
    let token1 = deploy_token_contract(declare, 'Akash1', 'AK1');
    // let token2 = deploy_token_contract('ERC20c', 'Neelesh1', 'NH1');
    let circuitBreaker = deploy_circuit_breaker(
        'CircuitBreaker', alice, 259200_u64, 14400_u64, 300_u64
    );
    let mockdefi = deploy_defi('MockDeFiProtocol', circuitBreaker, token1);
    let mock_defi = get_defi_contract(mockdefi);

    let mut address: Array<ContractAddress> = ArrayTrait::new();
    address.append(mockdefi);

    start_prank(circuitBreaker, alice);
    let circuit_breaker = get_circuit_breaker(circuitBreaker);
    start_prank(circuitBreaker, alice);
    circuit_breaker.addProtectedContracts(address);
    start_prank(circuitBreaker, alice);
    circuit_breaker.registerAsset(token1, 7000, 1000);
    // circuit_breaker.registerAsset(token2, 7000, 1000);
    start_warp(circuitBreaker, 3600);

    let token_unlimited = deploy_token_contract(declare, 'DAI', 'DAI');
    let tokenunlimited = get_token_contract(token_unlimited);
    tokenunlimited.mint(alice, 10000_u256);

    tokenunlimited.approve(mockdefi, 10000_u256);

    mock_defi.deposit(token_unlimited, 10000_u256);

    assert(circuit_breaker.isRateLimitTriggered(token_unlimited).unwrap() == false, 'Incorrect');
}

fn declare_token_contract(contract_name: felt252) -> ContractClass {
    let contract = declare(contract_name);
    contract
}

fn declare_defi_contract(contract_name: felt252) -> ContractClass {
    let contract = declare(contract_name);
    contract
}

fn declare_circuitbreaker(contract_name: felt252) -> ContractClass {
    let contract = declare(contract_name);
    contract
}

fn deploy_circuitbreaker1(
    contract: ContractClass,
    admin: ContractAddress,
    rate_limit_cooldown_period_: u64,
    withdrawal_period_: u64,
    liquidity_tick_length_: u64
) -> ContractAddress {
    let alice: ContractAddress = contract_address_const::<123>();
    let mut calldata: Array<felt252> = ArrayTrait::new();
    Serde::serialize(@alice, ref calldata);
    Serde::serialize(@rate_limit_cooldown_period_, ref calldata);
    Serde::serialize(@withdrawal_period_, ref calldata);
    Serde::serialize(@liquidity_tick_length_, ref calldata);

    contract.deploy(@calldata).unwrap()
}

fn deploy_defi_contract1(
    contract: ContractClass, circuit_breaker_address: ContractAddress, token: ContractAddress
) -> ContractAddress {
    let mut calldata: Array<felt252> = ArrayTrait::new();
    Serde::serialize(@circuit_breaker_address, ref calldata);
    Serde::serialize(@token, ref calldata);

    contract.deploy(@calldata).unwrap()
}

fn deploy_token_contract(
    contract: ContractClass, name: felt252, symbol: felt252
) -> ContractAddress {
    let mut calldata: Array<felt252> = ArrayTrait::new();
    Serde::serialize(@name, ref calldata);
    Serde::serialize(@symbol, ref calldata);
    contract.deploy(@calldata).unwrap()
}

fn get_token_contract(address: ContractAddress) -> IERC20SafeDispatcher {
    IERC20SafeDispatcher { contract_address: address }
}

fn deploy_circuit_breaker(
    contract_name: felt252, address: ContractAddress, threedays: u64, fourhours: u64, fivemin: u64
) -> ContractAddress {
    //259200 3days
    //14400 4hours
    //300 5minutes
    // let threedays: felt252 = '259200';
    // let fourhours: felt252 = '14400';
    // let fivemin: felt252 = '300';
    let contract = declare(contract_name);
    let mut calldata: Array<felt252> = ArrayTrait::new();
    Serde::serialize(@address, ref calldata);
    Serde::serialize(@threedays, ref calldata);
    Serde::serialize(@fourhours, ref calldata);
    Serde::serialize(@fivemin, ref calldata);

    contract.deploy(@calldata).unwrap()
}

fn get_circuit_breaker(address: ContractAddress) -> ICircuitBreakerSafeDispatcher {
    ICircuitBreakerSafeDispatcher { contract_address: address }
}

fn deploy_defi(
    contract_name: felt252, circuit_breaker_address: ContractAddress, token: ContractAddress
) -> ContractAddress {
    let contract = declare(contract_name);
    let mut calldata: Array<felt252> = ArrayTrait::new();
    Serde::serialize(@circuit_breaker_address, ref calldata);
    Serde::serialize(@token, ref calldata);

    contract.deploy(@calldata).unwrap()
}

fn deploy_protected_contract(
    contract_name: felt252, circuit_address: ContractAddress
) -> ContractAddress {
    let contract = declare(contract_name);
    let mut calldata: Array<felt252> = ArrayTrait::new();
    Serde::serialize(@circuit_address, ref calldata);
    contract.deploy(@calldata).unwrap()
}

fn get_defi_contract(contract_address: ContractAddress) -> IMockDefiProtocolSafeDispatcher {
    IMockDefiProtocolSafeDispatcher { contract_address: contract_address }
}

fn deploy_contract(name: felt252) -> ContractAddress {
    let contract = declare(name);
    let mut calldata: Array<felt252> = ArrayTrait::new();
    let signer: felt252 = 'signer public key';
    let guardian: felt252 = 'guardian key';
    Serde::serialize(@signer, ref calldata);
    Serde::serialize(@guardian, ref calldata);
    contract.deploy(@calldata).unwrap()
}

#[test]
fn test_get_name() {
    let declare = declare_token_contract('ERC20');
    let contract_address = deploy_token_contract(declare, 'DAI', 'DAI');
    let contracterc20 = get_token_contract(contract_address);
    let name = contracterc20.name().unwrap();
    assert(name == 'DAI', 'Error');
}

#[test]
fn test_deposit_shouldBeSuccessful() {
    let alice: ContractAddress = contract_address_const::<123>();
    let declare = declare_token_contract('ERC20');
    let token1 = deploy_token_contract(declare, 'Akash1', 'AK1');
    let token2 = deploy_token_contract(declare, 'Neelesh1', 'NH1');
    let circuitBreaker = deploy_circuit_breaker(
        'CircuitBreaker', alice, 259200_u64, 14400_u64, 300_u64
    );
    let circuit_breaker = get_circuit_breaker(circuitBreaker);
    let token_1 = get_token_contract(token1);
    let token_2 = get_token_contract(token2);
    let declare = declare_defi_contract('MockDeFiProtocol');
    let mockdefi = deploy_defi_contract1(declare, circuitBreaker, token1);
    let mock_defi = get_defi_contract(mockdefi);

    let mut address: Array<ContractAddress> = ArrayTrait::new();
    address.append(mockdefi);

    start_prank(circuitBreaker, alice);
    let circuit_breaker = get_circuit_breaker(circuitBreaker);
    start_prank(circuitBreaker, alice);
    circuit_breaker.addProtectedContracts(address);
    start_prank(circuitBreaker, alice);
    circuit_breaker.registerAsset(token1, 7000, 1000);
    circuit_breaker.registerAsset(token2, 7000, 1000);
    start_warp(circuitBreaker, 3600);

    token_1.mint(alice, 10000_u256);
    start_prank(token1, alice);
    token_1.approve(mockdefi, 10000_u256);
    mock_defi.deposit(token1, 10_u256);

    assert(circuit_breaker.isRateLimitTriggered(token1).unwrap() == false, 'False');
}

#[test]
fn test_withdrawal_shouldBeSuccessful() {
    let alice: ContractAddress = contract_address_const::<123>();
    let declare = declare_token_contract('ERC20');
    let token1 = deploy_token_contract(declare, 'Akash1', 'AK1');
    let token2 = deploy_token_contract(declare, 'Neelesh1', 'NH1');
    let circuitBreaker = deploy_circuit_breaker(
        'CircuitBreaker', alice, 259200_u64, 14400_u64, 300_u64
    );
    let circuit_breaker = get_circuit_breaker(circuitBreaker);
    let token_1 = get_token_contract(token1);
    let token_2 = get_token_contract(token2);
    let mockdefi = deploy_defi('MockDeFiProtocol', circuitBreaker, token1);
    let mock_defi = get_defi_contract(mockdefi);

    let mut address: Array<ContractAddress> = ArrayTrait::new();
    address.append(mockdefi);

    start_prank(circuitBreaker, alice);
    let circuit_breaker = get_circuit_breaker(circuitBreaker);
    start_prank(circuitBreaker, alice);
    circuit_breaker.addProtectedContracts(address);
    start_prank(circuitBreaker, alice);
    circuit_breaker.registerAsset(token1, 7000, 1000);
    circuit_breaker.registerAsset(token2, 7000, 1000);
    start_warp(circuitBreaker, 3600);

    token_1.mint(alice, 10000_u256);
    start_prank(token1, alice);
    token_1.approve(mockdefi, 10000_u256);
    mock_defi.deposit(token1, 1000_u256);

    start_warp(mockdefi, 3600);
    mock_defi.withdrawal(token1, 60_u256);

    assert(circuit_breaker.isRateLimitTriggered(token1).unwrap() == false, 'Incorrect');
}

#[test]
fn test_deploy_circuit() {
    let alice: ContractAddress = contract_address_const::<123>();
    let contract_address = deploy_circuit_breaker(
        'CircuitBreaker', alice, 259200_u64, 14400_u64, 300_u64
    );
    let contract = get_circuit_breaker(contract_address);
    let res = contract.isRateLimited().unwrap();

    assert(res == false, 'Eror');
}

#[test]
fn test_get_signer_public_key() {
    let contract_address = deploy_contract('Account');

    let safe_dispatcher = IAccountSafeDispatcher { contract_address };

    let guardian: felt252 = safe_dispatcher.get_signer_public_key().unwrap();
    assert(guardian == 'signer public key', 'Error bro');
}
#[test]
fn test_deposit_withDrawNoLimitTokenShouldBeSuccessful() {
    let alice: ContractAddress = contract_address_const::<123>();
    let declare = declare_token_contract('ERC20');
    let token1 = deploy_token_contract(declare, 'Akash1', 'AK1');
    // let token2 = deploy_token_contract('ERC20c', 'Neelesh1', 'NH1');
    let circuitBreaker = deploy_circuit_breaker(
        'CircuitBreaker', alice, 259200_u64, 14400_u64, 300_u64
    );
    let mockdefi = deploy_defi('MockDeFiProtocol', circuitBreaker, token1);
    let mock_defi = get_defi_contract(mockdefi);

    let mut address: Array<ContractAddress> = ArrayTrait::new();
    address.append(mockdefi);

    start_prank(circuitBreaker, alice);
    let circuit_breaker = get_circuit_breaker(circuitBreaker);
    start_prank(circuitBreaker, alice);
    circuit_breaker.addProtectedContracts(address);
    start_prank(circuitBreaker, alice);
    circuit_breaker.registerAsset(token1, 7000, 1000);
    // circuit_breaker.registerAsset(token2, 7000, 1000);
    start_warp(circuitBreaker, 3600);
    // let token1 = deploy_token_contract('ERC20', 'Akash1', 'AK1');
    // let token2 = deploy_token_contract('ERC20', 'Neelesh1', 'NH1');
    // let circuitBreaker = deploy_circuit_breaker('CircuitBreaker', '259200', '14400', '300');
    // let mockdefi = deploy_defi('MockDeFiProtocol', circuitBreaker);

    // let mut address: Array<ContractAddress> = ArrayTrait::new();
    // address.append(mockdefi);

    // start_prank(circuitBreaker, 123.try_into().unwrap());
    // let circuit_breaker = get_circuit_breaker(circuitBreaker);
    // circuit_breaker.addProtectedContracts(address);
    // circuit_breaker.registerAsset(token1, 7000, 1000);
    // circuit_breaker.registerAsset(token2, 7000, 1000);
    // start_warp(circuitBreaker, 3600);
    // let mock_defi = get_defi_contract(mockdefi);

    let alice: ContractAddress = contract_address_const::<123>();
    let unlimitedToken: ContractAddress = deploy_token_contract(declare, 'DAI', 'DAI');
    let unlimited_token = get_token_contract(unlimitedToken);
    unlimited_token.mint(alice, 10000_u256);
    let val: u256 = unlimited_token.balance_of(alice).unwrap();

    start_prank(unlimitedToken, alice);
    unlimited_token.approve(mockdefi, 10000);

    mock_defi.deposit(unlimitedToken, 10000);
    let res: bool = circuit_breaker.isRateLimitTriggered(unlimitedToken).unwrap();
    // res.print();
    assert(circuit_breaker.isRateLimitTriggered(unlimitedToken).unwrap() == false, 'Error');

    let withdrawal_amount = 300001_u256;
    start_warp(mockdefi, 3600);

    start_prank(mockdefi, alice);
    mock_defi.withdrawal(unlimitedToken, 10000_u256);

    let res: bool = circuit_breaker.isRateLimitTriggered(unlimitedToken).unwrap();
    // res.print();
    assert(circuit_breaker.isRateLimitTriggered(unlimitedToken).unwrap() == false, 'Error');
}
// #[test]

//This fn has not been implemented yet should implement
//@todo
// #[test]
// fn test_clearBacklog_shouldBeSuccessful() {
//     let alice: ContractAddress = contract_address_const::<123>();
//     let token1 = deploy_token_contract('ERC20', 'Akash1', 'AK1');
//     let token2 = deploy_token_contract('ERC20c', 'Neelesh1', 'NH1');
//     let circuitBreaker = deploy_circuit_breaker(
//         'CircuitBreaker', alice, 259200_u64, 14400_u64, 300_u64
//     );
//     let mockdefi = deploy_defi('MockDeFiProtocol', circuitBreaker);

//     let mut address: Array<ContractAddress> = ArrayTrait::new();
//     address.append(mockdefi);

//     start_prank(circuitBreaker, alice);
//     let circuit_breaker = get_circuit_breaker(circuitBreaker);
//     circuit_breaker.addProtectedContracts(address);
//     circuit_breaker.registerAsset(token1, 7000, 1000);
//     circuit_breaker.registerAsset(token2, 7000, 1000);
//     start_warp(circuitBreaker, 3600);
//     let mock_defi = get_defi_contract(mockdefi);
//     let token_imp = get_token_contract(token1);

//     //Setup ends here

//     token_imp.mint(alice, 10000_u256);
//     let res = token_imp.balance_of(alice).unwrap();

//     start_prank(token1, alice);
//     token_imp.approve(mockdefi,10000_u256);

//     start_prank(mockdefi, alice);
//     mock_defi.deposit(token1,1);

//     start_warp(mockdefi, 7200);
//     start_prank(mockdefi, alice);
//     mock_defi.deposit(token1,1);

//     start_warp(mockdefi, 10800);
//     start_prank(mockdefi, alice);
//     mock_defi.deposit(token1,1);

//     start_warp(mockdefi, 14400);
//     start_prank(mockdefi, alice);
//     mock_defi.deposit(token1,1);

//     start_warp(mockdefi, 18000);
//     start_prank(mockdefi, alice);
//     mock_defi.deposit(token1,1);

//     start_warp(mockdefi, 19800);
//     circuit_breaker.clearBackLog(token1,10);

//     assert(res == 1000_u256, 'err');
// // assert(token_imp.balance_of(alice).unwrap() == 10000_u256, 'error');
// }

// <--------------------------------------------------------------------------->

#[test]
fn test_breach() {
    let alice: ContractAddress = contract_address_const::<123>();
    let declare = declare_token_contract('ERC20');
    let token1 = deploy_token_contract(declare, 'Akash1', 'AK1');
    let token2 = deploy_token_contract(declare, 'Neelesh1', 'NH1');

    let circuitBreaker = deploy_circuit_breaker(
        'CircuitBreaker', alice, 259200_u64, 14400_u64, 300_u64
    );
    // let protectedContract = deploy_protected_contract('ProtectedContract', circuitBreaker);
    let mockdefi = deploy_defi('MockDeFiProtocol', circuitBreaker, token1);

    let mut address: Array<ContractAddress> = ArrayTrait::new();
    address.append(mockdefi);

    start_prank(circuitBreaker, alice);
    let circuit_breaker = get_circuit_breaker(circuitBreaker);

    circuit_breaker.addProtectedContracts(address);

    circuit_breaker.registerAsset(token1, 7000_u256, 1000_u256);
    let limiter = circuit_breaker.get_token_limiter(token1).unwrap();
    assert(limiter.min_liq_retained_bps == 7000_u256, 'Not right');
    assert(limiter.limit_begin_threshold == 1000_u256, 'Not right');
    circuit_breaker.registerAsset(token2, 7000_u256, 1000_u256);
    start_warp(circuitBreaker, 3600);
    let mock_defi = get_defi_contract(mockdefi);
    let token_imp = get_token_contract(token1);
    stop_prank(circuitBreaker);
    // //Setup ends here

    token_imp.mint(alice, 1000000_u256);

    start_prank(token1, alice);
    token_imp.approve(mockdefi, 1000000_u256);
    // // stop_prank(token1);

    start_prank(mockdefi, alice);
    mock_defi.deposit(token1, 1000000_u256);

    // let balance = token_imp.balance_of(mockdefi);
    // balance.unwrap().print();
    // assert(balance.unwrap() == 1000000_u256, 'Incorrect');
    // //HACK
    let withdrawal_amount = 300001_u256;
    start_warp(mockdefi, 18000);

    // mock_defi.withdrawal(token1, withdrawal_amount);
    start_prank(mockdefi, alice);
    mock_defi.withdrawal(token1, withdrawal_amount);
    stop_prank(mockdefi);
    assert(circuit_breaker.isRateLimitTriggered(token1).unwrap() == true, 'not triggered');
}

#[test]
fn test_breachAndLimitExpired() {
    let alice: ContractAddress = contract_address_const::<123>();
    let declare = declare_token_contract('ERC20');
    let token1 = deploy_token_contract(declare, 'Akash1', 'AK1');
    let token2 = deploy_token_contract(declare, 'Neelesh1', 'NH1');
    let circuitBreaker = deploy_circuit_breaker(
        'CircuitBreaker', alice, 259200_u64, 14400_u64, 300_u64
    );
    let circuit_breaker = get_circuit_breaker(circuitBreaker);
    let token_1 = get_token_contract(token1);
    let token_2 = get_token_contract(token2);
    let mockdefi = deploy_defi('MockDeFiProtocol', circuitBreaker, token1);
    let mock_defi = get_defi_contract(mockdefi);

    let mut address: Array<ContractAddress> = ArrayTrait::new();
    address.append(mockdefi);

    start_prank(circuitBreaker, alice);
    let circuit_breaker = get_circuit_breaker(circuitBreaker);
    start_prank(circuitBreaker, alice);
    circuit_breaker.addProtectedContracts(address);
    start_prank(circuitBreaker, alice);
    circuit_breaker.registerAsset(token1, 7000, 1000);
    circuit_breaker.registerAsset(token2, 7000, 1000);
    start_warp(circuitBreaker, 3600);

    token_1.mint(alice, 1000000_u256);
    start_prank(token1, alice);
    token_1.approve(mockdefi, 1000000_u256);
    mock_defi.deposit(token1, 1000000_u256);

    let withdrawal_amount: u256 = 300001_u256;
    start_warp(mockdefi, 18000);
    mock_defi.withdrawal(token1, withdrawal_amount);
    assert(circuit_breaker.isRateLimitTriggered(token1).unwrap() == true, 'Incorrect');
}


#[test]
#[should_panic]
fn test_should_panic() {
    let declare = declare_token_contract('ERC20');
    let token = deploy_token_contract(declare, 'USDC', 'USDC');
    let admin: ContractAddress = contract_address_const::<53>();
    let alice: ContractAddress = contract_address_const::<123>();
    let circuitbreaker = deploy_circuit_breaker(
        'CircuitBreaker', admin, 259200_u64, 14400_u64, 300_u64
    );
    let defi = deploy_defi('MockDeFiProtocol', circuitbreaker, token);
    let mut addresses: Array<ContractAddress> = ArrayTrait::new();
    addresses.append(defi);
    let circuit_breaker = get_circuit_breaker(circuitbreaker);

    start_prank(circuitbreaker, admin);
    circuit_breaker.addProtectedContracts(addresses);

    start_prank(circuitbreaker, admin);
    circuit_breaker.registerAsset(token, 7000_u256, 1000_u256);
    start_prank(circuitbreaker, admin);
    circuit_breaker.registerAsset(contract_address_const::<1>(), 7000_u256, 1000_u256);
    start_warp(circuitbreaker, 3600);

    let secondToken = deploy_token_contract(declare, 'DAI', 'DAI');
    start_prank(circuitbreaker, admin);
    circuit_breaker.registerAsset(secondToken, 7000_u256, 1000_u256);

    let token_call = get_token_contract(token);
    token_call.mint(alice, 1000000_u256);

    start_prank(token, alice);
    token_call.approve(defi, 1000000_u256);

    let defi_call = get_defi_contract(defi);

    start_prank(defi, alice);
    defi_call.deposit(token, 1000000_u256);

    let withdrawalAmount = 300001_u256;
    start_warp(defi, 18000);
    start_prank(defi, alice);
    defi_call.withdrawal(token, withdrawalAmount);
    assert(circuit_breaker.isRateLimited().unwrap() == true, 'error');
    assert(circuit_breaker.isRateLimitTriggered(secondToken).unwrap() == false, 'error2');
}

#[test]
fn test_addProtectedcontracts() {
    let declare = declare_token_contract('ERC20');
    let token = deploy_token_contract(declare, 'USDC', 'USDC');
    let admin: ContractAddress = contract_address_const::<53>();
    let alice: ContractAddress = contract_address_const::<123>();
    let circuitbreaker = deploy_circuit_breaker(
        'CircuitBreaker', admin, 259200_u64, 14400_u64, 300_u64
    );
    let declare = declare_defi_contract('MockDeFiProtocol');
    let mockdefi = deploy_defi_contract1(declare, circuitbreaker, token);
    let mock_defi = get_defi_contract(mockdefi);
    let mut addresses: Array<ContractAddress> = ArrayTrait::new();
    addresses.append(mockdefi);
    let circuit_breaker = get_circuit_breaker(circuitbreaker);

    start_prank(circuitbreaker, admin);
    circuit_breaker.addProtectedContracts(addresses);

    start_prank(circuitbreaker, admin);
    circuit_breaker.registerAsset(token, 7000_u256, 1000_u256);
    start_prank(circuitbreaker, admin);
    circuit_breaker.registerAsset(contract_address_const::<1>(), 7000_u256, 1000_u256);
    start_warp(circuitbreaker, 3600);

    let secondToken = deploy_token_contract(declare, 'DAI', 'DAI');
    start_prank(circuitbreaker, admin);
    circuit_breaker.registerAsset(secondToken, 7000_u256, 1000_u256);

    let secondDefi = deploy_defi_contract1(declare, circuitbreaker, token);

    let mut addresses: Array<ContractAddress> = ArrayTrait::new();
    addresses.append(secondDefi);

    start_prank(circuitbreaker, admin);
    circuit_breaker.addProtectedContracts(addresses);

    assert(circuit_breaker.isProtectedContract(secondDefi).unwrap() == true, 'issue');
}

#[test]
fn test_removeProtectedContract() {
    let declare = declare_token_contract('ERC20');
    let token = deploy_token_contract(declare, 'USDC', 'USDC');
    let admin: ContractAddress = contract_address_const::<53>();
    let alice: ContractAddress = contract_address_const::<123>();
    let circuitbreaker = deploy_circuit_breaker(
        'CircuitBreaker', admin, 259200_u64, 14400_u64, 300_u64
    );
    let declare = declare_defi_contract('MockDeFiProtocol');
    let mockdefi = deploy_defi_contract1(declare, circuitbreaker, token);
    let mock_defi = get_defi_contract(mockdefi);
    let mut addresses: Array<ContractAddress> = ArrayTrait::new();
    addresses.append(mockdefi);
    let circuit_breaker = get_circuit_breaker(circuitbreaker);

    start_prank(circuitbreaker, admin);
    circuit_breaker.addProtectedContracts(addresses);

    start_prank(circuitbreaker, admin);
    circuit_breaker.registerAsset(token, 7000_u256, 1000_u256);
    start_prank(circuitbreaker, admin);
    circuit_breaker.registerAsset(contract_address_const::<1>(), 7000_u256, 1000_u256);
    start_warp(circuitbreaker, 3600);

    let secondToken = deploy_token_contract(declare, 'DAI', 'DAI');
    start_prank(circuitbreaker, admin);
    circuit_breaker.registerAsset(secondToken, 7000_u256, 1000_u256);

    let secondDefi = deploy_defi_contract1(declare, circuitbreaker, token);

    let mut addresses: Array<ContractAddress> = ArrayTrait::new();
    addresses.append(secondDefi);

    start_prank(circuitbreaker, admin);
    circuit_breaker.addProtectedContracts(addresses);

    let mut addressess: Array<ContractAddress> = ArrayTrait::new();
    addressess.append(secondDefi);

    start_prank(circuitbreaker, admin);
    circuit_breaker.removeProtectedContracts(addressess);
    assert(circuit_breaker.isProtectedContract(secondDefi).unwrap() == false, 'incorrect');
}
#[test]
fn test_initialization() {
    let declare = declare_token_contract('ERC20');
    let token = deploy_token_contract(declare, 'USDC', 'USDC');
    let admin: ContractAddress = contract_address_const::<53>();
    let alice: ContractAddress = contract_address_const::<123>();
    let declare = declare_circuitbreaker('CircuitBreaker');
    let circuitbreaker = deploy_circuitbreaker1(declare, admin, 259200_u64, 14400_u64, 300_u64);

    let declare = declare_defi_contract('MockDeFiProtocol');
    let mockdefi = deploy_defi_contract1(declare, circuitbreaker, token);
    let mock_defi = get_defi_contract(mockdefi);
    let mut addresses: Array<ContractAddress> = ArrayTrait::new();
    addresses.append(mockdefi);
    let circuit_breaker = get_circuit_breaker(circuitbreaker);

    start_prank(circuitbreaker, admin);
    circuit_breaker.addProtectedContracts(addresses);

    start_prank(circuitbreaker, admin);
    circuit_breaker.registerAsset(token, 7000_u256, 1000_u256);
    start_prank(circuitbreaker, admin);
    circuit_breaker.registerAsset(contract_address_const::<1>(), 7000_u256, 1000_u256);
    start_warp(circuitbreaker, 3600);

    let newCircuitBreaker = deploy_circuit_breaker(
        'CircuitBreaker', admin, 259200_u64, 14400_u64, 300_u64
    );

    let new_circuitbreaker = get_circuit_breaker(newCircuitBreaker);
    assert(new_circuitbreaker.admin().unwrap() == admin, 'Not the admin');
}

