// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC3664 compliant contract.
 */
interface IERC3664 is IERC165 {
    /**
     * @dev Emitted when new attribute type `attrId` are minted.
     */
    event AttributeCreated(
        uint256 indexed attrId,
        string name,
        string symbol,
        string uri
    );

    /**
     * @dev Emitted when `value` of attribute type `attrId` are attached to "to"
     * or removed from `from` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        uint256 from,
        uint256 to,
        uint256 indexed attrId,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events.
     */
    event TransferBatch(
        address indexed operator,
        uint256 from,
        uint256 to,
        uint256[] indexed attrIds,
        uint256[] values
    );

    /**
     * @dev Returns primary attribute type of owned by `tokenId`.
     */
    function primaryAttributeOf(uint256 tokenId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns all attribute types of owned by `tokenId`.
     */
    function attributesOf(uint256 tokenId)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the attribute type `attrId` value owned by `tokenId`.
     */
    function balanceOf(uint256 tokenId, uint256 attrId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the batch of attribute type `attrIds` values owned by `tokenId`.
     */
    function balanceOfBatch(uint256 tokenId, uint256[] calldata attrIds)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Set primary attribute type of owned by `tokenId`.
     */
    function setPrimaryAttribute(uint256 tokenId, uint256 attrId) external;

    /**
     * @dev Attaches `amount` value of attribute type `attrId` to `tokenId`.
     */
    function attach(
        uint256 tokenId,
        uint256 attrId,
        uint256 amount
    ) external;

    /**
     * @dev [Batched] version of {attach}.
     */
    function batchAttach(
        uint256 tokenId,
        uint256[] calldata attrIds,
        uint256[] calldata amounts
    ) external;
}
