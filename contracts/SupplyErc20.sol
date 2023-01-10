//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/compound.sol";

contract SupplyErc20 {
    IERC20 public token; //token that we priovide the protocol
    CErc20 public cToken; //token that we get back for lending the token to the protocol 

    constructor(address _token, address _cToken) {
        token = IERC20(_token);
        cToken = CErc20(_cToken);
    }

    function supply(uint _amount) external {
        token.transferFrom(msg.sender, address(this), _amount); //to lend first we need to transfer the token to the protocol.
        token.approve(address(cToken), _amount); //approve to spend the token that was transfered from msg.sender. 
        require(cToken.mint(_amount) == 0,  "mint failed");// this wiil transfer our Token to ctoken contract and mint Ctoken on behalf.
    }

    function gettokenBalance() external view returns(uint){
        return cToken.balanceOf(address(this)); // ctoken that we get for lending tokens including intrest
        //, this function simply returns the balance of ctokens.
    } 

    function getInfo() external returns(uint exchangeRate, uint supplyRate){
        exchangeRate = cToken.exchangeRateCurrent(); // amount of current exchange rate from cTokens to Tokens that we providedto the protocol.  
        supplyRate = cToken.supplyRatePerBlock(); // to know the interest while supplying token we get the interest rate.
    // we need to do transaction and pay transaction fee to get to know about these Rates.
    }

    function estimateBalanceOfUnderlying() external returns (uint) {
        uint cTokenBal = cToken.balanceOf(address(this));
        uint exchangeRate = cToken.exchangeRateCurrent();
        uint decimals = 8; 
        uint cTokenDecimals = 8;
        return (cTokenBal * exchangeRate) / 10**(18 + decimals - cTokenDecimals);
    }

    function balanceOfUnderlying() external returns (uint) {
        return cToken.balanceOfUnderlying(address(this));
    }
    //for few days after supplying tokens to the protocol and earning interest on it we can reddeem passing redeem on cToken Contract
    // and as these passes we will have some tokens in this contract to withdraw.
    function redeem(uint _cTokenAmount) external {
        require(cToken.redeem(_cTokenAmount) == 0, "redeem failed");
    }

    //Borrow and repay 

    Comptroller public comptroller =
    
    Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    PriceFeed public pricefeed =

    PriceFeed(0x922018674c12a7F0D394ebEEf9B58F186CdE13c1);

    //To get the collateral factor we need to call the market in the comptroller passing the cTokens that we supplied

    function getCollateralFactor() external view returns (uint) {
        (bool isListed, uint colFactor , bool isComped) = comptroller.markets(address(cToken));
        //isComped = it will be getting the rewad token Comp or not
        return colFactor; // to get the collataeral factor in % we need to divide it by 1e18.
    }

// calculate that How much we can Borrow. Here we need to call through comptroller getAccountLiquidity
    function getAccountLiquidity() external view returns (uint liquidity, uint shortfall){
        (uint error, uint _liquidity, uint _shortfall) = comptroller.getAccountLiquidity(address(this));
        //_liquidity = is the USD amount we can borrow from the market.
        //_shortfall = if greater than 0 means you borrow more than the limit .
        require(error == 0, "error");
        return (_liquidity, _shortfall);
    }

// we can get the price of the token that we want to borrow by calling getUnderlyingPrice.
    function getPricefeed(address _cToken) external view returns(uint){
        return priceFeed.getUnderlyingPrice(_cToken);
    }
// here we enter the market and borrow 
    function borrow(address _cTokenBorrow, uint _decimals) external {
        address[] memory cToken = new address[](1);// only 1 token so Arraylength is 1
        cTokens[0] = address(cToken);// only one ctokens we are going to supply here
        uint[] memory errors = comptroller.enterMarkets(cTokens);// enter the market passing the cTokens that we supplied.
        require(errors[0] == 0,
        "comptroller.enterMarkets failed.");

        //check Liquidity
        (uint error, uint liquidity, uint shortfall) = comptroller.getAccountLiquidity(
            address(this)
        );
// Normal conditions to Borrow from the market 
        require(error == 0, "error");
        require(shortfall == 0, "shortfall > 0");
        require(liquidity > 0, "liquidity = 0");// it means we can borrow upto this amount
         // calcuate max borrow

        uint price = priceFeed.getUnderlyingPrice(_cTokenBorrow);
        uint maxBorrow = (liquidity * (10**_decimals)) / price; // because every tokens has decimals 
        require(maxBorrow > 0, "max borrow = 0");

        uint amount = (maxBorrow * 50) / 100;// borrow 50% of the max amount to borrow

        require(CERC20(_CTokenToBorrow).borrow(amount) == 0, "borrow failed");// 0 is the no. to be passed if not it fails
    }

    function getBorrowBalance(address _cTokenBorrowed) public returns (uint) {
        return CErc20(_cTokenBorrowed).borrowedBalnceCurrent(address(this));
    }

    function gwtBorrowRatePerBlock(address _cTokenBorrowed) external view returns (uint){
        return CErc20(_cTokenBorrowed).borrowRatePerBlock();
    }

    function repay(address _tokenBorrowed, address _cTokenBorrowed, uint _amount) external {
        IERC20(_tokenBorrowed).appprove(_cTokenBorrowed, _amount);
        require(CErc20(_ctokenBorowed).repayBorrow(_amount) == 0, "repay failed");
    }


}

