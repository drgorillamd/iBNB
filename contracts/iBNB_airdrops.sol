pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract iBNB_airdrop is Ownable {

    IERC20 iBNB_contract;
    uint256 init_balance;

    constructor (address _contract) {
        iBNB_contract = IERC20(_contract);
    }

    function send_airdrop(address[] calldata _receivers, uint256[] calldata _balances) external onlyOwner {
        iBNB_contract.approve(address(this), ~uint256(0));
        for(uint256 i = 0; i<_receivers.length; i++) {
            iBNB_contract.transferFrom(msg.sender, _receivers[i], _balances[i]);
        }
        selfdestruct(payable(msg.sender));
    }

}
