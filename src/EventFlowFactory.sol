// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./EventFlow.sol";

contract EventFlowFactory {
    EventFlowTicket[] eventFlowTickets;

    function createEventFlowClone(
        string memory eventTitle,
        string memory eventDescription,
        string memory eventLocation,
        string memory ticketURI,
        uint256 eventDate,
        uint256 ticketPrice
    ) public returns (bool success) {
        EventFlowTicket eventFlow = new EventFlowTicket(
            msg.sender,
            eventTitle,
            eventDescription,
            eventLocation,
            ticketURI,
            eventDate,
            ticketPrice
        );
        eventFlowTickets.push(eventFlow);
    }
}
