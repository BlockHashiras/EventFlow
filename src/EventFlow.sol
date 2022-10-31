//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/Counters.sol";

contract EventFlowTicket is ERC721URIStorage, Ownable {
    //create ticket based on the ticket struct
    //on creation ticket's gets minted to msg.sender and then transferred in same
    // function to this contract, so we can sell tickets on their behalf

    //when another users executes sale based on ticket tokenID,
    // they pay ticket price if any and the ticket gets minted to them
    address private owner_;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("EventFlow Ticket", "ETicket") {}

    struct ListedEvent {
        address OwnerOfTicket;
        string EventTitle;
        string EventDescription;
        string EventLocation;
        string TicketURI;
        uint256 EventDate;
        uint256 TicketPrice;
        uint256 NumberOfSale;
        uint256 totalAmountGottenFromSale;
        bool isCurrentlyListed;
    }

    mapping(uint256 => ListedEvent) idToListedEvent;

    ListedEvent[] allListedEvents;

    error InvalidPurchasePrice(string);
    error IncompleteWithdrawCriteria(string);

    //create ticket
    //to add - pass in ticket owner as an argument so we can use
    //it in our factory contract
    //optional - add button for ticket owner to delete ticket
    function createEvent(
        string memory eventTitle,
        string memory eventDescription,
        string memory eventLocation,
        string memory ticketURI,
        uint256 eventDate,
        uint256 ticketPrice
    ) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        uint256 newEventDate = block.timestamp + (eventDate);
        uint256 newTicketPrice = ticketPrice * 1 ether;
        safeMint(msg.sender, ticketURI);
        _transfer(msg.sender, address(this), tokenId);

        idToListedEvent[tokenId] = ListedEvent(
            msg.sender,
            eventTitle,
            eventDescription,
            eventLocation,
            ticketURI,
            newEventDate,
            newTicketPrice,
            0,
            0,
            true
        );

        allListedEvents.push(
            ListedEvent(
                msg.sender,
                eventTitle,
                eventDescription,
                eventLocation,
                ticketURI,
                eventDate,
                newTicketPrice,
                0,
                0,
                true
            )
        );
        return tokenId;
    }

    function buyEventTicket(uint256 _tokenId) public payable {
        uint256 price = idToListedEvent[_tokenId].TicketPrice;
        uint256 eventDate = idToListedEvent[_tokenId].EventDate;
        address seller = idToListedEvent[_tokenId].OwnerOfTicket;
        string memory ticketURI = idToListedEvent[_tokenId].TicketURI;

        if (msg.value != price) {
            revert InvalidPurchasePrice(
                "Error: Please submit the asking price in order to complete ticket purchase"
            );
        }
        require(seller != address(0), "Error: Invalid Ticket");
        require(block.timestamp < eventDate, "Error: Ticket expired");
        allListedEvents[_tokenId].NumberOfSale += 1;
        allListedEvents[_tokenId].totalAmountGottenFromSale += msg.value;
        idToListedEvent[_tokenId].NumberOfSale += 1;
        idToListedEvent[_tokenId].totalAmountGottenFromSale += msg.value;
        safeMint(msg.sender, ticketURI);
    }

    //function for event creators to withdraw amount gotten from their ticket sale
    function withdrawAmountFromTicketSale(uint256 _tokenId)
        public
        returns (
            string memory,
            uint256,
            string memory,
            uint256
        )
    {
        address eventCreator = idToListedEvent[_tokenId].OwnerOfTicket;
        uint256 amount = idToListedEvent[_tokenId].totalAmountGottenFromSale;
        require(eventCreator != address(0), "Error: Invalid Ticket");
        require(msg.sender == eventCreator, "Not event owner");
        require(amount > 0, "Error: No ticket sale yet, nothing to withdraw");

        (uint256 eventListingFee, uint256 remainingBalance) = getFeePercentage(
            amount
        );
        payable(eventCreator).transfer(remainingBalance);
        payable(owner_).transfer(eventListingFee);
        return (
            "Our fee:",
            eventListingFee,
            "Amount sent to event creator",
            remainingBalance
        );
    }

    function getOneEvent(uint256 _tokenId)
        public
        view
        returns (ListedEvent memory)
    {
        return idToListedEvent[_tokenId];
    }

    function getAllEvents() public view returns (ListedEvent[] memory) {
        return allListedEvents;
    }

    //safe mint private function
    //helper function that mints tickets to user on ticket purchase
    function safeMint(address to, string memory uri) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // private helper function to get 1.82% percentage from event creators total sale
    function getFeePercentage(uint256 _amount)
        private
        pure
        returns (uint256, uint256)
    {
        uint256 eventListingFee = (_amount * 182) / 10000;
        uint256 remainingBalance = _amount - eventListingFee;
        return (eventListingFee, remainingBalance);
    }

    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) internal {
    //     super._beforeTokenTransfer(from, to, tokenId);
    // }

    function _burn(uint256 tokenId) internal override(ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
