use snforge_std::forge_print::PrintTrait;
use core::result::ResultTrait;
use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait};
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
use snforge_std::{start_prank, start_warp};

fn setup() -> (
    IMockDefiProtocolSafeDispatcher,
    ICircuitBreakerSafeDispatcher,
    ContractAddress,
    IERC20SafeDispatcher
) {
    let alice: ContractAddress = contract_address_const::<123>();
    let token1 = deploy_token_contract('ERC20', 'Akash1', 'AK1');
    let token2 = deploy_token_contract('ERC20c', 'Neelesh1', 'NH1');
    let circuitBreaker = deploy_circuit_breaker(
        'CircuitBreaker', alice, 259200_u64, 14400_u64, 300_u64
    );
    let mockdefi = deploy_defi('MockDeFiProtocol', circuitBreaker, token1);

    let mut address: Array<ContractAddress> = ArrayTrait::new();
    address.append(mockdefi);

    start_prank(circuitBreaker, alice);
    let circuit_breaker = get_circuit_breaker(circuitBreaker);
    circuit_breaker.addProtectedContracts(address);
    circuit_breaker.registerAsset(token1, 7000, 1000);
    circuit_breaker.registerAsset(token2, 7000, 1000);
    start_warp(circuitBreaker, 3600);
    let mock_defi = get_defi_contract(mockdefi);
    let token_imp = get_token_contract(token1);
    return (mock_defi, circuit_breaker, mockdefi, token_imp);
}

fn deploy_token_contract(
    contract_name: felt252, name: felt252, symbol: felt252
) -> ContractAddress {
    let contract = declare(contract_name);
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
    let contract_address = deploy_token_contract('ERC20', 'DAI', 'DAI');
    let contracterc20 = get_token_contract(contract_address);
    let name = contracterc20.name().unwrap();
    assert(name == 'DAI', 'Error');
}

// #[test]
// fn test_deploy_circuit() {
//     let alice: ContractAddress = contract_address_const::<123>();
//     let contract_address = deploy_circuit_breaker(
//         'CircuitBreaker', alice, 259200_u64, 14400_u64, 300_u64
//     );
//     let contract = get_circuit_breaker(contract_address);
//     let res = contract.isRateLimited().unwrap();

//     assert(res == false, 'Eror');
// }

#[test]
fn test_get_signer_public_key() {
    let contract_address = deploy_contract('Account');

    let safe_dispatcher = IAccountSafeDispatcher { contract_address };

    let guardian: felt252 = safe_dispatcher.get_signer_public_key().unwrap();
    assert(guardian == 'signer public key', 'Error bro');
}

// #[test]
// fn test_deposit_withDrawNoLimitTokenShouldBeSuccessful() {
//     let (mock_defi, circuit_breaker, mockdefi) = deployContracts1();
//     // let token1 = deploy_token_contract('ERC20', 'Akash1', 'AK1');
//     // let token2 = deploy_token_contract('ERC20', 'Neelesh1', 'NH1');
//     // let circuitBreaker = deploy_circuit_breaker('CircuitBreaker', '259200', '14400', '300');
//     // let mockdefi = deploy_defi('MockDeFiProtocol', circuitBreaker);

//     // let mut address: Array<ContractAddress> = ArrayTrait::new();
//     // address.append(mockdefi);

//     // start_prank(circuitBreaker, 123.try_into().unwrap());
//     // let circuit_breaker = get_circuit_breaker(circuitBreaker);
//     // circuit_breaker.addProtectedContracts(address);
//     // circuit_breaker.registerAsset(token1, 7000, 1000);
//     // circuit_breaker.registerAsset(token2, 7000, 1000);
//     // start_warp(circuitBreaker, 3600);
//     // let mock_defi = get_defi_contract(mockdefi);

//     let alice: ContractAddress = contract_address_const::<123>();
//     let unlimitedToken: ContractAddress = deploy_token_contract('ERC20', 'DAI', 'DAI');
//     let unlimited_token = get_token_contract(unlimitedToken);
//     unlimited_token.mint(alice, 10000_u256);
//     // let val : u256 = unlimited_token.balance_of(alice).unwrap();

//     // start_prank(unlimitedToken, alice);
//     // unlimited_token.approve(mockdefi, 10000);

//     // mock_defi.deposit(unlimitedToken, 10000);

//     let res: bool = circuit_breaker.isRateLimitTriggered(unlimitedToken).unwrap();
//     // res.print();
//     assert(circuit_breaker.isRateLimitTriggered(unlimitedToken).unwrap() == false, 'Error');
// }
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
    let token1 = deploy_token_contract('ERC20', 'Akash1', 'AK1');
    let token2 = deploy_token_contract('ERC20c', 'Neelesh1', 'NH1');
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
    circuit_breaker.registerAsset(token2, 7000_u256, 1000_u256);
    start_warp(circuitBreaker, 3600);
    let mock_defi = get_defi_contract(mockdefi);
    let token_imp = get_token_contract(token1);

    //Setup ends here

    token_imp.mint(alice, 1000000_u256);

    start_prank(token1, alice);
    token_imp.approve(mockdefi, 1000000_u256);

    start_prank(mockdefi, alice);
    mock_defi.deposit(token1, 1000000_u256);

    // //HACK
    let withdrawal_amount = 300000_u256;
    start_warp(mockdefi, 18000);
    start_prank(mockdefi, alice);
    // mock_defi.withdrawal(token1, withdrawal_amount);
    mock_defi.withdrawal(token1, withdrawal_amount);
    assert(circuit_breaker.isRateLimitTriggered(token1).unwrap() == true, 'not triggered');
}
