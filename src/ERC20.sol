// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC20 {

    string public name;
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public owner;
    bool public paused = false;

    mapping(address => uint256) public balance_of;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Paused(address account);
    event Unpaused(address account);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "token transfer while paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "token transfer while not paused");
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;

        mint(owner, 100 ether); // 컨트랙트 생성 시 초기 공급량 발행

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {// 토큰 전송을 수행
        require(balance_of[msg.sender] >= value, "transfer amount exceeds balance error!");
        balance_of[msg.sender] -= value;
        balance_of[to] += value;
        emit Transfer(msg.sender, to, value);
        return true; 
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {// 토큰 사용을 승인
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; 
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {// 승인된 토큰을 전송
        require(balance_of[from] >= value, "transfer amount exceeds balance error!");
        require(allowance[from][msg.sender] >= value, "transfer amount exceeds allowance error!");
        
        balance_of[from] -= value;
        balance_of[to] += value;
        allowance[from][msg.sender] -= value;
        
        emit Transfer(from, to, value);
        return true; 
    }

    function permit(
        address _owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp <= deadline, "expired deadline error!");

        bytes32 structHash = keccak256(abi.encode(
            PERMIT_TYPEHASH,
            _owner,
            spender,
            value,
            nonces[_owner]++,
            deadline
        ));

        bytes32 hash = _toTypedDataHash(structHash);
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == _owner, "INVALID_SIGNER");

        allowance[_owner][spender] = value;
        emit Approval(_owner, spender, value); // 서명 기반으로 승인
    }

    function _toTypedDataHash(bytes32 structHash) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)); // EIP-712 형식으로 해시 생성
    }

    function pause() public onlyOwner whenNotPaused {// 토큰 전송을 일시 중지
        paused = true;
        emit Paused(msg.sender); 
    }

    function unpause() public onlyOwner whenPaused {// 토큰 전송을 다시 활성화
        paused = false;
        emit Unpaused(msg.sender); 
    }

    function mint(address to, uint256 value) public onlyOwner {// 새로운 토큰을 발행
        totalSupply += value;
        balance_of[to] += value;
        emit Transfer(address(0), to, value); 
    }
}
