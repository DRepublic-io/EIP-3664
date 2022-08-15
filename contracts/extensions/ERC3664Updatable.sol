// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC3664.sol";
import "./IERC3664Updatable.sol";

abstract contract ERC3664Updatable is ERC3664, IERC3664Updatable {
    /**
     * @dev See {IERC3664Updatable-remove}.
     */
    function remove(uint256 tokenId, uint256 attrId) public virtual override {
        require(
            _attrExists(attrId),
            "ERC3664Updatable: remove for nonexistent attribute"
        );
        uint256 amount = attrBalances[attrId][tokenId];
        require(
            amount > 0,
            "ERC3664Updatable: token has not attached the attribute"
        );

        address operator = _msgSender();
        _beforeAttrTransfer(
            operator,
            tokenId,
            0,
            _as3664SingletonArray(attrId),
            _as3664SingletonArray(amount),
            ""
        );

        delete attrBalances[attrId][tokenId];
        _removeByValue(attrs[tokenId], attrId);

        emit TransferSingle(operator, tokenId, 0, attrId, amount);
    }

    /**
     * @dev See {IERC3664Updatable-increase}.
     */
    function increase(
        uint256 tokenId,
        uint256 attrId,
        uint256 amount
    ) public virtual override {
        require(
            _attrExists(attrId),
            "ERC3664Updatable: increase for nonexistent attribute"
        );
        require(
            _hasAttr(tokenId, attrId),
            "ERC3664Updatable: token has not attached the attribute"
        );

        address operator = _msgSender();
        _beforeAttrTransfer(
            operator,
            0,
            tokenId,
            _as3664SingletonArray(attrId),
            _as3664SingletonArray(amount),
            ""
        );

        attrBalances[attrId][tokenId] += amount;

        emit TransferSingle(operator, 0, tokenId, attrId, amount);
    }

    /**
     * @dev See {IERC3664Updatable-decrease}.
     */
    function decrease(
        uint256 tokenId,
        uint256 attrId,
        uint256 amount
    ) public virtual override {
        require(
            _attrExists(attrId),
            "ERC3664Updatable: decrease for nonexistent attribute"
        );
        require(
            _hasAttr(tokenId, attrId),
            "ERC3664Updatable: token has not attached the attribute"
        );

        address operator = _msgSender();
        _beforeAttrTransfer(
            operator,
            tokenId,
            0,
            _as3664SingletonArray(attrId),
            _as3664SingletonArray(amount),
            ""
        );

        uint256 tb = attrBalances[attrId][tokenId];
        require(tb >= amount);
        attrBalances[attrId][tokenId] = tb - amount;

        emit TransferSingle(operator, tokenId, 0, attrId, amount);
    }
}
