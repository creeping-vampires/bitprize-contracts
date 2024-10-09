<img align="right" width="150" height="150" top="100" src="./public/readme.png">

# BrokenToken ![license](https://img.shields.io/github/license/zeroknots/brokentoken?label=license) ![solidity](https://img.shields.io/badge/solidity-^0.8.0-lightgrey)

The BrokenToken is a tool designed to automatically test smart contracts that interact with ERC20 tokens for unexpected behavior that may result in exploits. The ERC20 specification is loosely defined, and many developers violate the few semantic requirements that are imposed. This makes building smart contracts that interface directly with ERC20 tokens challenging.

The BrokenToken is based on a repository of minimal example implementations in Solidity of ERC20 tokens with behavior that may be surprising or unexpected. The tool is intended for use by developers and auditors to test smart contracts that utilize ERC20 tokens and identify potential vulnerabilities.


## Usage

```sh
forge install zeroknots/brokentoken
```

Write your *ERC20* foundry test as follows:


```solidity
pragma solidity ^0.8.13;
import "forge-std/Test.sol";

import {BrokenToken} from "brokentoken/BrokenToken.sol";


contract YourTest is Test, BrokenToken {

    function testFoobar() public useBrokenToken { // such wow. much easy.
        deal(address(brokenERC20), bob, 1_000_000);
        brokenERC20.approve(address(vault), 1_000_000);
    }
}
```

Or if you want to test weird *ERC721*


```solidity

pragma solidity ^0.8.13;
import "forge-std/Test.sol";

import {BrokenToken} from "brokentoken/BrokenToken.sol";


contract YourTest is Test, BrokenToken {

    function testFoobar() public useBrokenNFT { // such wow. much easy.
        brokenERC721.mint(alice);
        brokenERC721.transferFrom(alice, bob, tokenId);
    }
}
```



# Roadmap

- add more weird ERC20
- add weird ERC721 
- add weird ERC1155

Please open a GH issue if you want me to add specific test cases

