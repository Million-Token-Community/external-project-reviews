# MillionFarm Contract Analysis Report
This report serves the purpose of document Slither analysis output of the Million Farm project. Analysis was
done when it was initially presented. This analysis was done by the Million Farm team as well, using the same tool
(Slither), and the same issues were found. The Million Farm team took it upon themselves to address several issues found
within the analysis. Much of what the Million Farm team didn't address was related to coding conventions and formatting.
For more information about each issue, see the reference links included.

The analysis output files are contained within this repository as well. This is the direct output from the Slither
static analysis tool. Other tools were attempted to be used to further identity issues however none of them yielded any
results significantly different then what Slither provided.


## Disclaimer
The information provided here does not constitute as financial advice, trading advice, or any other sort of advice.
This analysis is simply an objective comparison between a before and after report of `MillionFarm` derived from the
Slither tool. This document, this code repository, and any files or links within this code repository, are not an
edorsement or recommendation. Please conduct your own due diligence before determining whether or
not you want to participate or use any third party services or applications. Furthermore, there is no waranty or
guarantee included with this repo with regards to the accuracy of this information contained within; it was directly derived from Slither.

## Issues that have been addressed
The Million Farm team analyzed their code and addressed the following issues.

### Unchecked transfer
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#unchecked-transfer

