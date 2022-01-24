pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../lib/Upgradeable.sol";
import "../interfaces/ILand.sol";
import "../lib/SignerRecover.sol";
import "../lib/BlackholePreventionUpgradeable.sol";

contract LandSale is Upgradeable,
    BlackholePreventionUpgradeable,
    SignerRecover

{
    using AddressUpgradeable for address payable;
    ILand public land;
    mapping(address => bool) public acceptToken;
    address public constant nativeToken =
        0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    address public operator;
    uint256 public maxLandId;
    uint256 public maxBoxNumber;
    uint256 public currentBoxNumber;

    event BuyBox(
        address buyer,
        address tokenPayment,
        uint256 tokenAmount,
        uint256 boxNumber
    );
    event BuyBoxMultiToken(
        address buyer,
        bytes tokenPayment,
        bytes tokenAmount,
        uint256 boxNumber
    );
    event OpenBox(address buyer, uint256 tokenId, bytes32 landName);

    struct OpenLandInfo {
        bytes32 package;
        uint256 tokenId;
        bytes32 landName;
    }
    mapping(address => uint256) public buyerBoxNumber;
    mapping(address => uint256) public buyerBoxOpen;
    mapping(bytes32 => bool) public useKeys;

    function initialize(ILand _land) external initializer {
        initOwner();

        land = _land;
        maxLandId = 1;
    }

    function setLandAddress(ILand _land) public onlyOwner {
        land = _land;
    }

    function setMaxLandId(uint256 max) public onlyOwner {
        maxLandId = max;
    }

    function setMaxBoxNumber(uint256 max) public onlyOwner {
        maxBoxNumber = max;
    }

    function addTokenAccept(address _token, bool _value) public onlyOwner {
        acceptToken[_token] = _value;
    }

    function setOperator(address _operator) public onlyOwner {
        operator = _operator;
    }

    function buyBox(
        bytes32 _key,
        address _tokenPayment,
        uint256 _tokenAmount,
        uint256 _boxNumber,
        uint256 _expiryTime,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external payable {
        bytes32 msgHash = keccak256(
            abi.encode(
                msg.sender,
                _key,
                _tokenPayment,
                _tokenAmount,
                _boxNumber,
                _expiryTime
            )
        );
        require(
            operator == recoverSigner(r, s, v, msgHash),
            "!invalid operator"
        );
        require(maxBoxNumber > currentBoxNumber, "reached the limit");
        require(!useKeys[_key], "!invalid key");
        useKeys[_key] = true;
        currentBoxNumber = currentBoxNumber + 1;
        if (_tokenPayment == nativeToken) {
            require(msg.value == _tokenAmount, "Not enough BNB");
        } else {
            IERC20Upgradeable(_tokenPayment).transferFrom(
                msg.sender,
                address(this),
                _tokenAmount
            );
        }

        buyerBoxNumber[msg.sender] = buyerBoxNumber[msg.sender] + _boxNumber;
        emit BuyBox(msg.sender, _tokenPayment, _tokenAmount, _boxNumber);
    }

    function buyBoxMultiToken(
        bytes32 _key,
        address[] memory _tokenPayment,
        uint256[] memory _tokenAmount,
        uint256 _boxNumber,
        uint256 _expiryTime,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external payable {
        require(_tokenPayment.length == _tokenAmount.length, "invalid length");
        bytes32 msgHash = keccak256(
            abi.encode(
                msg.sender,
                _tokenPayment,
                _tokenAmount,
                _boxNumber,
                _expiryTime
            )
        );
        require(
            operator == recoverSigner(r, s, v, msgHash),
            "invalid operator"
        );
        require(maxBoxNumber > currentBoxNumber, "reached the limit");
        require(!useKeys[_key], "invalid key");
        useKeys[_key] = true;
        currentBoxNumber = currentBoxNumber + 1;
        for (uint256 i = 0; i < _tokenPayment.length; i++) {
            if (_tokenPayment[i] == nativeToken) {
                require(msg.value == _tokenAmount[i], "Not enough BNB");
            } else {
                IERC20Upgradeable(_tokenPayment[i]).transferFrom(
                    msg.sender,
                    address(this),
                    _tokenAmount[i]
                );
            }
        }

        buyerBoxNumber[msg.sender] = buyerBoxNumber[msg.sender] + _boxNumber;
        emit BuyBoxMultiToken(
            msg.sender,
            abi.encodePacked(_tokenPayment),
            abi.encodePacked(_tokenAmount),
            _boxNumber
        );
    }

    function countNotOpenBox(address buyer) public view returns (uint256) {
        return buyerBoxNumber[buyer] - buyerBoxOpen[buyer];
    }

    function openBox(
        bytes32 _key,
        bytes32 landName,
        uint256 _expiryTime,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        require(
            buyerBoxOpen[msg.sender] < buyerBoxNumber[msg.sender],
            "Dont have any box"
        );
        require(!useKeys[_key], "invalid key");
        useKeys[_key] = true;

        bytes32 msgHash = keccak256(
            abi.encode(msg.sender, landName, _expiryTime)
        );
        require(
            operator == recoverSigner(r, s, v, msgHash),
            "invalid operator"
        );

        buyerBoxOpen[msg.sender] = buyerBoxOpen[msg.sender] + 1;
        land.mint(msg.sender, maxLandId);

        emit OpenBox(msg.sender, maxLandId, landName);
        maxLandId = maxLandId + 1;
    }

    function claimLandFromOther(
        bytes32 _key,
        bytes32 landName,
        uint256 _expiryTime,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        bytes32 msgHash = keccak256(
            abi.encode(msg.sender, _key, landName, _expiryTime)
        );
        require(
            operator == recoverSigner(r, s, v, msgHash),
            "invalid operator"
        );
        require(!useKeys[_key], "invalid key");
        useKeys[_key] = true;

        land.mint(msg.sender, maxLandId);

        emit OpenBox(msg.sender, maxLandId, landName);
        maxLandId = maxLandId + 1;
    }

    function withdrawEther(address payable receiver, uint256 amount)
        external
        virtual
        onlyOwner
    {
        _withdrawEther(receiver, amount);
    }

    function withdrawERC20(
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) external virtual onlyOwner {
        _withdrawERC20(receiver, tokenAddress, amount);
    }

    function withdrawERC721(
        address payable receiver,
        address tokenAddress,
        uint256 tokenId
    ) external virtual onlyOwner {
        _withdrawERC721(receiver, tokenAddress, tokenId);
    }
}
