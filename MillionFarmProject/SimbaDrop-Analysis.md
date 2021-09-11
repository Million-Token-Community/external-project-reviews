# SimbaDrop Contract Analysis Report
This report serves the purpose of document Slither analysis output of the Million Farm project. Analysis was
done when it was initially presented. This analysis was done by the Million Farm team as well, using the same tool
(Slither), and the same issues were found. The Million Farm team took it upon themselves to address several issues found
within the analysis of other conracts, however this contract has not been changed. Much of what the Million Farm team
didn't address was related to coding conventions and formatting however, there was still one reentrancy issue not addressed
related to claiming air drops. See the Reentrancy section below and reference links to learn more. Each issue is
presented with reference links to learn more.

The analysis output files are contained within this repository as well. This is the direct output from the Slither
static analysis tool. Other tools were attempted to be used to further identity issues however none of them yielded any
results significantly different then what Slither provided.


## Disclaimer
The information provided here does not constitute as financial advice, trading advice, or any other sort of advice.
This analysis is simply an objective comparison between a before and after report of `SimbaDrop` derived from the
Slither tool. This document, this code repository, and any files or links within this code repository, are not an
edorsement or recommendation. Please conduct your own due diligence before determining whether or
not you want to participate or use any third party services or applications. Furthermore, there is no waranty or
guarantee included with this repo with regards to the accuracy of this information contained within; it was directly derived from Slither.


## Issues presented upon final analysis
These issues were present in the first report as well as the second. It seems the Million Farm decided no changes were
necessary.


### Compilation messages
```
Warning: Visibility for constructor is ignored. If you want the contract to be non-deployable, making it "abstract" is sufficient.
  --> contracts/SimbaDrop.sol:20:3:
   |
20 |   constructor(address _address) public {
   |   ^ (Relevant source part starts here and spans across multiple lines).
```
---

## Unchecked transfer
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#unchecked-transfer

