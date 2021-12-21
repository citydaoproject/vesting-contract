# CityDAO Vesting Contract

This smart contract is designed to award contributors with a fixed amount of tokens, over a set period of time. This works like equity vesting in a startup, incentivizing continued participation. A contributor can claim tokens at any time, and will recieve tokens based on how long their last claim was, and how many months are left on their contract.

For instance, Alice sets up a contract to pay Bob 10 tokens every month, for 6 months through this smart-contract. Bob can claim 10 tokens after 1 month of the contract being initiated. Bob can then wait another 3 months (for a total of 4), and receive another 30 tokens (total 40 in his account). After another 2 months (total of 6), Bob can recieve the rest of the tokens (20), for a total of 60 tokens over time. After those 6 months, Bob will not revieve any more tokens.

# Setting up the project

make sure you have [nix](https://nixos.org/) installed!

(this project uses [dapptools](https://dapp.tools/) as a framework. this is automatically installed via nix.)

1. install nix
2. make sure you clone submodules! (git submodule update --init)
3. open a nix-shell (via 'nix-shell' from the project directory)
4. run 'dapp test' to build+run the test suite

# Deploy the project

TBD
