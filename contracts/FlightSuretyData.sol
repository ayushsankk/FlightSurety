pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./FlightSuretyData.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    address[] private registeredAirlines;

    struct Airline {
        address airlineID;
        string airlineName;
        bool isRegistered;
        bool fundingSubmitted;
        uint registrationVotes;
    }

    struct Flight {
        string flight;
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airlineID;
    }

    struct Insurance {
        address insuree;
        uint256 amountInsuredFor;
    }

    mapping(address => bool) private authorizedCallers;
    mapping(address => Airline) private airlines;
    mapping(bytes32 => bool) private airlineRegistrationVotes;
    mapping(bytes32 => Flight) private flights;
    mapping(bytes32 => Insurance[]) private policies;
    mapping(address => uint256) private credits;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
       event AddedAirline(address airlineID);

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        authorizedCallers[msg.sender] = true;
    }

    /** @dev Fallback function for funding smart contract. */
    function() external payable {
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireAuthorizedCaller() {
        require(
            authorizedCallers[msg.sender] == true,
            "Requires caller is authorized to call this function");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            requireAuthorizedCaller
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus 
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

function authorizeCaller(address caller) external requireContractOwner {
        authorizedCallers[caller] = true;
    }

    function deauthorizeCaller(address caller) external requireContractOwner {
        authorizedCallers[caller] = false;
    }
    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function addAirline
                            (
                                address airlineID,
                                string airlineName   
                            )
                            external
                            requireAuthorizedCaller
                            requireIsOperational
    {
        airlines[airlineID] = Airline({
            airlineID: airlineID,
            airlineName: airlineName,
            isRegistered: false,
            fundingSubmitted: false,
            registrationVotes: 0
        });

        emit AddedAirline(airlineID);
    }

    /** @dev Check if airline has been added. */
    function hasAirlineBeenAdded(
        address airlineID
    )
        external
        view
        requireAuthorizedCaller
        requireIsOperational
        returns (bool)
    {
        return airlines[airlineID].airlineID == airlineID;
    }

/** @dev Add an airline. */
    function addToRegisteredAirlines(
        address airlineID
    )
        external
        requireAuthorizedCaller
        requireIsOperational
    {
        airlines[airlineID].isRegistered = true;
        registeredAirlines.push(airlineID);
    }

    /** @dev Check if airline has been registered. */
    function hasAirlineBeenRegistered(
        address airlineID
    )
        external
        view
        requireAuthorizedCaller
        requireIsOperational
        returns (bool)
    {
        return airlines[airlineID].isRegistered;
    }

    /** @dev Get all registered airlines. */
    function getRegisteredAirlines(
    )
        external
        view
        requireAuthorizedCaller
        requireIsOperational
        returns (address[] memory)
    {
        return registeredAirlines;
    }

    
    function hasAirlineVotedFor(
        address airlineVoterID,
        address airlineVoteeID
    )
        external
        view
        requireAuthorizedCaller
        requireIsOperational
        returns (bool)
    {
        bytes32 voteHash = keccak256(
            abi.encodePacked(airlineVoterID, airlineVoteeID));
        return airlineRegistrationVotes[voteHash] == true;
    }

function voteForAirline(
        address airlineVoterID,
        address airlineVoteeID
    )
        external
        requireAuthorizedCaller
        requireIsOperational
        returns (uint)
    {
        bytes32 voteHash = keccak256(
            abi.encodePacked(airlineVoterID, airlineVoteeID));
        airlineRegistrationVotes[voteHash] = true;
        airlines[airlineVoteeID].registrationVotes += 1;

        return airlines[airlineVoteeID].registrationVotes;
    }

    function setFundingSubmitted(
        address airlineID
    )
        external
        requireAuthorizedCaller
        requireIsOperational
    {
        airlines[airlineID].fundingSubmitted = true;
    }

    function addToRegisteredFlights(
        address airlineID,
        string flight,
        uint256 timestamp
    )
        external
        requireAuthorizedCaller
        requireIsOperational
    {
        flights[getFlightKey(airlineID, flight, timestamp)] = Flight({
            isRegistered: true,
            statusCode: 0, // STATUS_CODE_LATE_AIRLINE
            updatedTimestamp: timestamp,
            airlineID: airlineID,
            flight: flight
        });
    }

    function hasFundingBeenSubmitted(
        address airlineID
    )
        external
        view
        requireAuthorizedCaller
        requireIsOperational
        returns (bool)
    {
        return airlines[airlineID].fundingSubmitted == true;
    }

    function addToInsurancePolicy(
        address airlineID,
        string flight,
        address _insuree,
        uint256 amountToInsureFor
    )
        external
        requireAuthorizedCaller
        requireIsOperational
    {
        policies[keccak256(abi.encodePacked(airlineID, flight))].push(
            Insurance({
                insuree: _insuree,
                amountInsuredFor: amountToInsureFor
            })
        );
    }
   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    address airlineID,
                                    string flight,
                                    uint256 creditMultiplier
                                )
                                external
                                requireAuthorizedCaller
                                requireIsOperational
    {
        bytes32 policyKey = keccak256(abi.encodePacked(airlineID, flight));
        Insurance[] memory policiesToCredit = policies[policyKey];

        uint256 currentCredits;
        for (uint i = 0; i < policiesToCredit.length; i++) {
            currentCredits = credits[policiesToCredit[i].insuree];
            // Calculate payout with multiplier and add to existing credits
            uint256 creditsPayout = (
                policiesToCredit[i].amountInsuredFor.mul(creditMultiplier).div(10));
            credits[policiesToCredit[i].insuree] = currentCredits.add(
                creditsPayout);
        }

        delete policies[policyKey];
    }
    
        function withdrawCreditsForInsuree(
        address insuree
    )
        external
        requireAuthorizedCaller
        requireIsOperational
    {
        uint256 creditsAvailable = credits[insuree];
        require(creditsAvailable > 0, "Requires credits are available");
        credits[insuree] = 0;
        insuree.transfer(creditsAvailable);
    }


    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        internal
                        requireAuthorizedCaller
                        requireIsOperational
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }
}

