pragma solidity ^0.5.12;

import "./InterestRateModel.sol";

/**
  * @title Interest rate model for invoice token
  *
  * It's almost a dummy model, where the borrow rate being zero
  * and the supply rate being zero. But collateral factor should be 0
  */
contract InvoiceTokenInterestRateModel is InterestRateModel {

    function getBorrowRate(uint /*cash*/, uint /*borrows*/, uint /*reserves*/)
        external view returns (uint) {
        return 0;
    }

    function getSupplyRate(uint /*cash*/, uint /*borrows*/, uint /*reserves*/, uint /*reserveFactorMantissa*/)
        external view returns (uint) {
        return 0;
    }
}
