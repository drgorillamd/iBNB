pragma solidity 0.8.0;
// SPDX-License-Identifier: GPL - @DrGorilla_md (Tg/Twtr)

/*
Supply Breakdown Update:

Total Supply - 1 QT

Burn - 300T
Team - 40T
Marketing - 45T
Private - 27T  
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

  mapping (address => uint256) amountBought;
  mapping (address => bool) whiteListed;

  enum status {
    beforeSale,
    ongoingSale,
    postSale
  }

  status public sale_status;

  uint256 public presale_token_per_BNB = 500;  //pre-sale price (500b/1BNB) AKA (500*10**9*10**9)/10**18
  uint256 public public_token_per_BNB = 400; //public pancake listing (400b/1BNB)
  uint256 public presale_end_ts;
  uint256 private init_balance;
  uint256 private whiteQuota = 27 * 10**12 * 10**9; //27T whitelist
  uint256 private presaleQuota = 250 * 10**12 * 10**9; //250T presale
  uint256 private liquidityQuota = 338 * 10**12 * 10**9;  //338T public
  
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
    require(sale_status == status.ongoingSale, "Sale: already started");
    _;
  }

  modifier postSale() {
    require(sale_status == status.postSale, "Sale: not ended yet");
    _;
  }    //@dev set circuit_breaker to true for the duration of the sale
  constructor(address _router, address _ibnb_address) public {
      router = IUniswapV2Router02(_router);
      require(router.WETH() != address(0), 'Router error');
      iBNB_token = ERC20(_ibnb_address);
      sale_status = status.beforeSale;
  }

// -- before sale --

  //@dev retain whitelisting capacity during the sale (ie too much "zombies" not coming)
  // allowance max is 2BNB, +10**18 to flag whitelisted accounts (ie non-whitelisted == 0)
  // in claim() 
  function addWhitelist(address[] calldata _adr) external onlyOwner {
    for(uint256 i=0; i< _adr.length; i++) {
      if(whiteListed[_adr[i]] == false) {
        whiteListed[_adr[i]] = true;
      }
    }
  }

  function isWhitelisted() external view returns (bool){
    return whiteListed[msg.sender];
  }

  function saleStatus() external view returns(uint256) {
    return uint256(sale_status);
  }

// -- Presale launch --

  function startSale() external beforeSale onlyOwner {
    sale_status = status.ongoingSale;
    init_balance = iBNB_token.balanceOf(address(this));
  }

// -- Presale flow --

  //@dev contract starts with presale+public
  //     will revert when < 338T token available
  function tokenLeftForPrivateSale() public view returns (uint256) {
    return iBNB_token.balanceOf(address(this)).sub(whiteQuota).sub(liquidityQuota, "Private sale: No more token to sell");
  }

  function tokenLeftForWhitelistSale() public view returns (uint256) {
    return iBNB_token.balanceOf(address(this)).sub(presaleQuota).sub(liquidityQuota, "Whitelist sale: No more token to sell");
  }


  function buy() external payable ongoingSale {
    require(msg.value >= 2 * 10**17, "Sale: Under min amount"); // <0.2 BNB
    require(amountBought[msg.sender].add(msg.value) <= 2*10**18, "Sale: above max amount"); // >2bnb

    uint256 amountToken = msg.value.mul(presale_token_per_BNB);


    require(amountToken <= tokenLeftForPrivateSale() || (whiteListed[msg.sender] && amountToken <= tokenLeftForWhitelistSale()), "Sale: Not enough token left");

    amountBought[msg.sender] = amountBought[msg.sender].add(msg.value);
    emit Claimable(msg.sender, msg.value, amountToken);
  }

  function allowanceLeftInBNB() external view returns (uint256) {
    return 2*10**18 - amountBought[msg.sender];
  }
  
  function amountTokenBought() external view returns (uint256) {
    return amountBought[msg.sender].mul(presale_token_per_BNB);
  }


// -- post sale --

  function claim() external postSale {
    require(amountBought[msg.sender] > 0, "0 tokens to claim");
    uint256 amountToken = presale_token_per_BNB.mul(amountBought[msg.sender]);
    amountBought[msg.sender] = 0;
    iBNB_token.transfer(msg.sender, amountToken);
  }

  //@dev convert BNB received and token left in pool liquidity. LP send to owner.
  //     Uni Router handles both scenario : existing and non-existing pair
  //     /!\ will revert if < 1BNB in contract
  // not in postSale scope to avoid having claim and third-party liq before calling it
  function concludeAndAddLiquidity() external onlyOwner {
    uint256 balance_BNB = address(this).balance;
    uint256 balance_token = iBNB_token.balanceOf(address(this));

    if(balance_token > liquidityQuota) balance_token = liquidityQuota; //public capped at liquidityQuota

    if(balance_token.div(balance_BNB) >= public_token_per_BNB) { // too much token for BNB
        balance_token = public_token_per_BNB.mul(balance_BNB);
      }
      else { // too much BNB for token left
        balance_BNB = balance_token.div(public_token_per_BNB);
      }

    iBNB_token.approve(address(router), balance_token);
    router.addLiquidityETH{value: balance_BNB}(
        address(iBNB_token),
        balance_token,
        balance_token,
        balance_BNB,
        owner(),
        block.timestamp
    );

    sale_status = status.postSale;
    presale_end_ts = block.timestamp;

    emit LiquidityTransferred(balance_BNB, balance_token);
      
  }

//@dev wait min 1 week after presale ending, for "late claimers", before destroying the
//contract and emptying it.
  function finalClosure() external onlyOwner {
    require(block.timestamp >= presale_end_ts + 604800, "finalClosure: grace period");

    if(iBNB_token.balanceOf(address(this)) != 0) {
      iBNB_token.transfer(msg.sender, iBNB_token.balanceOf(address(this)));
    }

    selfdestruct(payable(msg.sender));
  }

}