SimbaDrop.claimAirDrop() (contracts/SimbaDrop.sol#33-40)
  - ignores return value by simba.transfer(msg.sender,amount) (contracts/SimbaDrop.sol#36)

---

### Reentrancy
Reference: https://github.com/craytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1

SimbaDrop.claimAirDrop() (contracts/SimbaDrop.sol#33-40):
- External calls:
  - simba.transfer(msg.sender,amount) (contracts/SimbaDrop.sol#36)
  - State variables written after the call(s):
    - claimed[msg.sender] = 0 (contracts/SimbaDrop.sol#37)

 ---

### Missing events arithmetic
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#missing-events-arithmetic

SimbaDrop.setAirDrop(address[]) (contracts/SimbaDrop.sol#24-31) should emit an event for:
- count = _address.length (contracts/SimbaDrop.sol#25)
- amount = simba.balanceOf(address(this)).div(count) (contracts/SimbaDrop.sol#26)

---

### Calls inside a loop
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation/#calls-inside-a-loop

SimbaDrop.claimAirDrop() (contracts/SimbaDrop.sol#33-40) has external calls inside a loop:
- simba.transfer(msg.sender,amount) (contracts/SimbaDrop.sol#36)

---

### Inline assembly
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#assembly-usage

Address.isContract(address) (@openzeppelin/contracts/utils/Address.sol#26-36) uses assembly
- INLINE ASM (@openzeppelin/contracts/utils/Address.sol#32-34)

Address.verifyCallResult(bool,bytes,string) (@openzeppelin/contracts/utils/Address.sol#195-215) uses assembly
- INLINE ASM (@openzeppelin/contracts/utils/Address.sol#207-210)

---

### Different versions of solidity used
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#different-pragma-directives-are-used

- Version used: ['0.8.0', '^0.8.0']
- 0.8.0 (contracts/SimbaDrop.sol#2)
- ^0.8.0 (@openzeppelin/contracts/access/Ownable.sol#3)
- ^0.8.0 (@openzeppelin/contracts/token/ERC20/IERC20.sol#3)
- ^0.8.0 (@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#3)
- ^0.8.0 (@openzeppelin/contracts/utils/Address.sol#3)
- ^0.8.0 (@openzeppelin/contracts/utils/Context.sol#3)
- ^0.8.0 (@openzeppelin/contracts/utils/math/SafeMath.sol#3)

---

### Dead code
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code

Address.functionCall(address,bytes) (@openzeppelin/contracts/utils/Address.sol#79-81)
- is never used and should be removed

Address.functionCall(address,bytes,string) (@openzeppelin/contracts/utils/Address.sol#89-95)
- is never used and should be removed

Address.functionCallWithValue(address,bytes,uint256) (@openzeppelin/contracts/utils/Address.sol#108-114)
- is never used and should be removed

Address.functionCallWithValue(address,bytes,uint256,string) (@openzeppelin/contracts/utils/Address.sol#122-133)
- is never used and should be removed

Address.functionDelegateCall(address,bytes) (@openzeppelin/contracts/utils/Address.sol#168-170)
- is never used and should be removed

Address.functionDelegateCall(address,bytes,string) (@openzeppelin/contracts/utils/Address.sol#178-187)
- is never used and should be removed

Address.functionStaticCall(address,bytes) (@openzeppelin/contracts/utils/Address.sol#141-143)
- is never used and should be removed

Address.functionStaticCall(address,bytes,string) (@openzeppelin/contracts/utils/Address.sol#151-160)
- is never used and should be removed

Address.isContract(address) (@openzeppelin/contracts/utils/Address.sol#26-36)
- is never used and should be removed

Address.sendValue(address,uint256) (@openzeppelin/contracts/utils/Address.sol#54-59)
- is never used and should be removed

Address.verifyCallResult(bool,bytes,string) (@openzeppelin/contracts/utils/Address.sol#195-215)
- is never used and should be removed

Context._msgData() (@openzeppelin/contracts/utils/Context.sol#20-22)
- is never used and should be removed

SafeERC20._callOptionalReturn(IERC20,bytes) (@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#87-97)
- is never used and should be removed

SafeERC20.safeApprove(IERC20,address,uint256) (@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#44-57)
- is never used and should be removed

feERC20.safeDecreaseAllowance(IERC20,address,uint256) (@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#68-79)
- is never used and should - be removed

feERC20.safeIncreaseAllowance(IERC20,address,uint256) (@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#59-66)
- is never used and should - be removed

SafeERC20.safeTransfer(IERC20,address,uint256) (@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#20-26)
- is never used and should be removed

SafeERC20.safeTransferFrom(IERC20,address,address,uint256) (@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#28-35) is never used and - should be removed

SafeMath.add(uint256,uint256) (@openzeppelin/contracts/utils/math/SafeMath.sol#92-94)
- is never used and should be removed

SafeMath.div(uint256,uint256,string) (@openzeppelin/contracts/utils/math/SafeMath.sol#190-199)
- is never used and should be removed

SafeMath.mod(uint256,uint256) (@openzeppelin/contracts/utils/math/SafeMath.sol#150-152)
- is never used and should be removed

SafeMath.mod(uint256,uint256,string) (@openzeppelin/contracts/utils/math/SafeMath.sol#216-225)
- is never used and should be removed

SafeMath.mul(uint256,uint256) (@openzeppelin/contracts/utils/math/SafeMath.sol#120-122)
- is never used and should be removed

SafeMath.sub(uint256,uint256) (@openzeppelin/contracts/utils/math/SafeMath.sol#106-108)
- is never used and should be removed

SafeMath.sub(uint256,uint256,string) (@openzeppelin/contracts/utils/math/SafeMath.sol#167-176)
- is never used and should be removed

SafeMath.tryAdd(uint256,uint256) (@openzeppelin/contracts/utils/math/SafeMath.sol#21-27)
- is never used and should be removed

SafeMath.tryDiv(uint256,uint256) (@openzeppelin/contracts/utils/math/SafeMath.sol#63-68)
- is never used and should be removed

SafeMath.tryMod(uint256,uint256) (@openzeppelin/contracts/utils/math/SafeMath.sol#75-80)
- is never used and should be removed

SafeMath.tryMul(uint256,uint256) (@openzeppelin/contracts/utils/math/SafeMath.sol#46-56)
- is never used and should be removed

SafeMath.trySub(uint256,uint256) (@openzeppelin/contracts/utils/math/SafeMath.sol#34-39)
- is never used and should be removed


---

### Incorrect version of solidity
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity

solc-0.8.0 is not recommended for deployment

Pragma version^0.8.0 (@openzeppelin/contracts/access/Ownable.sol#3)
- necessitates a version too recent to be trusted. Consider deploying with 0.6.- 12/0.7.6

Pragma version^0.8.0 (@openzeppelin/contracts/token/ERC20/IERC20.sol#3)
- necessitates a version too recent to be trusted. Consider deploying with 0.- 6.12/0.7.6

Pragma version^0.8.0 (@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#3)
- necessitates a version too recent to be trusted. Consider - deploying with 0.6.12/0.7.6

Pragma version^0.8.0 (@openzeppelin/contracts/utils/Address.sol#3)
- necessitates a version too recent to be trusted. Consider deploying with 0.6.12/- 0.7.6

Pragma version^0.8.0 (@openzeppelin/contracts/utils/Context.sol#3)
- necessitates a version too recent to be trusted. Consider deploying with 0.6.12/- 0.7.6

Pragma version^0.8.0 (@openzeppelin/contracts/utils/math/SafeMath.sol#3)
- necessitates a version too recent to be trusted. Consider deploying with - 0.6.12/0.7.6

Pragma version0.8.0 (contracts/SimbaDrop.sol#2)
- necessitates a version too recent to be trusted. Consider deploying with 0.6.12/0.7.6


---

### Low-level callss
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#low-level-calls

Low level call in Address.sendValue(address,uint256) (@openzeppelin/contracts/utils/Address.sol#54-59):
- (success) = recipient.call{value: amount}() (@openzeppelin/contracts/utils/Address.sol#57)

Low level call in Address.functionCallWithValue(address,bytes,uint256,string) (@openzeppelin/contracts/utils/Address.sol#122-133):
- (success,returndata) = target.call{value: value}(data) (@openzeppelin/contracts/utils/Address.sol#131)

Low level call in Address.functionStaticCall(address,bytes,string) (@openzeppelin/contracts/utils/Address.sol#151-160):
- (success,returndata) = target.staticcall(data) (@openzeppelin/contracts/utils/Address.sol#158)

Low level call in Address.functionDelegateCall(address,bytes,string) (@openzeppelin/contracts/utils/Address.sol#178-187):
- (success,returndata) = target.delegatecall(data) (@openzeppelin/contracts/utils/Address.sol#185)

---

### Conformance to solidity naming conventions
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#conformance-to-solidity-naming-conventions

Parameter SimbaDrop.setAirDrop(address[])._address (contracts/SimbaDrop.sol#24) is not in mixedCase

---

### Public functions that could be declared external
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#public-function-that-could-be-declared-external

renounceOwnership() should be declared external:
- Ownable.renounceOwnership() (@openzeppelin/contracts/access/Ownable.sol#53-55)

transferOwnership(address) should be declared external:
- Ownable.transferOwnership(address) (@openzeppelin/contracts/access/Ownable.sol#61-64)
