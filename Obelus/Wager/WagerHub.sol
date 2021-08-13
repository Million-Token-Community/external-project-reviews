/**
 *Submitted for verification at Etherscan.io on 2021-07-25
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

contract WagerHub {
    uint256 constant $ = 1e18;
    Oracle ORACLE = Oracle(0x6c8E3ef0fc3aaf0b99775c9ef8B1530e279c5AF2);
    address address0 = address(0);
    address THIS = address(this);
    mapping(uint256 => Wager) wagers;
    uint256 public wagerCount;

    constructor() {}

    struct Wager {
        uint256 ID;
        string query;
        address asset;
        uint256 finalizeWagerTime;
        uint256 cutOffTime;
        uint256 unresolvedTimeout;
        uint256 wagerPositions;
        uint256 totalValue;
        bool finalized;
        bool unresolved;
        bool oracleRequestSent;
        mapping(address => bool) positioned;
        mapping(address => uint256) position;
        mapping(address => uint256) weight;
        mapping(uint256 => uint256) totalValueInPosition;
        uint256 requestTicketID;
        uint256 winningPosition;
        mapping(address => bool) takenReward;
    }

    function viewWager(uint256 ID, address perspective)
        public
        view
        returns (
            string memory query,
            address asset,
            uint256[] memory UINTs,
            bool[] memory BOOLs,
            uint256[] memory positionWeights
        )
    {
        Wager storage wager = wagers[ID];

        query = wager.query;
        asset = wager.asset;
        BOOLs = new bool[](5);
        BOOLs[0] = wager.finalized;
        BOOLs[1] = wager.unresolved;
        BOOLs[2] = wager.oracleRequestSent;
        BOOLs[3] = wager.positioned[perspective];
        BOOLs[4] = wager.takenReward[perspective];

        UINTs = new uint256[](10);
        UINTs[0] = wager.finalizeWagerTime;
        UINTs[1] = wager.cutOffTime;
        UINTs[2] = wager.unresolvedTimeout;
        UINTs[3] = wager.wagerPositions;
        UINTs[4] = wager.totalValue;
        UINTs[5] = wager.position[perspective];
        UINTs[6] = wager.weight[perspective];
        UINTs[7] = wager.totalValueInPosition[UINTs[5]];
        UINTs[8] = wager.requestTicketID;
        UINTs[9] = wager.winningPosition;

        positionWeights = new uint256[](64);
        for (uint256 i; i < 64; i += 1) {
            positionWeights[i] = wager.totalValueInPosition[i];
        }
    }

    function viewWagers(
        uint256 start,
        uint256 L,
        address perspective
    )
        public
        view
        returns (
            string[] memory QUERYs, //queries
            address[] memory ASSETs, //assets
            uint256[] memory UINTs,
            bool[] memory BOOLs,
            uint256[] memory positionWeights
        )
    {
        QUERYs = new string[](L);
        ASSETs = new address[](L);
        BOOLs = new bool[](5 * L);
        UINTs = new uint256[](10 * L);
        positionWeights = new uint256[](64 * L);

        bool[] memory _BOOLs = new bool[](5);
        uint256[] memory _UINTs = new uint256[](10);
        uint256[] memory _positionWeights = new uint256[](64);

        uint256 j;
        for (uint256 i = start; i < start + L; i += 1) {
            (
                QUERYs[i],
                ASSETs[i],
                _UINTs,
                _BOOLs,
                _positionWeights
            ) = viewWager(i, perspective);
            UINTs[0 + i * 10] = _UINTs[0];
            UINTs[1 + i * 10] = _UINTs[1];
            UINTs[2 + i * 10] = _UINTs[2];
            UINTs[3 + i * 10] = _UINTs[3];
            UINTs[4 + i * 10] = _UINTs[4];
            UINTs[5 + i * 10] = _UINTs[5];
            UINTs[6 + i * 10] = _UINTs[6];
            UINTs[7 + i * 10] = _UINTs[7];
            UINTs[8 + i * 10] = _UINTs[8];
            UINTs[9 + i * 10] = _UINTs[9];
            BOOLs[0 + i * 5] = _BOOLs[0];
            BOOLs[1 + i * 5] = _BOOLs[1];
            BOOLs[2 + i * 5] = _BOOLs[2];
            BOOLs[3 + i * 5] = _BOOLs[3];
            BOOLs[4 + i * 5] = _BOOLs[4];
            for (j = 0; j < 64; j += 1) {
                positionWeights[j + i * 64] = _positionWeights[j];
            }
        }
    }

    event NewWager(
        address sender,
        address asset,
        string query,
        uint256 cutOffTime,
        uint256 finalizeWagerTime,
        uint256 unresolvedTimeout,
        uint256 wagerPositions
    );

    function newWagering(
        string memory query,
        address asset,
        uint256 cutOffTime,
        uint256 finalizeWagerTime,
        uint256 unresolvedTimeout,
        uint256 wagerPositions
    ) public returns (uint256 wagerID) {
        address sender = msg.sender;
        require(
            cutOffTime < finalizeWagerTime &&
                wagerPositions <= 64 &&
                wagerPositions >= 2
        );

        wagerID = wagerCount;
        Wager storage wager = wagers[wagerCount];
        wagerCount++;

        wager.ID = wagerID;
        wager.query = query;
        wager.asset = asset;
        wager.cutOffTime = cutOffTime;
        wager.finalizeWagerTime = finalizeWagerTime;
        if (unresolvedTimeout > 86400 * 30) {
            unresolvedTimeout = 86400 * 30;
        }
        if (unresolvedTimeout < 14400) {
            unresolvedTimeout = 14400;
        }
        wager.unresolvedTimeout = unresolvedTimeout; //no more than 30 days
        wager.wagerPositions = wagerPositions;
        emit NewWager(
            sender,
            asset,
            query,
            cutOffTime,
            finalizeWagerTime,
            unresolvedTimeout,
            wagerPositions
        );
    }

    event WagerIn(address sender, uint256, uint256, uint256);

    function wagerIn(uint256 wagerID, uint256 wagerPosition) public payable {
        require(wagers[wagerID].asset == address0);
        _wagerIn(wagerID, wagerPosition, msg.value);
    }

    function wagerInToken(
        uint256 wagerID,
        uint256 wagerPosition,
        uint256 value
    ) public {
        require(
            ERC20(wagers[wagerID].asset).transferFrom(msg.sender, THIS, value)
        );
        _wagerIn(wagerID, wagerPosition, value);
    }

    function _wagerIn(
        uint256 wagerID,
        uint256 wagerPosition,
        uint256 value
    ) internal {
        address sender = msg.sender;
        Wager storage wager = wagers[wagerID];
        require(
            wagerID < wagerCount &&
                block.timestamp < wager.cutOffTime &&
                value > 0
        );

        if (!wager.positioned[sender]) {
            wager.position[sender] = wagerPosition;
            wager.positioned[sender] = true;
        } else {
            wagerPosition = wager.position[sender];
        }

        wager.totalValue += value;
        wager.weight[sender] += value;
        wager.totalValueInPosition[wagerPosition] += value;
        emit WagerIn(sender, wagerID, wager.position[sender], value);
    }

    mapping(uint256 => uint256) ticketToWager;
    event SendOracleRequest(
        string query,
        uint256 wagerID,
        uint256 requestTicketID
    );
    event Unresolved(uint256);

    function sendOracleRequest(uint256 wagerID) public payable {
        Wager storage wager = wagers[wagerID];
        require(!wager.finalized && block.timestamp >= wager.finalizeWagerTime);
        if (
            block.timestamp >= wager.finalizeWagerTime + wager.unresolvedTimeout
        ) {
            wager.unresolved = true;
            wager.finalized = true;
            payable(msg.sender).transfer(msg.value);
            emit Unresolved(wagerID);
        } else {
            uint256 ID = ORACLE.fileRequestTicket{value: msg.value}(1, false);
            ticketToWager[ID] = wager.ID;
            wager.requestTicketID = ID;
            wager.oracleRequestSent = true;
            emit SendOracleRequest(wager.query, wager.ID, ID);
        }
    }

    event FinalizeWager(uint256, bool, uint256);

    function oracleIntFallback(
        uint256 ticketID,
        bool requestRejected,
        uint256 numberOfOptions,
        uint256[] memory optionWeights,
        int256[] memory intOptions
    ) external {
        Wager storage wager = wagers[ticketToWager[ticketID]];

        require(msg.sender == address(ORACLE) && !wager.finalized);

        if (!requestRejected) {
            wager.winningPosition = uint256(intOptions[0]);
            wager.finalized = true;
            if (wager.totalValueInPosition[wager.winningPosition] == 0) {
                wager.unresolved = true;
            }
        }

        emit FinalizeWager(
            ticketToWager[ticketID],
            requestRejected,
            wager.winningPosition
        );
    }

    event PullMoney(address, uint256, uint256);

    function pullMoney(uint256 wagerID) public {
        address payable sender = payable(msg.sender);
        Wager storage wager = wagers[wagerID];
        require(
            wager.finalized &&
                !wager.takenReward[sender] &&
                /* this last check is technically not necessary*/
                wager.positioned[sender]
        );
        wager.takenReward[sender] = true;
        uint256 valuePulled;
        if (wager.unresolved) {
            valuePulled = wager.weight[sender];
            if (wager.asset == address0) {
                sender.transfer(valuePulled);
            } else {
                ERC20(wager.asset).transfer(sender, valuePulled);
            }
        } else {
            uint256 position = wager.winningPosition;
            require(wager.position[sender] == position);
            uint256 totalValueInPosition = wager.totalValueInPosition[position];
            valuePulled =
                (wager.totalValue * wager.weight[sender]) /
                totalValueInPosition;

            if (wager.asset == address0) {
                sender.transfer(valuePulled);
            } else {
                ERC20(wager.asset).transfer(sender, valuePulled);
            }
        }
        emit PullMoney(sender, wagerID, valuePulled);
    }
}

abstract contract Oracle {
    function fileRequestTicket(uint8 returnType, bool subjective)
        public
        payable
        virtual
        returns (uint256 ticketID);
}

abstract contract ERC20 {
    function balanceOf(address _address)
        public
        view
        virtual
        returns (uint256 balance);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) public virtual returns (bool);

    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool);
}
