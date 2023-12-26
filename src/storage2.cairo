use starknet::ContractAddress;


#[starknet::interface]
trait INameRegistry<TContractState> {
    fn store_name(
        ref self: TContractState, name: felt252);
    fn get_name(self: @TContractState, address: ContractAddress) -> felt252;
    fn get_owner(self: @TContractState) -> NameRegistry::Person;
    fn set_favorite_number(
        ref self: TContractState, address: ContractAddress, number: felt252);
    fn get_total_names(self: @TContractState) -> felt252;
}


#[starknet::contract]
mod NameRegistry {
    use starknet::ContractAddress;
    use starknet::get_caller_address;

    

    #[storage]
    struct Storage {
        names: LegacyMap::<ContractAddress, felt252>,
        total_names: u128, // keep track of the total number of name registrations stored in the contract
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
        address: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: Person) {
        self.names.write(owner.address, owner.name);
        self.total_names.write(1);
        self.owner.write(owner);
        self.favorite_numbers.write(owner.address, 0)
        
        // add registration_type initialization 
    }

    #[abi(embed_v0)] // when cairo 2.4.0, update to abi
    impl NameRegistry of super::INameRegistry<ContractState> {
        fn store_name(ref self: ContractState, name: felt252) {
            let caller = get_caller_address();
            self._store_name(caller, name);
        }

        fn get_name(self: @ContractState, address: ContractAddress) -> felt252 {
            let name = self.names.read(address);
            name
        }   
        fn get_owner(self: @ContractState) -> Person {
            let owner = self.owner.read();
            owner
        }
        fn set_favorite_number(ref self: ContractState, address: ContractAddress, number: felt252) {
            self.favorite_numbers.write(address, number);
        }
        fn get_total_names(self: @ContractState) -> felt252 {
            self.total_names.read()
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _store_name( // invoked whenever we identify a new registration, which comes with a user address and a name
            ref self: ContractState,
            user: ContractAddress,
            name: felt252,

        ) {
            let mut total_names = self.total_names.read(); // read from total names
            self.names.write(user, name); // store the 'name' in the contract's map 'names', associating it with the 'user's address
            self.total_names.write(total_names + 1); // increment with each additional registration, update the total names count in the contract storage
            self.emit(StoredName { user, name }); // log the action with an event

        }
        
    }

    // outside of impl block, aka private/internal, hence no need for external, not accessing contract state
    fn get_contract_name() -> felt252 { // fn doesn't interact with the state, users don't need to retrieve this
        'Name Registry'
    }

    fn get_owner_storage_address(self: @ContractState) -> starknet::StorageBaseAddress {
        self.owner.address() // return the key in the contract's storage where info about the Person struct is stored
    }
}