# Testing Scope
This test suite is currently heavily utilizing [d-xo/weird-erc20](https://github.com/d-xo/weird-erc20/) and implements following test cases:


## Reentrant Calls

Some tokens allow reentrant calls on transfer (e.g. `ERC777` tokens).

This has been exploited in the wild on multiple occasions (e.g. [imBTC Uniswap pool
drained](https://defirate.com/imbtc-uniswap-hack/), [lendf.me
drained](https://defirate.com/dforce-hack/))


## Missing Return Values

Some tokens do not return a bool (e.g. `USDT`, `BNB`, `OMG`) on ERC20 methods. see
[here](https://gist.githubusercontent.com/lukas-berlin/f587086f139df93d22987049f3d8ebd2/raw/1f937dc8eb1d6018da59881cbc633e01c0286fb0/Tokens%20missing%20return%20values%20in%20transfer) for a comprehensive (if somewhat outdated) list.

Some tokens (e.g. `BNB`) may return a `bool` for some methods, but fail to do so for others.  This
resulted in stuck `BNB` tokens in Uniswap v1
([details](https://mobile.twitter.com/UniswapProtocol/status/1072286773554876416)).

Some particularly pathological tokens (e.g. Tether Gold) declare a bool return, but then return
`false` even when the transfer was successful
([code](https://etherscan.io/address/0x4922a015c4407f87432b179bb209e125432e4a2a#code)).

A good safe transfer abstraction
([example](https://github.com/Uniswap/uniswap-v2-core/blob/4dd59067c76dea4a0e8e4bfdda41877a6b16dedc/contracts/UniswapV2Pair.sol#L44))
can help somewhat, but note that the existence of Tether Gold makes it impossible to correctly handle
return values for all tokens.

Two example tokens are provided:

- `MissingReturns`: does not return a bool for any erc20 operation
- `ReturnsFalse`: declares a bool return, but then returns false for every erc20 operation


## Fee on Transfer

Some tokens take a transfer fee (e.g. `STA`, `PAXG`), some do not currently charge a fee but may do
so in the future (e.g. `USDT`, `USDC`).

The `STA` transfer fee was used to drain $500k from several balancer pools ([more
details](https://medium.com/@1inch.exchange/balancer-hack-2020-a8f7131c980e)).


## Balance Modifications Outside of Transfers (rebasing/airdrops)

Some tokens may make arbitrary balance modifications outside of transfers (e.g. Ampleforth style
rebasing tokens, Compound style airdrops of governance tokens, mintable/burnable tokens).

Some smart contract systems cache token balances (e.g. Balancer, Uniswap-V2), and arbitrary
modifications to underlying balances can mean that the contract is operating with outdated
information.

In the case of Ampleforth, some Balancer and Uniswap pools are special cased to ensure that the
pool's cached balances are atomically updated as part of the rebase procedure
([details](https://www.ampltalk.org/app/forum/technology-development-17/topic/supported-dex-pools-61/)).

*example*: TODO: implement a rebasing token

## Upgradable Tokens

Some tokens (e.g. `USDC`, `USDT`) are upgradable, allowing the token owners to make arbitrary
modifications to the logic of the token at any point in time.

A change to the token semantics can break any smart contract that depends on the past behaviour.

Developers integrating with upgradable tokens should consider introducing logic that will freeze
interactions with the token in question if an upgrade is detected. (e.g. the [`TUSD`
adapter](https://github.com/makerdao/dss-deploy/blob/7394f6555daf5747686a1b29b2f46c6b2c64b061/src/join.sol#L321)
used by MakerDAO).

## Flash Mintable Tokens

Some tokens (e.g. `DAI`) allow for so called "flash minting", which allows tokens to be minted for the duration
of one transaction only, provided they are returned to the token contract by the end of the
transaction.

This is similar to a flash loan, but does not require the tokens that are to be lent to exist before
the start of the transaction. A token that can be flash minted could potentially have a total supply
of max `uint256`.

Documentation for the MakerDAO flash mint module can be found
[here](https://docs.makerdao.com/smart-contract-modules/flash-mint-module).

## Tokens with Blocklists

Some tokens (e.g. `USDC`, `USDT`) have a contract level admin controlled address blocklist. If an
address is blocked, then transfers to and from that address are forbidden.

Malicious or compromised token owners can trap funds in a contract by adding the contract address to
the blocklist. This could potentially be the result of regulatory action against the contract
itself, against a single user of the contract (e.g. a Uniswap LP), or could also be a part of an
extortion attempt against users of the blocked contract.


## Pausable Tokens

Some tokens can be paused by an admin (e.g. `BNB`, `ZIL`).

Similary to the blocklist issue above, an admin controlled pause feature opens users
of the token to risk from a malicious or compromised token owner.


## Approval Race Protections

Some tokens (e.g. `USDT`, `KNC`) do not allow approving an amount `M > 0` when an existing amount
`N > 0` is already approved. This is to protect from an ERC20 attack vector described
[here](https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit#heading=h.b32yfk54vyg9).

[This PR](https://github.com/Uniswap/uniswap-v2-periphery/pull/26#issuecomment-647543138) shows some
in the wild problems caused by this issue.


## Revert on Approval To Zero Address

Some tokens (e.g. OpenZeppelin) will revert if trying to approve the zero address to spend tokens
(i.e. a call to `approve(address(0), amt)`).

Integrators may need to add special cases to handle this logic if working with such a token.


## Revert on Zero Value Transfers

Some tokens (e.g. `LEND`) revert when transferring a zero value amount.


## Multiple Token Addresses

Some proxied tokens have multiple addresses. 
As an example consider the following snippet. `rescueFunds` is intended to allow the contract owner
to return non pool tokens that were accidentally sent to the contract. However, it assumes a single
address per token and so would allow the owner to steal all funds in the pool.

```solidity
mapping isPoolToken(address => bool);
constructor(address tokenA, address tokenB) public {
  isPoolToken[tokenA] = true;
  isPoolToken[tokenB] = true;
}
function rescueFunds(address token, uint amount) external nonReentrant onlyOwner {
    require(!isPoolToken[token], "access denied");
    token.transfer(msg.sender, amount);
}
```


## Low Decimals

Some tokens have low decimals (e.g. `USDC` has 6). Even more extreme, some tokens like [Gemini USD](https://etherscan.io/token/0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd?a=0x5f65f7b609678448494De4C87521CdF6cEf1e932) only have 2 decimals.

This may result in larger than expected precision loss.


## High Decimals

Some tokens have more than 18 decimals (e.g. `YAM-V2` has 24).

This may trigger unexpected reverts due to overflow, posing a liveness risk to the contract.


## `transferFrom` with `src == msg.sender`

Some token implementations (e.g. `DSToken`) will not attempt to decrease the caller's allowance if
the sender is the same as the caller. This gives `transferFrom` the same semantics as `transfer` in
this case. Other implementations (e.g. OpenZeppelin, Uniswap-v2) will attempt to decrease the
caller's allowance from the sender in `transferFrom` even if the caller and the sender are the same
address, giving `transfer(dst, amt)` and `transferFrom(address(this), dst, amt)` a different
semantics in this case.


## Non `string` metadata

Some tokens (e.g.
[`MKR`](https://etherscan.io/address/0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2#code)) have metadata
fields (`name` / `symbol`) encoded as `bytes32` instead of the `string` prescribed by the ERC20
specification.

This may cause issues when trying to consume metadata from these tokens.


## Revert on Transfer to the Zero Address

Some tokens (e.g. openzeppelin) revert when attempting to transfer to `address(0)`.

This may break systems that expect to be able to burn tokens by transferring them to `address(0)`.

## No Revert on Failure

Some tokens do not revert on failure, but instead return `false` (e.g.
[ZRX](https://etherscan.io/address/0xe41d2489571d322189246dafa5ebde1f4699f498#code)).

While this is technically compliant with the ERC20 standard, it goes against common solidity coding
practices and may be overlooked by developers who forget to wrap their calls to `transfer` in a
`require`.


## Revert on Large Approvals & Transfers

Some tokens (e.g. `UNI`, `COMP`) revert if the value passed to `approve` or `transfer` is larger than `uint96`.

Both of the above tokens have special case logic in `approve` that sets `allowance` to `type(uint96).max`
if the approval amount is `uint256(-1)`, which may cause issues with systems that expect the value
passed to `approve` to be reflected in the `allowances` mapping.


## Code Injection Via Token Name

Some malicious tokens have been observed to include malicious javascript in their `name` attribute,
allowing attackers to extract private keys from users who choose to interact with these tokens via
vulnerable frontends.

This has been used to exploit etherdelta users in the wild ([reference](https://hackernoon.com/how-one-hacker-stole-thousands-of-dollars-worth-of-cryptocurrency-with-a-classic-code-injection-a3aba5d2bff0)).

## Unusual Permit Function

Some tokens ([DAI, RAI, GLM, STAKE, CHAI, HAKKA, USDFL, HNY](https://github.com/yashnaman/tokensWithPermitFunctionList/blob/master/hasDAILikePermitFunctionTokenList.json)) have a `permit()` implementation that does not follow [EIP2612](https://eips.ethereum.org/EIPS/eip-2612). Tokens that do not support permit may not revert, which [could lead to the execution of later lines of code in unexpected scenarios](https://media.dedaub.com/phantom-functions-and-the-billion-dollar-no-op-c56f062ae49f). [Uniswap's Permit2](https://github.com/Uniswap/permit2) may provide a more compatible alternative.

