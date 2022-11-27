# EventFlow
The EventFlowTicket contract provides event management and NFT Ticketing services, this makes EventFlow an Event management and NFT Ticketing platform, and as an additional feature provides users a portfolio of their connected wallet address.

Another bonus feature of EventFlow is it provides gas estimations for users, this allows users to know the amount of gas/fee they do spend for a transaction before performing the transaction.

In EventFlow you can:
- Create events as a creator (Event Host).
- Buy event tickets as an attendee of an event.
- Find Event near you.
- Track Top events to attend.
- Own NFT by buying Event Tickets
- As a bonus to users of EventFlow you automatically have profile of your connected wallet address

Checkout the EventFlowTicket contract [here](https://github.com/BlockHashiras/EventFlow/blob/main/src/EventFlow.sol)

## Summary of the EventFlowTicket Contract Functions

### createEvent
This function is responsible for creating event tickets for a particular event, the event creator provides the ticket image, event title, event location, event date and time, ticket quantity and event price. Event price is 0 if creator want the event attendance to be free.

### buyEventTicket
This functions lets event attendees to purchase event ticket for a particular event, which automatically gives them pass to attend the event, when users buys a ticket for a particular event they automatically owns that event ticket as an NFT asset, minted to their account.

### getOneEvent
This function returns the details of a specific event, provided the event id it returns the details of an event.

### getAllEvents
This function returns all the events created in the EventFlow platform.

### getMyEvents
This function gets all the events created by a specific creator.

### withdrawAmountFromTicketSale
This function allows event creators to withdraw the money made from purchased event tickets of their event.

### getFeePercentage
This function calculates 1.82% of the total fund raised from selling event tickets of a particlar event, this function is called whenever a creator wants to withdraw this fund, 1.82% is the percentage EventFlow charge creators for using the platform.

Checkout the EventFlowTicket contract [here](https://github.com/BlockHashiras/EventFlow/blob/main/src/EventFlow.sol)
