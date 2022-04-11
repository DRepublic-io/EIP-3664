// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ISynthetic.sol";

/**
 * @dev Interface of the NFT(ERC721) Synthetic.
 */
interface ISynthetic721 is ISynthetic, IERC721 {

}
