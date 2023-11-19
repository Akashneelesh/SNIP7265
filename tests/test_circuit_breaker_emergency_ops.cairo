// use snforge_std::forge_print::PrintTrait;
// use core::result::ResultTrait;
// use starknet::ContractAddress;

// use snforge_std::{declare, ContractClass, ContractClassTrait};
// use starknet::contract_address_const;

// use circuitbreaker::account::interface::IAccountSafeDispatcher;
// use circuitbreaker::account::interface::IAccountSafeDispatcherTrait;
// use circuitbreaker::circuit_breaker::interface::{
//     ICircuitBreakerSafeDispatcher, ICircuitBreakerSafeDispatcherTrait
// };

// use circuitbreaker::tests::mocks::defi::{
//     IMockDefiProtocolSafeDispatcher, IMockDefiProtocolSafeDispatcherTrait
// };
// use circuitbreaker::tests::mocks::erc20::{IERC20SafeDispatcher, IERC20SafeDispatcherTrait};
// use array::ArrayTrait;
// use snforge_std::{start_prank, start_warp, stop_prank};

// fn declare_token_contract(contract_name: felt252) -> ContractClass {
//     let contract = declare(contract_name);
//     contract
// }

// fn deploy_token_contract(
//     contract: ContractClass, name: felt252, symbol: felt252
// ) -> ContractAddress {
//     let mut calldata: Array<felt252> = ArrayTrait::new();
//     Serde::serialize(@name, ref calldata);
//     Serde::serialize(@symbol, ref calldata);
//     contract.deploy(@calldata).unwrap()
// }

// fn get_token_contract(address: ContractAddress) -> IERC20SafeDispatcher {
//     IERC20SafeDispatcher { contract_address: address }
// }

// fn deploy_circuit_breaker(
//     contract_name: felt252, address: ContractAddress, threedays: u64, fourhours: u64, fivemin: u64
// ) -> ContractAddress {
//     //259200 3days
//     //14400 4hours
//     //300 5minutes
//     // let threedays: felt252 = '259200';
//     // let fourhours: felt252 = '14400';
//     // let fivemin: felt252 = '300';
//     let contract = declare(contract_name);
//     let mut calldata: Array<felt252> = ArrayTrait::new();
//     Serde::serialize(@address, ref calldata);
//     Serde::serialize(@threedays, ref calldata);
//     Serde::serialize(@fourhours, ref calldata);
//     Serde::serialize(@fivemin, ref calldata);

//     contract.deploy(@calldata).unwrap()
// }

// fn get_circuit_breaker(address: ContractAddress) -> ICircuitBreakerSafeDispatcher {
//     ICircuitBreakerSafeDispatcher { contract_address: address }
// }

// fn deploy_defi(
//     contract_name: felt252, circuit_breaker_address: ContractAddress, token: ContractAddress
// ) -> ContractAddress {
//     let contract = declare(contract_name);
//     let mut calldata: Array<felt252> = ArrayTrait::new();
//     Serde::serialize(@circuit_breaker_address, ref calldata);
//     Serde::serialize(@token, ref calldata);

//     contract.deploy(@calldata).unwrap()
// }

// fn deploy_protected_contract(
//     contract_name: felt252, circuit_address: ContractAddress
// ) -> ContractAddress {
//     let contract = declare(contract_name);
//     let mut calldata: Array<felt252> = ArrayTrait::new();
//     Serde::serialize(@circuit_address, ref calldata);
//     contract.deploy(@calldata).unwrap()
// }

// fn get_defi_contract(contract_address: ContractAddress) -> IMockDefiProtocolSafeDispatcher {
//     IMockDefiProtocolSafeDispatcher { contract_address: contract_address }
// }

// fn deploy_contract(name: felt252) -> ContractAddress {
//     let contract = declare(name);
//     let mut calldata: Array<felt252> = ArrayTrait::new();
//     let signer: felt252 = 'signer public key';
//     let guardian: felt252 = 'guardian key';
//     Serde::serialize(@signer, ref calldata);
//     Serde::serialize(@guardian, ref calldata);
//     contract.deploy(@calldata).unwrap()
// }


