/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

 abstract contract Context {
    function _msgSender() internal view virtual returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
 contract Ownable is Context {
    address private immutable _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract ZESC is Context, IBEP20, Ownable {
   
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
   
    mapping(address => bool) private _isTimeLockedAddress;
    mapping(address => uint256) private _lockedAddressEndTime;
    uint256 private _totalSupply;
    uint8 private immutable _decimals;
    string private _symbol;
    string private _name;
    uint256 private burnAmount;
    bool private burnFlag;

    constructor()  {
        _name = "ZesCoin";
        _symbol = "ZESC";
        _decimals = 18;
        _totalSupply = 5114477611 * 10**18;
        _balances[msg.sender] = _totalSupply;
        burnFlag = false;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function getBurnAmount() external view returns (uint256) {
        return burnAmount;
    }

    function getBurnFlag() external view returns (bool) {
        return burnFlag;
    }

    function transfer(address recipient, uint256 amount) external override
        returns (bool)
    {
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(_msgSender() != recipient, "BEP20: transfer to the self address" );
        require(amount != 0, "BEP20: transfer amount zero");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require(
            spender != address(0),
            "BEP20: spender cannot be the zero address"
        );
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override(IBEP20) returns (bool) {
        require(!_isTimeLockedAddress[sender], "TimeLocked account");
        require(amount != 0, "BEP20: transfer amount zero");
        require(sender != recipient, "BEP20: transfer to the self address");
        _transfer(sender, recipient, amount);
           require(_allowances[sender][_msgSender()] >= amount ,  "BEP20: transfer amount exceeds allowance");
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        require(_allowances[_msgSender()][spender] >= subtractedValue , "BEP20: decreased allowance below zero");
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function setBurnAmount(uint256 newBurnAmount)
        external
        onlyOwner
        returns (uint256)
    {
        burnAmount = newBurnAmount;
        burnFlag = true;
        return burnAmount;
    }

    function setTimeLockAddress(address newTarget, uint256 lockTime)
        external
        onlyOwner
        returns (bool)
    {
     
        require(!_isTimeLockedAddress[newTarget], "Timelocked account");
        _isTimeLockedAddress[newTarget] = true;
        _lockedAddressEndTime[newTarget] = block.timestamp + lockTime;
        return true;
    }

    function unlockTimeLockAddress(address target)
        external
        onlyOwner
        returns (bool)
    {
        require(_isTimeLockedAddress[target], "Not timelocked address");
        _isTimeLockedAddress[target] = false;
        delete _lockedAddressEndTime[target];
        return true;
    }

    function timelockedAddress(address account) external view returns (bool) {
        return _isTimeLockedAddress[account];
    }

    function timelockedDurationAddress(address account)
        external
        view
        returns (uint256)
    {
        require(_isTimeLockedAddress[account], "BEP20: not timelocked address");

        if (block.timestamp < _lockedAddressEndTime[account]) {
            return _lockedAddressEndTime[account] - block.timestamp;
        } else {
            require(
                block.timestamp > _lockedAddressEndTime[account],
                "TimeLock duration end"
            );
            return 0;
        }
    }

    function burn() external onlyOwner returns (bool) {
        _burn(_msgSender(), burnAmount);
        burnFlag = false;
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(!_isTimeLockedAddress[sender], "TimeLocked account");
        require(_balances[sender] >= amount, "BEP20: transfer amount exceeds balance");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;

        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");
        require(burnFlag, "Burn function is locked");
        require(_balances[account] >= amount ,"BEP20: burn amount exceeds balance");
        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}