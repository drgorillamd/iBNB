pragma solidity 0.8.0;
// SPDX-License-Identifier: GPL - @DrGorilla_md (Tg/Twtr)

/*
Supply Breakdown Update:

Total Supply - 1 QT

Burn - 300T
Team - 40T
Marketing - 45T
Private - 27T  (Split between the team and airdropped into separate wallets in randomly sized chunks to avoid any questions)
Presale - 250T
Public - 338T

Pre sale/Launch:

NB: Figures based on BNB @ $340

Hardcap - 500 BNB
Softcap - 300 BNB

Max buy - 2 BNB
Min buy - 0.2 BNB

Presale - 500B per BNB
Pancake - 400B per BNB

% to LP - 90%

LP at hardcap - $153,000
LP at softcap - $91,800

Spare funds at hardcap - $15,300
Spare funds at softcap - $10,200

MC at pre sale - $476,000
MC at public launch - $595,000

**MC figures dependant on pre sale filling up and no more tokens burnt.
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract iBNB_presale is Ownable {

using SafeMath for uint256;

// -- variables --

    mapping (address => bool) whitelist;
    mapping (address => uint256) BNBbought;

    enum status {
      beforeSale,
      ongoingSale,
      postSale
    }

    status public sale_status;

    uint256 public presale_token_per_BNB = 500000000000;  //pre-sale price (500b/1BNB)
    uint256 public public_token_per_BNB = 400000000000; //public pancake listing (400b/1BNB)
    uint256 private init_balance;

    uint256 decimal;
    ERC20 public iBNB_token;
    IUniswapV2Router02 router;

    event Buy(address, uint256, uint256);
    event LiquidityTransferred(uint256, uint256);
    event Claimable(address, uint256, uint256);

    modifier beforeSale() {
      require(sale_status == status.beforeSale, "Sale: already started");
      _;
    }

    modifier ongoingSale() {
      require(sale_status == status.ongoingSale, "Sale: not ongoing");
      _;
    }

    modifier postSale() {
      require(sale_status == status.postSale, "Sale: not in postSale");
      _;
    }

// -- init --

    //@dev set circuit_breaker to true for the duration of the sale
    constructor(address _router, address _ibnb_address) public {
        router = IUniswapV2Router02(_router);
        require(router.WETH() != address(0), 'Router error');
        iBNB_token = ERC20(_ibnb_address);
        decimal = iBNB_token.decimals();
        sale_status = status.beforeSale;
    }

// -- before sale --

    //@dev retain whitelisting capacity during the sale (ie too much "zombies" not coming)
    function addBlockWhitelist(address[50] memory _adr) external onlyOwner {
      for(uint256 i=0; i<256; i++) {
        whitelist[_adr[i]] = true;
      }
    }

// -- Presale launch --

    function startWhitelistSale() external beforeSale onlyOwner {
      sale_status = status.ongoingSale;
      init_balance = iBNB_token.balanceOf(address(this));
    }

// -- Presale flow --

    //@dev contract starts with presale+public
    //     will revert when < 338T token available
    function tokenLeftForSale() public view returns (uint256) {
      return iBNB_token.balanceOf(address(this)).sub(338 * 10**12, "Sale: No more token to sell");
    }


    function buy() external payable ongoingSale {
      require(msg.value.add(BNBbought[msg.sender]) <= 2 * 10**18, "Sale: Above max amount"); // 2 BNB
      require(msg.value >= 2 * 10**17, "Sale: Under min amount"); // 0.2 BNB

      uint256 amountToken = msg.value.mul(presale_token_per_BNB).div(10**18);
      require(amountToken <= tokenLeftForSale(), "Sale: Not enough token left");


      //add to withdrawable[addr]
      BNBbought[msg.sender] = BNBbought[msg.sender].add(msg.value);
      emit Claimable(msg.sender, msg.value, amountToken.mul(10**decimal));
    }

// -- post sale --

    function claim() external postSale {
      //amount = withdrawablr
      uint256 amountToken = BNBbought[msg.sender] * presale_token_per_BNB;
      iBNB_token.transfer(msg.sender, amountToken.mul(10**decimal));
    }

    //@dev convert BNB received and token left in pool liquidity. LP send to owner.
    //     Uni Router handles both scenario : existing and non-existing pair
    //     /!\ will revert if < 1BNB in contract
    //@param TokenPerBNB inital number of token for 1 BNB in the pool
    //@param min_amount_slippage_in_percents min amount for adding liquidity (see uniswap doc)
    //       in case of preexisting pool, if volatiltity++, set to 1% -> max slippage
    function concludeAndAddLiquidity(uint256 TokenPerBNB, uint256 min_amount_slippage_in_percents) external onlyOwner {

      sale_status = status.postSale;

      uint256 balance_BNB = address(this).balance.div(10**18);
      uint256 balance_token = iBNB_token.balanceOf(address(this)).div(10**decimal);

      if(balance_token.div(balance_BNB) >= TokenPerBNB) { // too much token for BNB
         balance_token = TokenPerBNB.mul(balance_BNB);
       }
       else { // too much BNB for token left
         balance_BNB = balance_token.div(TokenPerBNB);
       }

      iBNB_token.approve(address(router), balance_token.mul(10**decimal));
      router.addLiquidityETH{value: balance_BNB.mul(10**18)}(
          address(iBNB_token),
          balance_token.mul(10**decimal),
          balance_token.mul(10**decimal).mul(min_amount_slippage_in_percents).div(100),  //slippage is evitable...
          balance_BNB.mul(10**18).mul(min_amount_slippage_in_percents).div(100),
          owner(),
          block.timestamp
      );

      //burn the non-used tokens
      if(iBNB_token.balanceOf(address(this)) != 0) {
        iBNB_token.transfer(0x000000000000000000000000000000000000dEaD, iBNB_token.balanceOf(address(this)));
      }

      emit LiquidityTransferred(balance_BNB, balance_token);
      //retrieving BNB left (hopefully 0) + gas optimisation
      selfdestruct(payable(msg.sender));
  }


}