MillionFarm.safeSimbaTransfer(address,uint256) (contracts/MillionFarm.sol#190-197)
- ignores return value by simba.transfer(_to,simbaBal) (contracts/MillionFarm.sol#193)

MillionFarm.safeSimbaTransfer(address,uint256) (contracts/MillionFarm.sol#190-197)
- ignores return value by simba.transfer(_to,_amount) (contracts/MillionFarm.sol#195)

---

### Divide before multiply
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#divide-before-multiply

MillionFarm.simbaRewards(uint256,address) (contracts/MillionFarm.sol#153-164)
- performs a multiplication on the result of a division:
  - simbaReward = multiplier.mul(simbaPerSecond).mul(pool.allocPoint).div(totalAllocPoint) (contracts/MillionFarm.sol#160)
  - accSimbaPerShare = accSimbaPerShare.add(simbaReward.mul(1e12).div(stakeSupply)) (contracts/MillionFarm.sol#161)

MillionFarm.updatePool(uint256) (contracts/MillionFarm.sol#173-188)
- performs a multiplication on the result of a division:
  - simbaReward = multiplier.mul(simbaPerSecond).mul(pool.allocPoint).div(totalAllocPoint) (contracts/MillionFarm.sol#184)
  - pool.accSimbaPerShare = pool.accSimbaPerShare.add(simbaReward.mul(1e12).div(stakeSupply)) (contracts/MillionFarm.sol#186)

---

### Reentrancy vulnerabilities-1
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1

Reentrancy in MillionFarm.deposit(uint256,uint256) (contracts/MillionFarm.sol#88-112):
- External calls:
  - safeSimbaTransfer(msg.sender,pending) (contracts/MillionFarm.sol#95)
    - simba.transfer(_to,simbaBal) (contracts/MillionFarm.sol#193)
    - simba.transfer(_to,_amount) (contracts/MillionFarm.sol#195)
  - pool.stake.safeTransferFrom(address(msg.sender),address(this),_amount) (contracts/MillionFarm.sol#99)
  - pool.stake.safeTransfer(simbaTreasury,depositFee) (contracts/MillionFarm.sol#102)
- State variables written after the call(s):
  - pool.totalStaked = pool.totalStaked.add(_amount).sub(depositFee) (contracts/MillionFarm.sol#104)
  - user.amount = user.amount.add(_amount).sub(depositFee) (contracts/MillionFarm.sol#103)
  - user.rewardDebt = user.amount.mul(pool.accSimbaPerShare).div(1e12) (contracts/MillionFarm.sol#110)

&nbsp;

Reentrancy in MillionFarm.deposit(uint256,uint256) (contracts/MillionFarm.sol#88-112):
- External calls:
  - safeSimbaTransfer(msg.sender,pending) (contracts/MillionFarm.sol#95)
    - simba.transfer(_to,simbaBal) (contracts/MillionFarm.sol#193)
    - simba.transfer(_to,_amount) (contracts/MillionFarm.sol#195)
  - pool.stake.safeTransferFrom(address(msg.sender),address(this),_amount) (contracts/MillionFarm.sol#99)
- State variables written after the call(s):
  - pool.totalStaked = pool.totalStaked.add(_amount) (contracts/MillionFarm.sol#107)
  - user.amount = user.amount.add(_amount) (contracts/MillionFarm.sol#106)

&nbsp;

Reentrancy in MillionFarm.emergencyWithdraw(uint256) (contracts/MillionFarm.sol#133-142):
- External calls:
  - pool.stake.safeTransfer(address(msg.sender),amount) (contracts/MillionFarm.sol#139)
- State variables written after the call(s):
  - pool.totalStaked = pool.totalStaked.sub(amount) (contracts/MillionFarm.sol#140)

&nbsp;

Reentrancy in MillionFarm.withdraw(uint256,uint256) (contracts/MillionFarm.sol#114-130):
- External calls:
  - safeSimbaTransfer(msg.sender,pending) (contracts/MillionFarm.sol#121)
    - simba.transfer(_to,simbaBal) (contracts/MillionFarm.sol#193)
    - simba.transfer(_to,_amount) (contracts/MillionFarm.sol#195)
- State variables written after the call(s):
  - user.amount = user.amount.sub(_amount) (contracts/MillionFarm.sol#124)&nbsp;

&nbsp;

Reentrancy in MillionFarm.withdraw(uint256,uint256) (contracts/MillionFarm.sol#114-130):
- External calls:
  - safeSimbaTransfer(msg.sender,pending) (contracts/MillionFarm.sol#121)
    - simba.transfer(_to,simbaBal) (contracts/MillionFarm.sol#193)
    - simba.transfer(_to,_amount) (contracts/MillionFarm.sol#195)
  - pool.stake.safeTransfer(address(msg.sender),_amount) (contracts/MillionFarm.sol#125)
- State variables written after the call(s):
  - pool.totalStaked = pool.totalStaked.sub(_amount) (contracts/MillionFarm.sol#126)
  - user.rewardDebt = user.amount.mul(pool.accSimbaPerShare).div(1e12) (contracts/MillionFarm.sol#128)

---

### Reentrancy vulnerabilities-3
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3

Reentrancy in MillionFarm.deposit(uint256,uint256) (contracts/MillionFarm.sol#88-112):
- External calls:
	- safeSimbaTransfer(msg.sender,pending) (contracts/MillionFarm.sol#95)
		- simba.transfer(_to,simbaBal) (contracts/MillionFarm.sol#193)
		- simba.transfer(_to,_amount) (contracts/MillionFarm.sol#195)
	- pool.stake.safeTransferFrom(address(msg.sender),address(this),_amount) (contracts/MillionFarm.sol#99)
	- pool.stake.safeTransfer(simbaTreasury,depositFee) (contracts/MillionFarm.sol#102)
- Event emitted after the call(s):
	 - Deposit(msg.sender,_pid,_amount) (contracts/MillionFarm.sol#111)

&nbsp;

Reentrancy in MillionFarm.emergencyWithdraw(uint256) (contracts/MillionFarm.sol#133-142):
- External calls:
	- pool.stake.safeTransfer(address(msg.sender),amount) (contracts/MillionFarm.sol#139)
- Event emitted after the call(s):
	- EmergencyWithdraw(msg.sender,_pid,amount) (contracts/MillionFarm.sol#141)

&nbsp;

Reentrancy in MillionFarm.withdraw(uint256,uint256) (contracts/MillionFarm.sol#114-130):
- External calls:
	- safeSimbaTransfer(msg.sender,pending) (contracts/MillionFarm.sol#121)
		- simba.transfer(_to,simbaBal) (contracts/MillionFarm.sol#193)
		- simba.transfer(_to,_amount) (contracts/MillionFarm.sol#195)
	- pool.stake.safeTransfer(address(msg.sender),_amount) (contracts/MillionFarm.sol#125)
- Event emitted after the call(s):
	- Withdraw(msg.sender,_pid,_amount) (contracts/MillionFarm.sol#129)

&nbsp;
&nbsp;
&nbsp;
&nbsp;


------
------

## Issues presented upon final analysis

### Compiler messages
```
Warning: Visibility for constructor is ignored. If you want the contract to be non-deployable, making it "abstract" is sufficient.
  --> contracts/MillionFarm.sol:49:5:
   |
49 |     constructor(
   |     ^ (Relevant source part starts here and spans across multiple lines).
```

### Missing events arithmetic
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#missing-events-arithmetic

MillionFarm.add(uint256,IERC20,uint16,bool) (contracts/MillionFarm.sol#61-76) should emit an event for:
- totalAllocPoint = totalAllocPoint.add(_allocPoint) (contracts/MillionFarm.sol#67)

MillionFarm.set(uint256,uint256,uint16,bool) (contracts/MillionFarm.sol#78-86) should emit an event for:
- totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint) (contracts/MillionFarm.sol#83)

---

## Missing zero address validation
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation

MillionFarm.constructor(IERC20,address,uint256,uint256)._simbaTreasury (contracts/MillionFarm.sol#51) lacks a zero-check on :
- simbaTreasury = _simbaTreasury (contracts/MillionFarm.sol#55)

---

## Block timestamp
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#block-timestamp

MillionFarm.add(uint256,IERC20,uint16,bool) (contracts/MillionFarm.sol#61-76) uses timestamp for comparisons
- Dangerous comparisons:
  - block.timestamp > startTime (contracts/MillionFarm.sol#66)

MillionFarm.updateRewardPerSecond() (contracts/MillionFarm.sol#144-151) uses timestamp for comparisons
- Dangerous comparisons:
  - require(bool,string)(block.timestamp > emissionCheckpoint,you cannot halve emissions yet) (contracts/MillionFarm.sol#145)

MillionFarm.simbaRewards(uint256,address) (contracts/MillionFarm.sol#153-164) uses timestamp for comparisons
- Dangerous comparisons:
  - block.timestamp > pool.lastTimeStamp && stakeSupply != 0 (contracts/MillionFarm.sol#158)

MillionFarm.massUpdatePools() (contracts/MillionFarm.sol#166-171) uses timestamp for comparisons
- Dangerous comparisons:
  - pid < length (contracts/MillionFarm.sol#168)

MillionFarm.updatePool(uint256) (contracts/MillionFarm.sol#173-188) uses timestamp for comparisons
- Dangerous comparisons:
  - block.timestamp <= pool.lastTimeStamp (contracts/MillionFarm.sol#175)


---

## Assembly usage
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#assembly-usage

Address.isContract(address) (@openzeppelin/contracts/utils/Address.sol#26-36) uses assembly
	- INLINE ASM (@openzeppelin/contracts/utils/Address.sol#32-34)

Address.verifyCallResult(bool,bytes,string) (@openzeppelin/contracts/utils/Address.sol#195-215) uses assembly
	- INLINE ASM (@openzeppelin/contracts/utils/Address.sol#207-210)

---

## Different pragma directives are used
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#different-pragma-directives-are-used

- Version used: ['0.8.0', '^0.8.0']
	- 0.8.0 (contracts/MillionFarm.sol#3)
	- ^0.8.0 (@openzeppelin/contracts/access/Ownable.sol#3)
	- ^0.8.0 (@openzeppelin/contracts/token/ERC20/IERC20.sol#3)
	- ^0.8.0 (@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#3)
	- ^0.8.0 (@openzeppelin/contracts/utils/Address.sol#3)
	- ^0.8.0 (@openzeppelin/contracts/utils/Context.sol#3)
	- ^0.8.0 (@openzeppelin/contracts/utils/math/SafeMath.sol#3)

---

## Dead code
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code

Address.functionCall(address,bytes) (@openzeppelin/contracts/utils/Address.sol#79-81)
- is never used and should be removed

Address.functionCallWithValue(address,bytes,uint256) (@openzeppelin/contracts/utils/Address.sol#108-114)
- is never used and should be removed

Address.functionDelegateCall(address,bytes) (@openzeppelin/contracts/utils/Address.sol#168-170)
- is never used and should be removed

Address.functionDelegateCall(address,bytes,string) (@openzeppelin/contracts/utils/Address.sol#178-187)
- is never used and should be removed

Address.functionStaticCall(address,bytes) (@openzeppelin/contracts/utils/Address.sol#141-143)
- is never used and should be removed

Address.functionStaticCall(address,bytes,string) (@openzeppelin/contracts/utils/Address.sol#151-160)
- is never used and should be removed

Address.sendValue(address,uint256) (@openzeppelin/contracts/utils/Address.sol#54-59)
- is never used and should be removed

Context._msgData() (@openzeppelin/contracts/utils/Context.sol#20-22)
- is never used and should be removed

SafeERC20.safeApprove(IERC20,address,uint256) (@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#44-57)
- is never used and should be removed

SafeERC20.safeDecreaseAllowance(IERC20,address,uint256) (@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#68-79)
- is never used and should be removed

SafeERC20.safeIncreaseAllowance(IERC20,address,uint256) (@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#59-66)
- is never used and should be removed

SafeMath.div(uint256,uint256,string) (@openzeppelin/contracts/utils/math/SafeMath.sol#190-199)
- is never used and should be removed

SafeMath.mod(uint256,uint256) (@openzeppelin/contracts/utils/math/SafeMath.sol#150-152)
- is never used and should be removed

SafeMath.mod(uint256,uint256,string) (@openzeppelin/contracts/utils/math/SafeMath.sol#216-225)
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

## Incorrect versions of solidity
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity

solc-0.8.0 is not recommended for deployment
  - Consider deploying with 0.6.12/0.7.6

Pragma version^0.8.0 (@openzeppelin/contracts/access/Ownable.sol#3)
- necessitates a version too recent to be trusted.

Pragma version^0.8.0 (@openzeppelin/contracts/token/ERC20/IERC20.sol#3)
- necessitates a version too recent to be trusted.

Pragma version^0.8.0 (@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#3)
- necessitates a version too recent to be trusted.

Pragma version^0.8.0 (@openzeppelin/contracts/utils/Address.sol#3)
- necessitates a version too recent to be trusted.

Pragma version^0.8.0 (@openzeppelin/contracts/utils/Context.sol#3)
- necessitates a version too recent to be trusted.

Pragma version^0.8.0 (@openzeppelin/contracts/utils/math/SafeMath.sol#3)
- necessitates a version too recent to be trusted.

Pragma version0.8.0 (contracts/MillionFarm.sol#3)
- necessitates a version too recent to be trusted.


---

## Low level calls
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

## Conformance to solidity naming conventions
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#conformance-to-solidity-naming-conventions


Parameter MillionFarm.add(uint256,IERC20,uint16,bool)._allocPoint (contracts/MillionFarm.sol#61)
- is not in mixedCase

Parameter MillionFarm.add(uint256,IERC20,uint16,bool)._stake (contracts/MillionFarm.sol#61)
- is not in mixedCase

Parameter MillionFarm.add(uint256,IERC20,uint16,bool)._depositFeeBP (contracts/MillionFarm.sol#61)
- is not in mixedCase

Parameter MillionFarm.add(uint256,IERC20,uint16,bool)._withUpdate (contracts/MillionFarm.sol#61)
- is not in mixedCase

Parameter MillionFarm.set(uint256,uint256,uint16,bool)._pid (contracts/MillionFarm.sol#78)
- is not in mixedCase

Parameter MillionFarm.set(uint256,uint256,uint16,bool)._allocPoint (contracts/MillionFarm.sol#78)
- is not in mixedCase

Parameter MillionFarm.set(uint256,uint256,uint16,bool)._depositFeeBP (contracts/MillionFarm.sol#78)
- is not in mixedCase

Parameter MillionFarm.set(uint256,uint256,uint16,bool)._withUpdate (contracts/MillionFarm.sol#78)
- is not in mixedCase

Parameter MillionFarm.deposit(uint256,uint256)._pid (contracts/MillionFarm.sol#88)
- is not in mixedCase

Parameter MillionFarm.deposit(uint256,uint256)._amount (contracts/MillionFarm.sol#88)
- is not in mixedCase

Parameter MillionFarm.withdraw(uint256,uint256)._pid (contracts/MillionFarm.sol#114)
- is not in mixedCase

Parameter MillionFarm.withdraw(uint256,uint256)._amount (contracts/MillionFarm.sol#114)
- is not in mixedCase

Parameter MillionFarm.emergencyWithdraw(uint256)._pid (contracts/MillionFarm.sol#133)
- is not in mixedCase

Parameter MillionFarm.simbaRewards(uint256,address)._pid (contracts/MillionFarm.sol#153)
- is not in mixedCase

Parameter MillionFarm.simbaRewards(uint256,address)._user (contracts/MillionFarm.sol#153)
- is not in mixedCase

Parameter MillionFarm.updatePool(uint256)._pid (contracts/MillionFarm.sol#173)
- is not in mixedCase

Parameter MillionFarm.safeSimbaTransfer(address,uint256)._to (contracts/MillionFarm.sol#190)
- is not in mixedCase

Parameter MillionFarm.safeSimbaTransfer(address,uint256)._amount (contracts/MillionFarm.sol#190)
- is not in mixedCase

Parameter MillionFarm.getMultiplier(uint256,uint256)._from (contracts/MillionFarm.sol#199)
- is not in mixedCase

Parameter MillionFarm.getMultiplier(uint256,uint256)._to (contracts/MillionFarm.sol#199)
- is not in mixedCase

---

## State variables that could be declared constant
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#state-variables-that-could-be-declared-constant

MillionFarm.halvingTime (contracts/MillionFarm.sol#38)
- should be constant

---

## Public function that could be declared external
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#public-function-that-could-be-declared-external

renounceOwnership() should be declared external:
- Ownable.renounceOwnership() (@openzeppelin/contracts/access/Ownable.sol#53-55)

transferOwnership(address) should be declared external:
- Ownable.transferOwnership(address) (@openzeppelin/contracts/access/Ownable.sol#61-64)
