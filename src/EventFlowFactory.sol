// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./EventFlow.sol";

contract EventFlowFactory {
    //aim of the factory contract is to create a new instance of EventFLow every time
    //our user clicks the create button
    //users should be able to interact with all the functions in
    EventFlowTicket[] eventFlowTickets;

    function createEventFlowClone(
        string memory eventTitle,
        string memory eventDescription,
        string memory eventLocation,
        string memory ticketURI,
        uint256 eventDate,
        uint256 ticketPrice
    ) public returns (bool success, EventFlowTicket eventFlow) {
        eventFlow = new EventFlowTicket(
            msg.sender,
            eventTitle,
            eventDescription,
            eventLocation,
            ticketURI,
            eventDate,
            ticketPrice
        );
        eventFlowTickets.push(eventFlow);
        return (success = true, eventFlow);
    }

    function getEventTicketCount() external view returns (uint256) {
        return eventFlowTickets.length;
    }
}
