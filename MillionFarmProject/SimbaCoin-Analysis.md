# SimbaCoin Contract Analysis Report
This report serves the purpose of document Slither analysis output of the Million Farm project. Analysis was
done when it was initially presented. This analysis was done by the Million Farm team as well, using the same tool
(Slither), and the same issues were found. The Million Farm team took it upon themselves to address several issues found
within the analysis of other conracts, however this contract has not been changed. Much of what the Million Farm team
didn't address was related to coding conventions and formatting. See reference links for each given issue to learn more.

The analysis output files are contained within this repository as well. This is the direct output from the Slither
static analysis tool. Other tools were attempted to be used to further identity issues however none of them yielded any
results significantly different then what Slither provided.


## Disclaimer
The information provided here does not constitute as financial advice, trading advice, or any other sort of advice.
This analysis is simply an objective comparison between a before and after report of `SimbaCoin` derived from the
Slither tool. This document, this code repository, and any files or links within this code repository, are not an
edorsement or recommendation. Please conduct your own due diligence before determining whether or
not you want to participate or use any third party services or applications. Furthermore, there is no waranty or
guarantee included with this repo with regards to the accuracy of this information contained within; it was directly derived from Slither.


## Issues presented upon final analysis
These issues were present in the first report as well as the second. It seems the Million Farm decided no changes were
necessary.

### Different pragma directives are used
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#different-pragma-directives-are-used
- Version used: ['0.8.0', '^0.8.0']
	- 0.8.0 (contracts/SimbaCoin.sol#2)
	- ^0.8.0 (@openzeppelin/contracts/access/Ownable.sol#3)
	- ^0.8.0 (@openzeppelin/contracts/token/ERC20/ERC20.sol#3)
	- ^0.8.0 (@openzeppelin/contracts/token/ERC20/IERC20.sol#3)
	- ^0.8.0 (@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#3)
	- ^0.8.0 (@openzeppelin/contracts/utils/Context.sol#3)


### Dead code
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code

Context._msgData() (@openzeppelin/contracts/utils/Context.sol#20-22)
- is never used and should be removed

ERC20._burn(address,uint256) (@openzeppelin/contracts/token/ERC20/ERC20.sol#274-289)
- is never used and should be removed

### Incorrect versions of solidity
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity

solc-0.8.0 is not recommended for deployment

Pragma version0.8.0 (contracts/SimbaCoin.sol#2)
- necessitates a version too recent to be trusted. Consider deploying with 0.6.12/0.7.6

Pragma version^0.8.0 (@openzeppelin/contracts/access/Ownable.sol#3)
- necessitates a version too recent to be trusted. Consider deploying with 0.6.12/0.7.6

Pragma version^0.8.0 (@openzeppelin/contracts/token/ERC20/ERC20.sol#3)
- necessitates a version too recent to be trusted. Consider deploying with 0.6.12/0.7.6

Pragma version^0.8.0 (@openzeppelin/contracts/token/ERC20/IERC20.sol#3)
- necessitates a version too recent to be trusted. Consider deploying with 0.6.12/0.7.6

Pragma version^0.8.0 (@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#3)
- necessitates a version too recent to be trusted. Consider deploying with 0.6.12/0.7.6

Pragma version^0.8.0 (@openzeppelin/contracts/utils/Context.sol#3)
- necessitates a version too recent to be trusted. Consider deploying with 0.6.12/0.7.6


### Conformance to solidity naming conventions
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#conformance-to-solidity-naming-conventions

Parameter SimbaCoin.mint(address,uint256)._to (contracts/SimbaCoin.sol#15)
- is not in mixedCase

Parameter SimbaCoin.mint(address,uint256)._amount (contracts/SimbaCoin.sol#15)
- is not in mixedCase

Constant SimbaCoin.maxTotalSupply (contracts/SimbaCoin.sol#13)
- is not in UPPER_CASE_WITH_UNDERSCORES


### Public function that could be declared external
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#public-function-that-could-be-declared-external

renounceOwnership() should be declared external:
- Ownable.renounceOwnership() (@openzeppelin/contracts/access/Ownable.sol#53-55)

transferOwnership(address) should be declared external:
- Ownable.transferOwnership(address) (@openzeppelin/contracts/access/Ownable.sol#61-64)

name() should be declared external:
- ERC20.name() (@openzeppelin/contracts/token/ERC20/ERC20.sol#61-63)

symbol() should be declared external:
- ERC20.symbol() (@openzeppelin/contracts/token/ERC20/ERC20.sol#69-71)

decimals() should be declared external:
- ERC20.decimals() (@openzeppelin/contracts/token/ERC20/ERC20.sol#86-88)

balanceOf(address) should be declared external:
- ERC20.balanceOf(address) (@openzeppelin/contracts/token/ERC20/ERC20.sol#100-102)

transfer(address,uint256) should be declared external:
- ERC20.transfer(address,uint256) (@openzeppelin/contracts/token/ERC20/ERC20.sol#112-115)

allowance(address,address) should be declared external:
- ERC20.allowance(address,address) (@openzeppelin/contracts/token/ERC20/ERC20.sol#120-122)

approve(address,uint256) should be declared external:
- ERC20.approve(address,uint256) (@openzeppelin/contracts/token/ERC20/ERC20.sol#131-134)

transferFrom(address,address,uint256) should be declared external:
- ERC20.transferFrom(address,address,uint256) (@openzeppelin/contracts/token/ERC20/ERC20.sol#149-163)

increaseAllowance(address,uint256) should be declared external:
- ERC20.increaseAllowance(address,uint256) (@openzeppelin/contracts/token/ERC20/ERC20.sol#177-180)

decreaseAllowance(address,uint256) should be declared external:
- ERC20.decreaseAllowance(address,uint256) (@openzeppelin/contracts/token/ERC20/ERC20.sol#196-204)

mint(address,uint256) should be declared external:
- SimbaCoin.mint(address,uint256) (contracts/SimbaCoin.sol#15-18)

