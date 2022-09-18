//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract EventFlowTicket is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Ownable
{
    //create ticket based on the ticket struct
    //on creation ticket's gets minted to msg.sender and then transferred in same
    // function to this contract, so we can sell tickets on their behalf

    //when another users executes sale based on ticket tokenID,
    // they pay ticket price if any and the ticket gets minted to them

    // address _ticketAdmin;
    // string _eventTitle;
    // string _eventDescription;
    // string _eventLocation;
    // string _ticketURI;
    // uint256 _eventDate;
    // uint256 _ticketPrice;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor(
        address ticketAdmin_,
        string memory eventTitle_,
        string memory eventDescription_,
        string memory eventLocation_,
        string memory ticketURI_,
        uint256 eventDate_,
        uint256 ticketPrice_
    ) ERC721("EventFlow Ticket", "ETicket") {
        createTicket(
            ticketAdmin_,
            eventTitle_,
            eventDescription_,
            eventLocation_,
            ticketURI_,
            eventDate_,
            ticketPrice_
        );
    }

    struct ListedTicket {
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

    mapping(uint256 => ListedTicket) idToListedTicket;

    ListedTicket[] allListedTickets;

    error InvalidPurchasePrice(string);

    //create ticket
    //to add - pass in ticket owner as an argument so we can use
    //it in our factory contract
    //optional - add button for ticket owner to delete ticket
    function createTicket(
        address ticketOwner,
        string memory eventTitle,
        string memory eventDescription,
        string memory eventLocation,
        string memory ticketURI,
        uint256 eventDate,
        uint256 ticketPrice
    ) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        uint256 newEventDate = block.timestamp + (eventDate);
        uint256 newTicketPrice = ticketPrice * 1 ether;
        safeMint(msg.sender, ticketURI);
        _transfer(msg.sender, address(this), tokenId);

        idToListedTicket[tokenId] = ListedTicket(
            ticketOwner,
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

        allListedTickets.push(
            ListedTicket(
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

    function buyTicket(uint256 _tokenId) public payable {
        uint256 price = idToListedTicket[_tokenId].TicketPrice;
        uint256 eventDate = idToListedTicket[_tokenId].EventDate;
        address seller = idToListedTicket[_tokenId].OwnerOfTicket;
        string memory ticketURI = idToListedTicket[_tokenId].TicketURI;

        require(seller != address(0), "Error: Invalid Ticket");
        require(block.timestamp < eventDate, "Error: Ticket expired");

        if (msg.value != price) {
            revert InvalidPurchasePrice(
                "Error: Please submit the asking price in order to complete ticket purchase"
            );
        }
        idToListedTicket[_tokenId].NumberOfSale += 1;
        idToListedTicket[_tokenId].totalAmountGottenFromSale += msg.value;
        payable(seller).transfer(msg.value);
        safeMint(msg.sender, ticketURI);
    }

    function getOneTicket(uint256 _tokenId)
        public
        view
        returns (ListedTicket memory)
    {
        return idToListedTicket[_tokenId];
    }

    function getALlTickets() public view returns (ListedTicket[] memory) {
        return allListedTickets;
    }

    //safe mint private function
    function safeMint(address to, string memory uri) private  {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
