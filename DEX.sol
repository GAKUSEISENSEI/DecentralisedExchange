// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Ownable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}



interface IERC20 {
    
    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

}


contract DEX is Pausable {

    bytes32 private KEY;


    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }
    mapping(bytes32 => Token) public tokens;
    bytes32[] public tokenList;


    function setKEY(bytes32 newKEY) external onlyOwner {
    	   KEY = newKEY;
    }



    function addToken(bytes32 ticker, address tokenAddress) onlyOwner external {
        tokens[ticker] = Token(ticker, tokenAddress);
        tokenList.push(ticker);
    }

    function depositETH() public payable onlyOwner{
        require(msg.value > 0);
    }

    function depositToken(uint256 amount, bytes32 ticker) tokenExists(ticker) external onlyOwner{
        IERC20(tokens[ticker].tokenAddress).transferFrom(_msgSender(), address(this), amount);
    }


    function withdraw(uint256 amount, bytes32 ticker) tokenExists(ticker) external onlyOwner{
        require(IERC20(tokens[ticker].tokenAddress).balanceOf(address(this)) >= amount);
        IERC20(tokens[ticker].tokenAddress).transfer(_msgSender(), amount);
    }

    function withdrawEth(uint256 amount) external onlyOwner{
        payable(owner()).transfer(amount);
    }

    function getBalance(bytes32 ticker) tokenExists(ticker) external view returns (uint256) {
        return IERC20(tokens[ticker].tokenAddress).balanceOf(address(this));
    }

    function getTokens() external view returns (bytes32[] memory) {
        return tokenList;
    }

    function swapToken(bytes32 fromTicker, uint256 fromAmount, bytes32 toTicker, uint256 exchangeRate, bytes32 _KEY) tokenExists(fromTicker) tokenExists(toTicker) whenNotPaused external {
        require(_KEY == KEY);
        Token memory fromToken = tokens[fromTicker];
        Token memory toToken = tokens[toTicker];
        uint256 toAmount = (fromAmount * exchangeRate) / 10 ** 6;
        require(IERC20(fromToken.tokenAddress).balanceOf(_msgSender()) >= fromAmount);
        require(IERC20(toToken.tokenAddress).balanceOf(address(this)) >= toAmount);
        IERC20(fromToken.tokenAddress).transferFrom(_msgSender(), address(this), fromAmount);
        IERC20(toToken.tokenAddress).transfer(_msgSender(), toAmount);
    }

    function swapTokenForEth(bytes32 toTicker, uint256 exchangeRate, bytes32 _KEY) tokenExists(toTicker) whenNotPaused external payable {
        require(_KEY == KEY);
        require(msg.value >= 10 ** 14,"Amount too low");
        Token memory toToken = tokens[toTicker];
        uint toAmount = (msg.value * exchangeRate) / 10 ** 18;
        require(IERC20(toToken.tokenAddress).balanceOf(address(this)) >= toAmount);
        IERC20(toToken.tokenAddress).transfer(_msgSender(), toAmount);

    }

    function swapEthForToken(bytes32 fromTicker, uint256 amount, uint256 exchangeRate, bytes32 _KEY) tokenExists(fromTicker) whenNotPaused external {
        require(_KEY == KEY);
        Token memory fromToken = tokens[fromTicker];
        uint toAmount = ((amount * 10 ** 6 / exchangeRate) * 10 ** 18) / 10 ** 6;
        require(IERC20(fromToken.tokenAddress).balanceOf(_msgSender()) >= amount);
        require(address(this).balance >= toAmount);
        IERC20(fromToken.tokenAddress).transferFrom(_msgSender(), address(this), amount);
        payable(_msgSender()).transfer(toAmount);

    }

    modifier tokenExists(bytes32 ticker) {
        require(tokens[ticker].tokenAddress != address(0));
        _;
    }

    
  /**@dev Stops contract functionality
  * Requirements:
  * - contract must not be stopped at current state
  * - caller of the function must be account with granted role
  */

  function pause() public onlyOwner {
      _pause();
  }

  /**@dev Returns contract functionality
  * Requirements:
  * - contract must be stopped at current state
  * - caller of the function must be account with granted role
  */

  function unpause() public onlyOwner {
      _unpause();
  }

}
