use starknet::ContractAddress;


#[starknet::interface]
trait INameRegistry<TContractState> {
    fn store_name(
        ref self: TContractState, name: felt252, registration_type: NameRegistry::RegistrationType
    );
    fn get_name(self: @TContractState, address: ContractAddress) -> felt252;
    fn get_owner(self: @TContractState) -> NameRegistry::Person;
    fn set_favorite_numbers(
        ref self: TContractState, address: ContractAddress, number: felt252
    );
}


#[starknet::contract]
mod NameRegistry {
    use starknet::ContractAddress;
    use starknet::get_caller_address;

    

    #[storage]
    struct Storage {
        names: LegacyMap::<ContractAddress, felt252>,
        registration_type: LegacyMap::<ContractAddress, RegistrationType>,
        total_names: u128,
        owner: Person,
        favorite_numbers: LegacyMap<ContractAddress, felt252>
    }

        #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StoredName: StoredName,
    }

    #[derive(Drop, starknet::Event)]
    struct StoredName {
        #[key]
        user: ContractAddress,
        name: felt252
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct Person {
        name: felt252,
        address: ContractAddress
    }

    #[derive(Drop, Serde, starknet::Store)]
    enum RegistrationType {
        finite: u64,
        infinite
    }



    #[constructor]
    fn constructor(ref self: ContractState, owner: Person) {
        self.names.write(owner.address, owner.name);
        self.total_names.write(1);
        self.owner.write(owner);
        self.favorite_numbers.write(owner.address, 0)
    }

    #[abi(embed_v0)] // when cairo 2.4.0, update to abi
    impl NameRegistry of super::INameRegistry<ContractState> {
        fn store_name(ref self: ContractState, name: felt252, registration_type: RegistrationType) {
            let caller = get_caller_address();
            self._store_name(caller, name, registration_type);
        }

        fn get_name(self: @ContractState, address: ContractAddress) -> felt252 {
            let name = self.names.read(address);
            name
        }
        fn get_owner(self: @ContractState) -> Person {
            let owner = self.owner.read();
            owner
        }
        fn set_favorite_numbers(ref self: ContractState, address: ContractAddress, number: felt252) {
            self.favorite_numbers.write(address, number);
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _store_name(
            ref self: ContractState,
            user: ContractAddress,
            name: felt252,
            registration_type: RegistrationType
        ) {
            let mut total_names = self.total_names.read();
            self.names.write(user, name);
            self.registration_type.write(user, registration_type);
            self.total_names.write(total_names + 1);
            self.emit(StoredName { user: user, name: name });

        }
    }

    fn get_contract_name() -> felt252 {
        'Name Registry'
    }

    fn get_owner_storage_address(self: @ContractState) -> starknet::StorageBaseAddress {
        self.owner.address()
    }
}