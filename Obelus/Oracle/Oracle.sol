/**
 *Submitted for verification at Etherscan.io on 2021-07-26
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

contract Oracle {
    address ORACLE = address(0); //
    address address0 = address(0);

    struct RequestTicket {
        uint256 ID;
        address sender;
        uint256 timeRequested;
        uint256 timeWindow;
        bool finalized;
        uint256 serviceFee;
        bool subjective;
        mapping(address => mapping(address => bool)) attacks;
        mapping(address => bool) damaged;
        uint8 dataType; // string, uint, bool, address
        //commit
        mapping(address => bool) committed;
        mapping(address => bytes32) commitHash;
        //reveal
        mapping(address => bool) revealed;
        mapping(address => bool) rejected;
        mapping(address => bool) voted;
        mapping(address => string) stringVotes;
        mapping(address => int256) intVotes;
        mapping(address => bytes) bytesVotes;
        mapping(address => address) addressVotes;
        //RESULTS
        bool ticketRejected;
        uint256 numberOfOptions;
        //results
        mapping(uint256 => uint256) weightOfResults;
        mapping(uint256 => string) resolvedStrings;
        mapping(uint256 => int256) resolvedInts;
        mapping(uint256 => bytes) resolvedBytes;
        mapping(uint256 => address) resolvedAddresses;
    }

    //oracle configs
    uint256 constant ROUNDTABLE_SEATS = 0;
    uint256 constant RESPONSE_TIME_WINDOW = 1;
    uint256 constant DELEGATE_REWARDSHARE = 2;
    uint256 constant FREEZE_TIMEOUT = 3;
    uint256 constant SERVICE_FEE = 4;
    uint256 constant TX_FEE_PER = 5;
    uint256 constant CONFIGS = 6;

    uint256[] public oracleConfigurations = new uint256[](CONFIGS);
    mapping(uint256 => mapping(uint256 => uint256)) /*configID*/
        public totalVotes_forEach_configOption;
    mapping(uint256 => mapping(address => uint256)) /*configID*/
        public individualsSelectedOption;

    mapping(address => uint256) resolveWeight;
    mapping(address => uint256) weightLocked;

    mapping(uint256 => RequestTicket) requestTickets;
    uint256 requestTicketCount;
    //ROUND TABLE & Candidates
    mapping(uint256 => address) public chairsCandidate; // only looks at the first X indexes
    mapping(address => uint256) candidatesChair;
    mapping(address => uint256) timeSeated; // watchers aren't responsible for requestTickets that came in before them
    mapping(address => bool) frozen;
    mapping(address => uint256) latestPunishment;
    mapping(address => uint256) timeWhenThawedOut;
    mapping(address => bool) paused; // self pause
    mapping(address => bool) hasChair;
    uint256 chairs;
    uint256 public hotSeats;

    uint256 constant scaleFactor = 0x10000000000000000;
    //PAYROLL
    mapping(address => uint256) earnings;
    mapping(address => uint256) totalShares;
    mapping(address => mapping(address => uint256)) public shares;
    mapping(address => mapping(address => uint256)) payouts;
    mapping(address => uint256) earningsPerShare;

    //Tx Coverage fee
    uint256 earningsPerWatcher;
    uint256 public totalWatchers;
    mapping(address => uint256) watcherPayouts;

    //lazy UI data
    mapping(address => address[]) public yourBacking;
    mapping(address => mapping(address => bool)) public alreadyBacking;

    ResolveToken public resolveToken;
    address payable pineapples;
    Pyramid public pyramid =
        Pyramid(0x91683899ed812C1AC49590779cb72DA6BF7971fE);
    Greenpoint greenpoint =
        Greenpoint(0x8dB802D64f97dC6BDE4eE9e8C1aecC64d3E7c028);
    uint256 genesis;

    constructor() public {
        resolveToken = pyramid.resolveToken();
        genesis = block.timestamp;
        pineapples = msg.sender;
    }

    function addressPayable(address addr)
        public
        pure
        returns (address payable)
    {
        return address(uint160(addr));
    }

    function addShares(
        address pool,
        address account,
        uint256 amount
    ) internal {
        update(pool, account);
        totalShares[pool] += amount;
        shares[pool][account] += amount;

        if (pool == ORACLE) {
            updateWatcherTxEarnings(account, false);
            if (account != address0) totalWatchers += 1;
        }
    }

    function removeShares(
        address pool,
        address account,
        uint256 amount
    ) internal {
        update(pool, account);
        totalShares[pool] -= amount;
        shares[pool][account] -= amount;

        if (pool == ORACLE) {
            updateWatcherTxEarnings(account, true);
            if (account != address0) totalWatchers -= 1;
        }
    }

    function dividendsOf(address pool, address account)
        public
        view
        returns (uint256)
    {
        uint256 owedPerShare = earningsPerShare[pool] - payouts[pool][account];
        if (pool == ORACLE && !isWatcher(account)) return 0;
        return (shares[pool][account] * owedPerShare) / scaleFactor;
    }

    event WatcherPayroll(address watcher, uint256 paidOut);

    function update(address pool, address account) internal {
        uint256 newMoney = dividendsOf(pool, account);
        payouts[pool][account] = earningsPerShare[pool];

        if (pool == ORACLE) {
            uint256 eth4Watcher = (newMoney *
                oracleConfigurations[DELEGATE_REWARDSHARE]) / (1e20);
            earnings[account] += eth4Watcher;

            uint256 newDivs;
            if (totalShares[account] > 0) {
                newDivs =
                    ((newMoney - eth4Watcher) * scaleFactor) /
                    totalShares[account];
            } else {
                newDivs = 0;
            }

            earningsPerShare[
                account /*this is what the watcher has to distribute to its electorates*/
            ] += newDivs;
        } else {
            earnings[account] += newMoney;
        }
    }

    event TxCashout(address watcher, uint256 amount);

    function updateWatcherTxEarnings(address watcher, bool paying) internal {
        uint256 owed = earningsPerWatcher - watcherPayouts[watcher];
        watcherPayouts[watcher] = earningsPerWatcher;
        if (paying) earnings[watcher] += owed;
        emit TxCashout(watcher, owed);
    }

    mapping(address => bool) notNew;
    event StakeResolves(
        address indexed addr,
        uint256 amountStaked,
        bytes _data
    );

    function tokenFallback(
        address from,
        uint256 value,
        bytes calldata _data
    ) external {
        if (msg.sender == address(resolveToken)) {
            if (from == address(pyramid)) {
                return; // if the pyramid is sending resolve tokens back to this contract, then do nothing.
            }
            resolveWeight[from] += value;
            //update option totals
            uint256 option;
            if (notNew[from]) {
                for (uint8 config = 0; config < CONFIGS; config += 1) {
                    option = individualsSelectedOption[config][from];
                    totalVotes_forEach_configOption[config][option] += value;
                    assertOption(config, option);
                }
            } else {
                notNew[from] = true;
                for (uint8 config = 0; config < CONFIGS; config += 1) {
                    option = oracleConfigurations[config];
                    individualsSelectedOption[config][from] = option;
                    totalVotes_forEach_configOption[config][option] += value;
                    assertOption(config, option);
                }
            }

            emit StakeResolves(from, value, _data);

            address backImmediately = bytesToAddress(_data);

            if (backImmediately != address0) {
                backCandidate(from, backImmediately, value);
            }

            resolveToken.transfer(address(pyramid), value);
        } else {
            revert();
        }
    }

    event UnstakeResolves(address sender, uint256 amount);

    function unstakeResolves(uint256 amount) public {
        address sender = msg.sender;
        if (amount <= (resolveWeight[sender] - weightLocked[sender])) {
            resolveWeight[sender] -= amount;
            for (uint256 config = 0; config < CONFIGS; config += 1) {
                totalVotes_forEach_configOption[config][
                    individualsSelectedOption[config][sender]
                ] -= amount;
            }

            emit UnstakeResolves(sender, amount);
            pyramid.pullResolves(amount);

            resolveToken.transfer(sender, amount);
        } else {
            revert();
        }
    }

    event BackCandidate(address sender, address candidate, uint256 amount);

    function stakeCandidate(address candidate, uint256 amount) public {
        backCandidate(msg.sender, candidate, amount);
    }

    function backCandidate(
        address sender,
        address candidate,
        uint256 amount
    ) internal {
        require(candidate != ORACLE);
        if (
            amount <= (resolveWeight[sender] - weightLocked[sender]) &&
            !frozen[candidate] &&
            !isWatcher(candidate)
        ) {
            weightLocked[sender] += amount;
            addShares(candidate, sender, amount);

            emit BackCandidate(sender, candidate, amount);
            //LAZY U.I.
            if (!alreadyBacking[sender][candidate]) {
                yourBacking[sender].push(candidate);
                alreadyBacking[sender][candidate] = true;
            }
        } else {
            revert();
        }
    }

    event PullBacking(address sender, address candidate, uint256 amount);

    function pullBacking(address candidate, uint256 amount) public {
        address sender = msg.sender;
        if (
            amount <= shares[candidate][sender] &&
            !frozen[candidate] &&
            (!(candidatesChair[candidate] < hotSeats) || paused[candidate])
        ) {
            weightLocked[sender] -= amount;
            removeShares(candidate, sender, amount);
            emit PullBacking(sender, candidate, amount);
        } else {
            revert();
        }
    }

    function pullAllTheWay(address candidate, uint256 amount) public {
        pullBacking(candidate, amount);
        unstakeResolves(amount);
    }

    function frausted(address candidate) public view returns (bool) {
        return paused[candidate] || frozen[candidate];
    }

    event AssertCandidate(
        address candidate,
        bool successfulAssert,
        address replacedWatcher,
        uint256 newSeat
    );

    function assertCandidate() public returns (bool success) {
        address candidate = msg.sender;
        uint256 weakestChair;
        bool nullSeat;
        require(!frausted(candidate) && hotSeats > 0);
        address thisWatcher;

        for (uint256 i; i < hotSeats; i += 1) {
            thisWatcher = chairsCandidate[i];
            if (frausted(thisWatcher) || thisWatcher == address0) {
                nullSeat = true;
                weakestChair = i;
            } else if (
                totalShares[thisWatcher] <
                totalShares[chairsCandidate[weakestChair]]
            ) {
                weakestChair = i;
            }
            if (nullSeat) {
                break;
            }
        }

        if (
            (totalShares[candidate] >
                totalShares[chairsCandidate[weakestChair]] ||
                nullSeat) && !isWatcher(candidate)
        ) {
            address targetCandidate = chairsCandidate[weakestChair];

            if (targetCandidate != address0)
                removeShares(
                    ORACLE,
                    targetCandidate,
                    totalShares[targetCandidate]
                );
            addShares(ORACLE, candidate, totalShares[candidate]);
            timeSeated[candidate] = now;

            hasChair[candidate] = true;
            hasChair[targetCandidate] = false;

            chairsCandidate[weakestChair] = candidate;
            candidatesChair[candidate] = weakestChair;

            emit AssertCandidate(
                candidate,
                true,
                targetCandidate,
                weakestChair
            );
            return true;
        }
        emit AssertCandidate(candidate, false, address0, weakestChair);
        return false;
    }

    event OptionVote(
        address sender,
        uint256 config,
        uint256 option,
        uint256 weight
    );

    function optionVote(
        bool[] memory isModifying,
        uint256[] memory modifiedOptions
    ) public {
        address sender = msg.sender;
        uint256 config;
        uint256 modifiedOption;
        notNew[sender] = true;
        for (config = 0; config < CONFIGS; config += 1) {
            if (isModifying[config]) {
                modifiedOption = modifiedOptions[config];
                totalVotes_forEach_configOption[config][
                    individualsSelectedOption[config][sender]
                ] -= resolveWeight[sender];
                individualsSelectedOption[config][sender] = modifiedOption;
                totalVotes_forEach_configOption[config][
                    modifiedOption
                ] += resolveWeight[sender];
                emit OptionVote(
                    sender,
                    config,
                    modifiedOption,
                    resolveWeight[sender]
                );
                assertOption(config, modifiedOption);
            }
        }
    }

    event AssertOption(uint256 config, uint256 option);

    function assertOption(uint256 config, uint256 option) public {
        if (
            totalVotes_forEach_configOption[config][option] >
            totalVotes_forEach_configOption[config][
                oracleConfigurations[config]
            ]
        ) {
            if (config == RESPONSE_TIME_WINDOW) {
                option = option > 60 ? option : (60);
            }
            if (config == ROUNDTABLE_SEATS) {
                option = option > 5 ? option : (5);
            }
            if (config == DELEGATE_REWARDSHARE) {
                option = option > 1e20 ? 1e20 : option;
            }
            oracleConfigurations[config] = option;
            emit AssertOption(config, option);
        }
    }

    function isWatcher(address candidate) public view returns (bool) {
        return
            candidatesChair[candidate] < hotSeats &&
            hasChair[candidate] &&
            !frausted(candidate);
    }

    function getFee()
        public
        view
        returns (uint256 txCoverageFee, uint256 serviceFee)
    {
        uint256 activeWatchers;
        for (uint256 chair = 0; chair < hotSeats; chair += 1) {
            if (
                !frausted(chairsCandidate[chair]) &&
                chairsCandidate[chair] != address0
            ) {
                activeWatchers += 1;
            }
        }
        return (
            oracleConfigurations[TX_FEE_PER] * activeWatchers,
            oracleConfigurations[SERVICE_FEE]
        );
    }

    uint256 public devFunds;

    function updatePines(address addr) public {
        require(msg.sender == pineapples);
        pineapples = payable(addr);
    }

    bool acreLock;

    function updateACRE(address addr, bool lock) public {
        require(msg.sender == pineapples && !acreLock);
        greenpoint = Greenpoint(addr);
        acreLock = lock;
    }

    function devPull() public {
        require(msg.sender == pineapples);
        uint256 money = devFunds;
        devFunds = 0;
        greenpoint.payEthToAcreStakers{value: money / 2}();
        msg.sender.transfer(money - money / 2);
    }

    //------------------------------ Request Ticket Life Cycle
    event FileRequestTicket(
        address sender,
        uint256 ticketID,
        uint8 dataType,
        bool subjective,
        uint256 timeRequested,
        uint256 responseTimeWindow,
        uint256 feePaid
    );

    function fileRequestTicket(uint8 returnType, bool subjective)
        external
        payable
        returns (uint256 ticketID)
    {
        uint256 ETH = msg.value;
        (uint256 txCoverageFee, uint256 serviceFee) = getFee();

        uint256 devFee = ((block.timestamp - genesis) < 86400 * 365)
            ? (serviceFee / 20)
            : 0;

        if (ETH - devFee >= txCoverageFee + serviceFee) {
            if (returnType > 3) returnType = 3;

            ticketID = requestTicketCount;
            RequestTicket storage ticket = requestTickets[requestTicketCount];
            requestTicketCount++;

            ticket.dataType = returnType;
            ticket.timeRequested = now;
            ticket.timeWindow = oracleConfigurations[RESPONSE_TIME_WINDOW];
            ticket.ID = ticketID;
            ticket.sender = msg.sender;
            ticket.subjective = subjective;
            ticket.serviceFee = ETH - devFee - txCoverageFee;
            devFunds += devFee;
            earningsPerWatcher += txCoverageFee / totalWatchers;

            emit FileRequestTicket(
                msg.sender,
                ticketID,
                returnType,
                subjective,
                now,
                ticket.timeWindow,
                ETH
            );
        } else {
            revert();
        }
    }

    event CommitVote(address voter, uint256 ticketID, bytes32 hash);

    function commitVote(uint256[] memory tickets, bytes32[] memory voteHashes)
        external
    {
        address sender = msg.sender;
        RequestTicket storage ticket;
        for (uint256 R; R < tickets.length; R += 1) {
            ticket = requestTickets[tickets[R]];
            if (now <= ticket.timeRequested + ticket.timeWindow) {
                ticket.committed[sender] = true;
                ticket.commitHash[sender] = voteHashes[R];
                emit CommitVote(sender, tickets[R], voteHashes[R]);
            } else {
                revert(); //outside of timewindow
            }
        }
    }

    event RevealVote(
        address voter,
        uint256 ticketID,
        bool rejected,
        int256 intVote,
        bytes bytesVote,
        address addressVote
    );

    function revealVote(
        uint256[] memory tickets,
        bool[] memory rejected,
        int256[] memory intVotes,
        bytes[] memory bytesVotes,
        address[] memory addressVotes,
        string[] memory passwords
    ) external {
        address sender = msg.sender;
        RequestTicket memory ticket;
        bytes memory abiEncodePacked;
        for (uint256 R; R < tickets.length; R += 1) {
            ticket = requestTickets[tickets[R]];
            if (
                now > ticket.timeRequested + ticket.timeWindow &&
                now <= ticket.timeRequested + ticket.timeWindow * 2
            ) {
                if (ticket.dataType == 1) {
                    abiEncodePacked = abi.encodePacked(
                        rejected[R],
                        intVotes[R],
                        passwords[R]
                    );
                } else if (ticket.dataType == 2) {
                    abiEncodePacked = abi.encodePacked(
                        rejected[R],
                        bytesVotes[R],
                        passwords[R]
                    );
                } else if (ticket.dataType == 3) {
                    abiEncodePacked = abi.encodePacked(
                        rejected[R],
                        addressVotes[R],
                        passwords[R]
                    );
                }

                if (
                    compareBytes(
                        keccak256(abiEncodePacked),
                        requestTickets[tickets[R]].commitHash[sender]
                    )
                ) {
                    requestTickets[tickets[R]].revealed[sender] = true;
                    if (rejected[R]) {
                        requestTickets[tickets[R]].rejected[sender] = true;
                    } else {
                        requestTickets[tickets[R]].voted[sender] = true;
                        if (ticket.dataType == 1) {
                            requestTickets[tickets[R]].intVotes[
                                sender
                            ] = intVotes[R];
                        } else if (ticket.dataType == 2) {
                            requestTickets[tickets[R]].bytesVotes[
                                sender
                            ] = bytesVotes[R];
                        } else if (ticket.dataType == 3) {
                            requestTickets[tickets[R]].addressVotes[
                                    sender
                                ] = addressVotes[R];
                        }
                    }
                    emit RevealVote(
                        sender,
                        tickets[R],
                        rejected[R],
                        intVotes[R],
                        bytesVotes[R],
                        addressVotes[R]
                    );
                } else {
                    revert(); //not a match
                }
            } else {
                revert(); //outside of timewindow
            }
        }
    }

    event SubjectiveStance(
        address voter,
        uint256 ticketID,
        address defender,
        bool stance
    );

    function subjectiveStance(
        uint256[] memory tickets,
        address[] memory defenders,
        bool[] memory stances
    ) external {
        address sender = msg.sender;
        RequestTicket storage ticket;
        for (uint256 R; R < tickets.length; R += 1) {
            ticket = requestTickets[tickets[R]];
            if (timeSeated[sender] <= ticket.timeRequested) {
                if (
                    timeSeated[defenders[R]] <= ticket.timeRequested &&
                    now > ticket.timeRequested + ticket.timeWindow * 2 &&
                    now <= ticket.timeRequested + ticket.timeWindow * 3
                ) {
                    ticket.attacks[sender][defenders[R]] = stances[R];
                    emit SubjectiveStance(
                        sender,
                        tickets[R],
                        defenders[R],
                        stances[R]
                    );
                } else {
                    revert(); //outside timewindow
                }
            } else {
                revert(); //you just got here homie, whatcha takin' shots for?
            }
        }
    }

    function calculateDamage(uint256 ticketID)
        internal
        view
        returns (uint256 combatWeight, uint256[] memory damage)
    {
        RequestTicket storage ticket = requestTickets[ticketID];
        address offensiveWatcher;
        address defender;
        uint256 Y;
        uint256 X;
        damage = new uint256[](hotSeats);
        if (ticket.subjective) {
            for (X = 0; X < hotSeats; X += 1) {
                offensiveWatcher = chairsCandidate[X];
                if (
                    isWatcher(offensiveWatcher) &&
                    timeSeated[offensiveWatcher] <= ticket.timeRequested
                ) {
                    combatWeight += totalShares[offensiveWatcher];
                    for (Y = 0; Y < hotSeats; Y += 1) {
                        defender = chairsCandidate[Y];
                        if (
                            isWatcher(defender) &&
                            timeSeated[defender] <= ticket.timeRequested
                        ) {
                            if (ticket.attacks[offensiveWatcher][defender]) {
                                damage[Y] += totalShares[offensiveWatcher];
                            }
                        }
                    }
                }
            }
        }
    }

    event FinalizedRequest(uint256 ticketID, address[] watchers);

    function finalizeRequests(uint256[] memory tickets) external {
        for (uint256 R; R < tickets.length; R += 1) {
            finalizeRequest(tickets[R]);
        }
    }

    function finalizeRequest(uint256 ticketID) public {
        // if responsew time window is over or all delegates have voted,
        // anyone can finalize the request to trigger the event
        RequestTicket storage ticket = requestTickets[ticketID];
        if (!ticket.finalized) {
            address watcher;

            int256[] memory intOptions = new int256[](hotSeats);
            bytes[] memory bytesOptions = new bytes[](hotSeats);
            address[] memory addressOptions = new address[](hotSeats);
            uint256[] memory optionWeights = new uint256[](hotSeats);

            address[] memory watchers = new address[](hotSeats); // lazy UI data

            uint256[] memory UINTs = new uint256[](7); //0= weight of votes, 1=top Option, 2= number of options, 3=top Option, 4 =total eligible weight, 5 = combat weight, 6  = loop for saving subjectives to storage

            uint256 opt;
            uint256[] memory damage;
            (
                UINTs[5], /*combatWeight*/
                damage
            ) = calculateDamage(ticketID);
            for (uint256 chair = 0; chair < hotSeats; chair += 1) {
                watcher = chairsCandidate[chair];
                watchers[chair] = watcher;
                if (
                    damage[chair] <=
                    UINTs[5] / /*combatWeight*/
                        2
                ) {
                    if (
                        watcher != address0 &&
                        isWatcher(watcher) &&
                        timeSeated[watcher] <= ticket.timeRequested &&
                        ticket.revealed[watcher]
                    ) {
                        UINTs[4] += totalShares[watcher]; /*total Eligible Weight*/
                        if (ticket.voted[watcher]) {
                            UINTs[0] += totalShares[watcher]; /*weight of votes*/
                            //check to see if chosen option already is accounted for, if so, add weight to it.
                            for (
                                opt = 0;
                                opt < UINTs[2]; /*option count*/
                                opt += 1
                            ) {
                                if (
                                    (ticket.dataType == 1 &&
                                        intOptions[opt] ==
                                        ticket.intVotes[watcher]) ||
                                    (ticket.dataType == 2 &&
                                        compareBytes(
                                            keccak256(bytesOptions[opt]),
                                            keccak256(
                                                ticket.bytesVotes[watcher]
                                            )
                                        )) ||
                                    (ticket.dataType == 3 &&
                                        addressOptions[opt] ==
                                        ticket.addressVotes[watcher])
                                ) {
                                    optionWeights[opt] += totalShares[watcher];
                                    if (
                                        optionWeights[opt] >
                                        optionWeights[
                                            UINTs[3] /*top option*/
                                        ] &&
                                        !ticket.subjective
                                    ) {
                                        UINTs[3] = opt; /*top option*/
                                    }
                                    break;
                                }
                            }

                            //add new unique option
                            if (
                                opt == UINTs[2] /*option count*/
                            ) {
                                if (ticket.dataType == 1) {
                                    intOptions[
                                        UINTs[2] /*option count*/
                                    ] = ticket.intVotes[watcher];
                                } else if (ticket.dataType == 2) {
                                    bytesOptions[
                                        UINTs[2] /*option count*/
                                    ] = ticket.bytesVotes[watcher];
                                } else if (ticket.dataType == 3) {
                                    addressOptions[
                                        UINTs[2] /*option count*/
                                    ] = ticket.addressVotes[watcher];
                                }
                                optionWeights[
                                    UINTs[2] /*option count*/
                                ] = totalShares[watcher];

                                UINTs[2] += 1; /*option count*/
                            }
                        } else if (ticket.rejected[watcher]) {
                            UINTs[1] += totalShares[watcher]; /*weight of rejections*/
                        }
                    }
                } else {
                    ticket.damaged[watcher] = true;
                }
            }

            if (
                (UINTs[4] == /*total Eligible Weight*/
                    (UINTs[1] + UINTs[0]) && /*weight of rejections*/ /*weight of votes*/
                    !ticket.subjective) ||
                (now >
                    ticket.timeRequested +
                        ticket.timeWindow *
                        (ticket.subjective ? 3 : 2))
            ) {
                bool rejected;
                if (
                    UINTs[1] > /*weight of rejections*/
                    optionWeights[
                        UINTs[3] /*top option*/
                    ]
                ) {
                    rejected = true;
                }
                uint8 dataType = ticket.dataType;
                //write results in stone
                if (rejected) {
                    ticket.ticketRejected = true;
                } else {
                    if (ticket.subjective) {
                        ticket.numberOfOptions = UINTs[2]; /*option count*/
                        for (UINTs[6] = 0; UINTs[6] < UINTs[2]; UINTs[6] += 1) {
                            ticket.weightOfResults[UINTs[6]] = optionWeights[
                                UINTs[6]
                            ];
                            if (dataType == 1) {
                                ticket.resolvedInts[UINTs[6]] = intOptions[
                                    UINTs[6]
                                ];
                            } else if (dataType == 2) {
                                ticket.resolvedBytes[UINTs[6]] = bytesOptions[
                                    UINTs[6]
                                ];
                            } else if (dataType == 3) {
                                ticket.resolvedAddresses[
                                    UINTs[6]
                                ] = addressOptions[UINTs[6]];
                            }
                        }
                    } else {
                        ticket.numberOfOptions = UINTs[2] == 0 ? 0 : 1; //just in case no one responds the number of options needs to be 0
                        if (dataType == 1) {
                            ticket.resolvedInts[0] = intOptions[
                                UINTs[3] /*top option*/
                            ];
                        } else if (dataType == 2) {
                            ticket.resolvedBytes[0] = bytesOptions[
                                UINTs[3] /*top option*/
                            ];
                        } else if (dataType == 3) {
                            ticket.resolvedAddresses[0] = addressOptions[
                                UINTs[3] /*top option*/
                            ];
                        }
                    }
                }

                //dish out the rewards
                earningsPerShare[ORACLE] +=
                    (ticket.serviceFee * scaleFactor) /
                    totalShares[ORACLE];

                ticket.finalized = true;
                if (dataType == 1) {
                    Requestor(ticket.sender).oracleIntFallback(
                        ticket.ID,
                        ticket.ticketRejected,
                        ticket.numberOfOptions,
                        optionWeights,
                        intOptions
                    );
                } else if (dataType == 2) {
                    Requestor(ticket.sender).oracleBytesFallback(
                        ticket.ID,
                        ticket.ticketRejected,
                        ticket.numberOfOptions,
                        optionWeights,
                        bytesOptions
                    );
                } else if (dataType == 3) {
                    Requestor(ticket.sender).oracleAddressFallback(
                        ticket.ID,
                        ticket.ticketRejected,
                        ticket.numberOfOptions,
                        optionWeights,
                        addressOptions
                    );
                }

                emit FinalizedRequest(ticket.ID, watchers);
            } else {
                revert();
            }
        }
    }

    event Cashout(address addr, uint256 ETH);

    function cashout(address[] memory pools) external {
        address payable sender = msg.sender;
        for (uint256 p; p < pools.length; p += 1) {
            update(pools[p], sender);
        }
        runWatcherPayroll(sender);
        uint256 ETH = earnings[sender];
        earnings[sender] = 0;
        emit Cashout(sender, ETH);
        sender.transfer(ETH);
    }

    function runWatcherPayroll(address watcher) public {
        if (isWatcher(watcher)) {
            update(ORACLE, watcher);
            updateWatcherTxEarnings(watcher, true);
        }
    }

    function tryToPunish(uint256[] memory tickets, address[] memory watchers)
        external
    {
        freezeNoncommits(tickets, watchers);
        freezeUnrevealedCommits(tickets, watchers);
        freezeWrongWatchers(tickets, watchers);
    }

    event FreezeNoncommits(uint256 ticketID, address watcher);

    function freezeNoncommits(
        uint256[] memory tickets,
        address[] memory watchers
    ) public {
        // get them while they're still at the round table and we're in the reveal phase of a ticket
        RequestTicket storage ticket;
        for (uint256 i; i < watchers.length; i += 1) {
            ticket = requestTickets[tickets[i]];
            if (
                isWatcher(watchers[i]) &&
                !ticket.committed[watchers[i]] &&
                timeSeated[watchers[i]] <= ticket.timeRequested &&
                now > ticket.timeRequested + ticket.timeWindow
            ) {
                if (punish(tickets[i], watchers[i])) {
                    emit FreezeNoncommits(tickets[i], watchers[i]);
                }
            }
        }
    }

    event FreezeUnrevealedCommits(uint256 ticketID, address watcher);

    function freezeUnrevealedCommits(
        uint256[] memory tickets,
        address[] memory watchers
    ) public {
        // get them if they made a commit, but did not reveal it after the reveal window is over
        RequestTicket storage ticket;
        for (uint256 i; i < watchers.length; i += 1) {
            ticket = requestTickets[tickets[i]];
            if (
                ticket.committed[watchers[i]] &&
                !ticket.revealed[watchers[i]] &&
                now >
                requestTickets[tickets[i]].timeRequested + ticket.timeWindow * 2
            ) {
                if (punish(tickets[i], watchers[i])) {
                    emit FreezeUnrevealedCommits(tickets[i], watchers[i]);
                }
            }
        }
    }

    event FreezeWrongWatchers(uint256 ticketID, address watcher);

    function freezeWrongWatchers(
        uint256[] memory tickets,
        address[] memory watchers
    ) public {
        // get them if the ticket is finalized and their vote doesn't match the resolved answer
        address watcher;
        RequestTicket storage ticket;
        for (uint256 i; i < watchers.length; i += 1) {
            ticket = requestTickets[tickets[i]];
            watcher = watchers[i];
            if (
                ticket.finalized &&
                ticket.committed[watcher] &&
                !ticket.ticketRejected &&
                ((!ticket.subjective &&
                    ((ticket.dataType == 1 &&
                        ticket.resolvedInts[0] != ticket.intVotes[watcher]) ||
                        (ticket.dataType == 2 &&
                            compareBytes(
                                keccak256(ticket.resolvedBytes[0]),
                                keccak256(ticket.bytesVotes[watcher])
                            )) ||
                        (ticket.dataType == 3 &&
                            ticket.resolvedAddresses[0] !=
                            ticket.addressVotes[watcher]))) ||
                    (ticket.subjective && ticket.damaged[watcher]) || //if their subjective contribution is garbage
                    ticket.rejected[watcher]) //if they reject something the majority didn't reject
            ) {
                if (punish(tickets[i], watcher)) {
                    emit FreezeWrongWatchers(tickets[i], watcher);
                }
            }
        }
    }

    event Punish(address watcher, uint256 thawOutTime);

    function punish(uint256 ticketID, address watcher)
        internal
        returns (bool punished)
    {
        RequestTicket storage ticket = requestTickets[ticketID];
        if (latestPunishment[watcher] < ticket.timeRequested) {
            if (isWatcher(watcher)) {
                removeShares(ORACLE, watcher, totalShares[watcher]);
            }

            frozen[watcher] = true;
            latestPunishment[watcher] = ticket.timeRequested;
            timeWhenThawedOut[watcher] =
                now +
                oracleConfigurations[FREEZE_TIMEOUT];

            emit Punish(watcher, timeWhenThawedOut[watcher]);
            return true;
        }
        return false;
    }

    event Thaw(address candidate);

    function thaw(address candidate) public {
        if (now >= timeWhenThawedOut[candidate] && frozen[candidate]) {
            frozen[candidate] = false;
            if (candidatesChair[candidate] < hotSeats && !paused[candidate]) {
                addShares(ORACLE, candidate, totalShares[candidate]);
                timeSeated[candidate] = now;
            }
            emit Thaw(candidate);
        } else {
            revert();
        }
    }

    event PauseOut(address sender);

    function pauseOut() public {
        address sender = msg.sender;
        if (isWatcher(sender)) {
            removeShares(ORACLE, sender, totalShares[sender]);
        }
        paused[sender] = true;
        emit PauseOut(sender);
    }

    event Unpause(address sender);

    function unpause(bool _assert) public {
        address sender = msg.sender;
        paused[sender] = false;
        if (candidatesChair[sender] < hotSeats) {
            if (!frozen[sender]) addShares(ORACLE, sender, totalShares[sender]);
            //timeSeated[sender] = now; //this refreshes when they sat down. so they lose responsibility for old tickets.
        } else if (_assert) {
            assertCandidate();
        }
        emit Unpause(sender);
    }

    event UpdateRoundTable(uint256 newTotalHotSeats);

    function updateRoundTable(uint256 seats) public {
        // update hotSeats up and down.
        address candidate;
        uint256 s;
        for (s = 0; s < seats; s += 1) {
            if (oracleConfigurations[ROUNDTABLE_SEATS] > hotSeats) {
                candidate = chairsCandidate[hotSeats];
                addShares(ORACLE, candidate, totalShares[candidate]);
                timeSeated[candidate] = now;
                hotSeats += 1;
            }
            if (oracleConfigurations[ROUNDTABLE_SEATS] < hotSeats) {
                candidate = chairsCandidate[hotSeats - 1];
                removeShares(ORACLE, candidate, totalShares[candidate]);
                hotSeats -= 1;
            }
            if (oracleConfigurations[ROUNDTABLE_SEATS] == hotSeats) {
                break;
            }
        }
        emit UpdateRoundTable(hotSeats);
    }

    function viewRequestTicket(uint256 ticketID)
        public
        view
        returns (
            address sender,
            uint256 timeRequested,
            uint256 timeWindow,
            uint256 numberOfOptions,
            bool finalized,
            bool rejected,
            uint256[] memory weightOfResults,
            int256[] memory resolvedInts,
            bytes[] memory resolvedBytes,
            address[] memory resolvedAddresses
        )
    {
        RequestTicket storage T = requestTickets[ticketID];
        sender = T.sender;
        timeRequested = T.timeRequested;
        timeWindow = T.timeWindow;
        finalized = T.finalized;
        numberOfOptions = T.numberOfOptions;
        rejected = T.ticketRejected;

        weightOfResults = new uint256[](T.numberOfOptions);
        resolvedInts = new int256[](T.numberOfOptions);
        resolvedBytes = new bytes[](T.numberOfOptions);
        resolvedAddresses = new address[](T.numberOfOptions);
        //yikes
        for (uint256 i = 0; i < T.numberOfOptions; i += 1) {
            weightOfResults[i] = T.weightOfResults[i];
            resolvedInts[i] = T.resolvedInts[i];
            resolvedBytes[i] = T.resolvedBytes[i];
            resolvedAddresses[i] = T.resolvedAddresses[i];
        }
    }

    function viewCandidates(bool personal_or_roundtable, address perspective)
        public
        view
        returns (
            address[] memory addresses,
            uint256[] memory dividends,
            bool[] memory hasChairs,
            uint256[] memory seat,
            uint256[] memory weights,
            uint256[] memory clocks,
            bool[] memory isFrozen,
            bool[] memory isPaused,
            uint256[] memory roundTableDividends
        )
    {
        uint256 L;

        if (personal_or_roundtable) {
            L = hotSeats;
        } else {
            L = yourBacking[perspective].length;
        }

        dividends = new uint256[](L);
        seat = new uint256[](L);
        roundTableDividends = new uint256[](L);

        weights = new uint256[](L * 2);
        clocks = new uint256[](L * 3);

        isFrozen = new bool[](L);
        isPaused = new bool[](L);
        hasChairs = new bool[](L);

        addresses = new address[](L);

        address candidate;
        for (uint256 c = 0; c < L; c += 1) {
            if (personal_or_roundtable) {
                candidate = chairsCandidate[c];
            } else {
                candidate = yourBacking[perspective][c];
            }
            addresses[c] = candidate;
            dividends[c] = dividendsOf(candidate, perspective);
            roundTableDividends[c] = dividendsOf(ORACLE, candidate);
            seat[c] = candidatesChair[candidate];
            weights[c] = shares[candidate][perspective];
            weights[c + L] = totalShares[candidate];
            isFrozen[c] = frozen[candidate];
            isPaused[c] = paused[candidate];
            hasChairs[c] = hasChair[candidate];
            clocks[c] = timeWhenThawedOut[candidate];
            clocks[c + L] = timeSeated[candidate];
            clocks[c + L * 2] = latestPunishment[candidate];
        }
    }

    function viewGovernance(address addr)
        public
        view
        returns (uint256[] memory data)
    {
        data = new uint256[](CONFIGS * 4);
        for (uint256 i = 0; i < CONFIGS; i += 1) {
            data[i] = oracleConfigurations[i];
            data[CONFIGS + i] = totalVotes_forEach_configOption[i][
                oracleConfigurations[i]
            ];
            data[CONFIGS * 2 + i] = individualsSelectedOption[i][addr];
            data[CONFIGS * 3 + i] = totalVotes_forEach_configOption[i][
                individualsSelectedOption[i][addr]
            ];
        }
    }

    function accountData(address account)
        public
        view
        returns (
            uint256 _resolveWeight,
            uint256 _weightLocked,
            uint256 _timeSeated,
            bool _frozen,
            bool _paused,
            bool _hasChair,
            uint256 _earnings,
            uint256 _totalShares,
            uint256[] memory UINTs
        )
    {
        _resolveWeight = resolveWeight[account];
        _weightLocked = weightLocked[account];
        _timeSeated = timeSeated[account];
        _frozen = frozen[account];
        _paused = paused[account];
        _hasChair = hasChair[account];
        _earnings = earnings[account];
        _totalShares = totalShares[account];
        UINTs = new uint256[](5);

        if (isWatcher(account)) {
            UINTs[0] = earningsPerWatcher - watcherPayouts[account]; //txCoverageFee
            UINTs[1] =
                (dividendsOf(ORACLE, account) *
                    oracleConfigurations[DELEGATE_REWARDSHARE]) /
                (1e20);
        }

        UINTs[2] = timeWhenThawedOut[account];
        UINTs[3] = latestPunishment[account];
        UINTs[4] = candidatesChair[account];
    }

    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function compareBytes(bytes32 a, bytes32 b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function bytesToAddress(bytes memory bys)
        private
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}

abstract contract ResolveToken {
    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool);
}

abstract contract Pyramid {
    function pullResolves(uint256 amount)
        public
        virtual
        returns (uint256 forfeiture);

    function resolveToken() public view virtual returns (ResolveToken);
}

abstract contract Requestor {
    function oracleIntFallback(
        uint256 ticketID,
        bool rejected,
        uint256 numberOfOptions,
        uint256[] memory optionWeights,
        int256[] memory intOptions
    ) external virtual;

    function oracleBytesFallback(
        uint256 ticketID,
        bool rejected,
        uint256 numberOfOptions,
        uint256[] memory optionWeights,
        bytes[] memory bytesOptions
    ) external virtual;

    function oracleAddressFallback(
        uint256 ticketID,
        bool rejected,
        uint256 numberOfOptions,
        uint256[] memory optionWeights,
        address[] memory addressOptions
    ) external virtual;
}

abstract contract Greenpoint {
    function payEthToAcreStakers() public payable virtual;
}
