//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

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

    error InvalidPurchasePrice(string);
    error IncompleteWithdrawCriteria(string);


    address private owner_;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("EventFlow Ticket", "ETicket") {}

    struct ListedEvent {
        address OwnerOfTicket;
        string EventTitle;
        string EventLocation;
        string TicketURI;
        uint256 EventDate;
        uint256 TicketPrice;
        uint256 NumberOfSale;
        uint256 MaxSale;
        uint256 totalAmountGottenFromSale;
        bool isCurrentlyListed;
        uint256 CreateTokenID;
    }

    mapping(uint256 => ListedEvent) idToListedEvent;

    ListedEvent[] allListedEvents;

    mapping(address => ListedEvent[]) eventPurchased;

    //create ticket
    //to add - pass in ticket owner as an argument so we can use
    //it in our factory contract
    //optional - add button for ticket owner to delete ticket
    function createEvent(
        string memory eventTitle,
        string memory eventLocation,
        string memory ticketURI,
        uint256 eventDate,
        uint256 ticketPrice,
        uint256 maxAmountOfSale
    ) public {
        uint256 tokenId = _tokenIdCounter.current();
        uint256 newEventDate = block.timestamp + (eventDate);
        uint256 newTicketPrice = ticketPrice * 1 ether;
        _mint(address(this), tokenId);
        _setTokenURI(tokenId, ticketURI);

        idToListedEvent[tokenId] = ListedEvent(
            msg.sender,
            eventTitle,
            eventLocation,
            ticketURI,
            newEventDate,
            newTicketPrice,
            0,
            maxAmountOfSale,
            0,
            true,
            tokenId
        );

        allListedEvents.push(
            ListedEvent(
                msg.sender,
                eventTitle,
                eventLocation,
                ticketURI,
                eventDate,
                newTicketPrice,
                0,
                maxAmountOfSale,
                0,
                true,
                tokenId
            )
        );
    }

    //@dev this function let's users buy event tickets
    function buyEventTicket(uint256 _tokenId) public payable {
        require(_tokenId <= _tokenIdCounter.current(), "Token does not exist");

        ListedEvent memory LE = idToListedEvent[_tokenId];

        address seller = LE.OwnerOfTicket;
        uint256 maxCountOfSale = LE.MaxSale;
        uint256 price = LE.TicketPrice;
        uint256 eventDate = LE.EventDate;
        uint256 numberOfSales = LE.NumberOfSale;
        uint256 newTicketPrice = LE.TicketPrice;
        string memory ticketURI = LE.TicketURI;
        string memory eventTitle = LE.EventTitle;
        string memory eventLocation = LE.EventLocation;

        require(
            LE.isCurrentlyListed,
            "Ticket sale ended"
        );
        require(
            numberOfSales < maxCountOfSale,
            "Total supply of ticket reached"
        );
        if (msg.value != price) {
            revert InvalidPurchasePrice(
                "Error: Please submit the asking price in order to complete ticket purchase"
            );
        }
        require(seller != address(0), "Error: Invalid Ticket");
        require(block.timestamp < eventDate, "Error: Ticket expired");
        allListedEvents[_tokenId].NumberOfSale += 1;
        allListedEvents[_tokenId].totalAmountGottenFromSale += msg.value;
        LE.totalAmountGottenFromSale += msg.value;



        safeMint(msg.sender, ticketURI);

        eventPurchased[msg.sender].push(
            ListedEvent(
                msg.sender,
                eventTitle,
                eventLocation,
                ticketURI,
                eventDate,
                newTicketPrice,
                0,
                maxCountOfSale,
                0,
                true,
                _tokenId
            )
        );
    }

    ///@dev this function gets one event provided the token id
    function getOneEvent(uint256 _tokenId)
        public
        view
        returns (ListedEvent memory)
    {
        require(_tokenId <= _tokenIdCounter.current(), "Token does not exist");
        return idToListedEvent[_tokenId];
    }

    function getAllEvents() public view returns (ListedEvent[] memory) {
        return allListedEvents;
    }

    //@dev function to get event created by a user
    function getMyEvents() external view returns (ListedEvent[] memory) {
        ListedEvent[] memory totalEvents = new ListedEvent[](
            allListedEvents.length
        );
        uint32 myItemCount;
        uint32 currentIndex;

        for (uint256 i; i < allListedEvents.length; i++) {
            if (idToListedEvent[i].OwnerOfTicket == msg.sender) {
                myItemCount += 1;
            }
        }

        myEvents = new ListedEvent[](myItemCount);

        for (uint256 i; i < myEvents.length; i++) {
            if (idToListedEvent[i].OwnerOfTicket == msg.sender) {
                ListedEvent storage events = idToListedEvent[i];
                myEvents[currentIndex] = events;
                currentIndex += 1;
            }
        }

      return myEvents;
    }

    /// @dev Function for event creators to withdraw amount gotten from their ticket sale
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
        require(msg.sender == eventCreator, "Not event owner");

        require(_tokenId <= _tokenIdCounter.current(), "Token does not exist");

        require(
            idToListedEvent[_tokenId].isCurrentlyListed,
            "Ticket sale ended"
        );
        idToListedEvent[_tokenId].isCurrentlyListed = false;

        uint256 amount = idToListedEvent[_tokenId].totalAmountGottenFromSale;
        require(eventCreator != address(0), "Error: Invalid Ticket");
        require(amount > 0, "Error: No ticket sale yet, nothing to withdraw");

        (uint256 eventListingFee, uint256 remainingBalance) = this
            .getFeePercentage(amount);

        (bool success, ) = payable(owner_).call{value: eventListingFee}("");
        (bool t, ) = payable(eventCreator).call{value: remainingBalance}("");

        require(success, "Failed to send");
        require(t, "Failed to send");
        return (
            "Our fee:",
            eventListingFee,
            "Amount sent to event creator",
            remainingBalance
        );
    }

    /// @dev Private helper function to get 1.82% percentage from event creators total sale

    function getFeePercentage(uint256 _amount)
        external
        view
        returns (uint256, uint256)
    {
        require(msg.sender == owner_, "Not owner");
        uint256 eventListingFee = (_amount * 182) / 10000;
        uint256 remainingBalance = _amount - eventListingFee;
        return (eventListingFee, remainingBalance);
    }

    // function deleteTicket()

    /* function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        super._beforeTokenTransfer(from, to, tokenId, "");
    } */

    //@dev safe mint private function
    //helper function that mints tickets to user on ticket purchase
    function safeMint(address to, string memory uri) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

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

    function checkPurchase(address _addr) external view returns(ListedEvent[] memory){
        return eventPurchased[_addr];
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

// Deployed contract: 0xA87F30B7CD469D65B08bb74f669821259AfD0e7d

