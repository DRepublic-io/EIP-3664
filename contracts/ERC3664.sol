// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC3664.sol";
import "./extensions/IERC3664Metadata.sol";

contract ERC3664 is Context, ERC165, IERC3664, IERC3664Metadata {
    using Strings for uint256;

    struct AttrMetadata {
        string name;
        string symbol;
        string uri;
        bool exist;
    }

    // Used as the URI for all attribute types by relying on ID substitution, e.g. https://attr-cdn-domain/{id}.json
    string private _baseUri;
    // attrId => metadata
    mapping(uint256 => AttrMetadata) private _attrMetadatas;
    // attrId => tokenId => amount
    mapping(uint256 => mapping(uint256 => uint256)) public attrBalances;
    // tokenId => primary attribute Id
    mapping(uint256 => uint256) private _primaryAttrs;
    // tokenId => all attached attributes
    mapping(uint256 => uint256[]) public attrs;

    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC3664).interfaceId ||
            interfaceId == type(IERC3664Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC3664Metadata-name}.
     */
    function name(uint256 attrId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _attrExists(attrId),
            "ERC3664: name query for nonexistent attribute"
        );

        return _attrMetadatas[attrId].name;
    }

    /**
     * @dev See {IERC3664Metadata-symbol}.
     */
    function symbol(uint256 attrId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _attrExists(attrId),
            "ERC3664: symbol query for nonexistent attribute"
        );

        return _attrMetadatas[attrId].symbol;
    }

    /**
     * @dev See {IERC721Metadata-attrURI}.
     */
    function attrURI(uint256 attrId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _attrExists(attrId),
            "ERC3664: URI query for nonexistent attribute"
        );

        string memory uri = _attrMetadatas[attrId].uri;
        if (bytes(uri).length > 0) {
            return string(abi.encodePacked(uri, attrId.toString()));
        } else {
            return
                bytes(_baseUri).length > 0
                    ? string(abi.encodePacked(_baseUri, attrId.toString()))
                    : "";
        }
    }

    /**
     * @dev See {IERC3664-primaryAttributeOf}.
     */
    function primaryAttributeOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _primaryAttrs[tokenId];
    }

    /**
     * @dev See {IERC3664-setPrimaryAttribute}.
     */
    function setPrimaryAttribute(uint256 tokenId, uint256 attrId)
        public
        virtual
        override
    {
        require(
            _hasAttr(tokenId, attrId),
            "ERC3664: token has not attached the attribute"
        );

        _primaryAttrs[tokenId] = attrId;
    }

    /**
     * @dev See {IERC3664-attributesOf}.
     */
    function attributesOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        return attrs[tokenId];
    }

    /**
     * @dev See {IERC3664-balanceOf}.
     */
    function balanceOf(uint256 tokenId, uint256 attrId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return attrBalances[attrId][tokenId];
    }

    /**
     * @dev See {IERC3664-balanceOfBatch}.
     */
    function balanceOfBatch(uint256 tokenId, uint256[] calldata attrIds)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256[] memory batchBalances = new uint256[](attrIds.length);

        for (uint256 i = 0; i < attrIds.length; ++i) {
            batchBalances[i] = balanceOf(tokenId, attrIds[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC3664-attach}.
     */
    function attach(
        uint256 tokenId,
        uint256 attrId,
        uint256 amount
    ) public virtual override {
        require(
            _attrExists(attrId),
            "ERC3664: attach for nonexistent attribute"
        );

        address operator = _msgSender();

        _beforeAttrTransfer(
            operator,
            0,
            tokenId,
            _asSingletonArray(attrId),
            _asSingletonArray(amount),
            ""
        );

        if (attrBalances[attrId][tokenId] == 0) {
            attrs[tokenId].push(attrId);
        }

        attrBalances[attrId][tokenId] += amount;

        emit TransferSingle(operator, 0, tokenId, attrId, amount);
    }

    /**
     * @dev See {IERC3664-batchAttach}.
     */
    function batchAttach(
        uint256 tokenId,
        uint256[] calldata attrIds,
        uint256[] calldata amounts
    ) public virtual override {
        address operator = _msgSender();

        _beforeAttrTransfer(operator, 0, tokenId, attrIds, amounts, "");

        for (uint256 i = 0; i < attrIds.length; i++) {
            require(
                _attrExists(attrIds[i]),
                "ERC3664: batchAttach for nonexistent attribute"
            );

            if (attrBalances[attrIds[i]][tokenId] == 0) {
                attrs[tokenId].push(attrIds[i]);
            }

            attrBalances[attrIds[i]][tokenId] += amounts[i];
        }

        emit TransferBatch(operator, 0, tokenId, attrIds, amounts);
    }

    /**
     * @dev Mint new attribute type with metadata.
     *
     * Emits a {NewAttribute} event.
     */
    function _mint(
        uint256 attrId,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) internal virtual {
        require(!_attrExists(attrId), "ERC3664: attribute already exists");

        AttrMetadata memory data = AttrMetadata(_name, _symbol, _uri, true);
        _attrMetadatas[attrId] = data;

        emit AttributeCreated(attrId, _name, _symbol, _uri);
    }

    /**
     * @dev [Batched] version of {_mint}.
     */
    function _mintBatch(
        uint256[] memory attrIds,
        string[] memory names,
        string[] memory symbols,
        string[] memory uris
    ) internal virtual {
        require(
            attrIds.length == names.length,
            "ERC3664: attrIds and names length mismatch"
        );
        require(
            names.length == symbols.length,
            "ERC3664: names and symbols length mismatch"
        );
        require(
            symbols.length == uris.length,
            "ERC3664: symbols and uris length mismatch"
        );

        for (uint256 i = 0; i < attrIds.length; i++) {
            _mint(attrIds[i], names[i], symbols[i], uris[i]);
        }
    }

    /**
     * @dev Destroys `amount` values of attribute type `attrId` from `tokenId`
     */
    function _burn(
        uint256 tokenId,
        uint256 attrId,
        uint256 amount
    ) internal virtual {
        address operator = _msgSender();

        _beforeAttrTransfer(
            operator,
            tokenId,
            0,
            _asSingletonArray(attrId),
            _asSingletonArray(amount),
            ""
        );

        uint256 tokenBalance = attrBalances[attrId][tokenId];
        require(
            tokenBalance >= amount,
            "ERC3664: insufficient balance for transfer"
        );
        unchecked {
            attrBalances[attrId][tokenId] = tokenBalance - amount;
        }

        emit TransferSingle(operator, tokenId, 0, attrId, amount);
    }

    /**
     * @dev [Batched] version of {_burn}.
     */
    function _burnBatch(
        uint256 tokenId,
        uint256[] memory attrIds,
        uint256[] memory amounts
    ) internal virtual {
        require(
            attrIds.length == amounts.length,
            "ERC3664: attrIds and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeAttrTransfer(operator, tokenId, 0, attrIds, amounts, "");

        for (uint256 i = 0; i < attrIds.length; i++) {
            uint256 tokenBalance = attrBalances[attrIds[i]][tokenId];
            require(
                tokenBalance >= amounts[i],
                "ERC3664: insufficient balance for transfer"
            );
            unchecked {
                attrBalances[attrIds[i]][tokenId] = tokenBalance - amounts[i];
            }
        }

        emit TransferBatch(operator, tokenId, 0, attrIds, amounts);
    }

    /**
     * @dev Hook that is called before any attribute transfer. This includes attaching
     * and removing, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * attaches, the length of the `attrIds` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `attrIds` and `amounts` pair):
     */
    function _beforeAttrTransfer(
        address operator,
        uint256 from,
        uint256 to,
        uint256[] memory attrIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Sets a new URI for all attribute types
     *
     * If set, the resulting URI for each
     * attribute will be the concatenation of the `_baseUri` and the `attrId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _setURI(string memory newuri) internal virtual {
        _baseUri = newuri;
    }

    /**
     * @dev Returns whether `attrId` exists.
     *
     * Attribute start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _attrExists(uint256 attrId) internal view returns (bool) {
        return _attrMetadatas[attrId].exist;
    }

    function _hasAttr(uint256 tokenId, uint256 attrId)
        internal
        view
        returns (bool)
    {
        return attrBalances[attrId][tokenId] > 0;
    }

    function _asSingletonArray(uint256 element)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function _removeByValue(uint256[] storage values, uint256 value) internal {
        uint256 i = 0;
        while (values[i] != value) {
            i++;
        }
        delete values[i];
    }
}
