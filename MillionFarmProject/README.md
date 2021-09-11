# Million Farm Project Review
This directory contains an analysis of each report generated using the Slither tool during the analsysis of the Million
Farm project. Slither was ran against the three Solidity contracts presented by the Million Farm team. The Million Farm
team took it upon themselves to make several changes addressing several well known kinds of issues; reentrancy and
unchecked transfers.

To learn more about the Slither tool please visit the projects GitHub repository:
* https://github.com/crytic/slither

## Reports
The initial Slither output for each contract is saved as CONTRACT_NAME-slither-output.txt. The output of
CONTRACT_NAME-slither-post-code-changes.txt is the result of running the tool after the Million Farm team made changes
to address the reentrancy and unchecked transfer issues. Only one contract had changes; the Million Farm contract.

To run these reports yourself, please see the Slither tool for a guide.

## Disclaimer
As always, do your own research; this is not financial advice or a recommendation of any kind.

The information provided here does not constitute as financial advice, trading advice, or any other sort of advice.
This analysis is simply an objective comparison between a before and after report of `MillionFarm` derived from the
Slither tool. This document, this code repository, and any files or links within this code repository, are not an
edorsement or recommendation. Please conduct your own due diligence before determining whether or
not you want to participate or use any third party services or applications. Furthermore, there is no waranty or
guarantee included with this repo with regards to the accuracy of this information contained within; it was directly derived from Slither.


