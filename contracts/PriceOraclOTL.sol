pragma solidity ^0.5.12;

import "./CErc20.sol";
import "./CToken.sol";
import "./PriceOracle.sol";
import "./Comptroller.sol";

contract PriceOracleOTL is PriceOracle {

    /**
     * @notice The comptroller which is used to white-list assets the oracle will price
     * @dev Assets which are not white-listed will not be priced, to defend against abuse
     */
    Comptroller public comptroller;

    address payable public admin;

    address payable public poster;

    bool public constant isPriceOracle = true;

    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    mapping(address => uint) prices;

    event PricePosted(address indexed asset, address indexed postedBy, uint previousPriceMantissa, uint indexed requestedPriceMantissa, uint newPriceMantissa);
    event NewPoster(address indexed oldPoster, address indexed newPoster);

    constructor(address comptroller_) public {
        comptroller = Comptroller(comptroller_);
        admin = msg.sender;
        _setPosterInternal(msg.sender);
        _notEntered = true;
    }

    /**
     * @notice Do not pay into PriceOracle
     */
    function() external payable  {
        revert("Fallback Revert");
    }

    function getUnderlyingPrice(CToken cToken) public view returns (uint) {

        address cTokenAddress = address(cToken);
        (bool isListed, ,) = comptroller.markets(cTokenAddress);

        if (!isListed) {
            // not white-listed, worthless
            return 0;
        }

        return prices[address(CErc20(address(cToken)).underlying())];
    }

    function setUnderlyingPrice(CToken cToken, uint underlyingPriceMantissa) public nonReentrant {
        require(msg.sender == poster || msg.sender == admin, "Unauthorized");

        address asset = address(CErc20(address(cToken)).underlying());
        emit PricePosted(asset, msg.sender, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
        prices[asset] = underlyingPriceMantissa;
    }

    function setDirectPrice(address asset, uint priceMantissa) public {
        require(msg.sender == poster || msg.sender == admin, "Unauthorized");

        emit PricePosted(asset, msg.sender, prices[asset], priceMantissa, priceMantissa);
        prices[asset] = priceMantissa;
    }

    // v1 price oracle interface for use as backing of proxy
    function assetPrices(address asset) external view returns (uint) {
        return prices[asset];
    }

    /*** Admin Functions ***/

    function _setPoster(address payable newPoster) external {
        // Check caller = admin
        require(msg.sender == admin, "Unauthorized");

        _setPosterInternal(newPoster);
    }

    function _setPosterInternal(address payable newPoster) internal {
        emit NewPoster(poster, newPoster);
        poster = newPoster;
    }


    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }
}
