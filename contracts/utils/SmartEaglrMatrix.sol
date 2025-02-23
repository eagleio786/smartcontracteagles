// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SmartEaglrMatrixV1 is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public USDTAddress;
    address public id1;
    uint256 public constant LAST_LEVEL = 12;
    uint256 public constant LEVEL_1_PRICE = 2.5 * 1e18;  
    address public systemRecipentAddress = 0x6d1695e8Ed58dd50AD8EFa4F01E93F0D5967230B;

    struct User {
        address referrer;
        uint256 id;
        uint256 currentX1Level;
        uint256 currentX2Level;
        uint256 totalUSDTReceived;
        mapping(uint256 => bool) activeX1Levels;
        mapping(uint256 => bool) activeX2Levels;
        mapping(uint256 => uint256) x1SlotCount;
        mapping(uint256 => uint256) x2SlotCount;
        mapping(uint256 => uint256) X1recicle;
        mapping(uint256 => uint256) X2recicle;
    }

    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;
    uint256 lastUserId = 1;

    event UserRegistered(
        address indexed user,
        address indexed referrer,
        uint256 id
    );

    event LevelActivated(address indexed user, uint8 matrix, uint256 level);
    event FundsDistributed(
        address indexed from,
        address indexed to,
        uint8 matrix,
        uint256 level,
        uint256 amount
    );
    event SlotFilled(
        address indexed user,
        uint8 matrix,
        uint256 level,
        uint256 slotsFilled
    );

    constructor(address _usdtAddress) Ownable(systemRecipentAddress) {
        require(_usdtAddress != address(0));
        USDTAddress = IERC20(_usdtAddress);
        id1 = 0x31eaCE9383eE97A5cF2FD6A1B254F27683DedE1B;

        // Initialize ID1
        users[id1].referrer = address(0);
        users[id1].id = lastUserId++;
        users[id1].currentX1Level = LAST_LEVEL;
        users[id1].currentX2Level = LAST_LEVEL;
        idToAddress[users[id1].id] = id1;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[id1].activeX1Levels[i] = true;
            users[id1].activeX2Levels[i] = true;
        }
    }

    function register(address referrer) external {
        require(!isUserExists(msg.sender), "User exists");
        require(
            isUserExists(referrer) || referrer == address(0),
            "Invalid referrer"
        );

        USDTAddress.safeTransferFrom(
            msg.sender,
            address(this),
            LEVEL_1_PRICE * 2
        );

        if (referrer == address(0)) referrer = id1;

        users[msg.sender].referrer = referrer;
        users[msg.sender].id = lastUserId++;
        users[msg.sender].currentX1Level = 1;
        users[msg.sender].currentX2Level = 1;
        users[msg.sender].totalUSDTReceived = 0;
        idToAddress[users[msg.sender].id] = msg.sender;

        users[msg.sender].activeX1Levels[1] = true;
        users[msg.sender].activeX2Levels[1] = true;

        _updateX1lvl(msg.sender, 1, LEVEL_1_PRICE);
        _updateX2lvl(msg.sender, 1, LEVEL_1_PRICE);

        emit UserRegistered(msg.sender, referrer, users[msg.sender].id);
    }

    function activateLevel(uint8 matrix, uint256 level) external {
        require(isUserExists(msg.sender), "Register First");
        require(level > 0 && level <= LAST_LEVEL, "Invalid level");
        if (matrix == 1) {
            require(
                level == users[msg.sender].currentX1Level + 1,
                "Can only activate next level"
            );
        } else {
            require(
                level == users[msg.sender].currentX2Level + 1,
                "Can only activate next level"
            );
        }

        uint256 price = LEVEL_1_PRICE * (2**(level - 1));

        if (matrix == 1) {
            require(!users[msg.sender].activeX1Levels[level], "Level active");
            USDTAddress.safeTransferFrom(msg.sender, address(this), price);
            users[msg.sender].activeX1Levels[level] = true;
            if (level > users[msg.sender].currentX1Level) {
                users[msg.sender].currentX1Level = level;
            }
            _updateX1lvl(msg.sender, level, price);
        } else {
            require(!users[msg.sender].activeX2Levels[level], "Level active");
            USDTAddress.safeTransferFrom(msg.sender, address(this), price);
            users[msg.sender].activeX2Levels[level] = true;
            if (level > users[msg.sender].currentX2Level) {
                users[msg.sender].currentX2Level = level;
            }
            _updateX2lvl(msg.sender, level, price);
        }

        emit LevelActivated(msg.sender, matrix, level);
    }

    function _updateX1lvl(
        address user,
        uint256 level,
        uint256 amount
    ) private {
        address referrer = users[user].referrer;
        if (referrer == id1) {
            //simple transfer to id 1
            uint256 _slot = users[id1].x1SlotCount[level] % 4;
            _transferToID1(user, level, _slot, amount);
            return;
        } else {
            // For other referrers
            uint256 _slot = users[referrer].x1SlotCount[level] % 4; // Correct referrer's slot count
            referrer = _findActiveReferrer(user, 1, level);
            address receiver;
            if (_slot < 3) {
                // Slots 1-3: Direct referrer
                receiver = referrer;
                USDTAddress.safeTransfer(receiver, amount);
                emit FundsDistributed(user, receiver, 1, level, amount);
                users[receiver].totalUSDTReceived += amount;

                users[referrer].x1SlotCount[level]++;
                emit SlotFilled(
                    referrer,
                    1,
                    level,
                    users[referrer].x1SlotCount[level]
                );
            } else {
                // Slot 4: Parent of referrer
                receiver = _findActiveReferrer(referrer, 1, level);
                USDTAddress.safeTransfer(receiver, amount);
                emit FundsDistributed(user, receiver, 1, level, amount);
                users[receiver].totalUSDTReceived += amount;

                users[referrer].x1SlotCount[level]++;
                emit SlotFilled(
                    referrer,
                    1,
                    level,
                    users[referrer].x1SlotCount[level]
                );
            }
        }
        if (users[referrer].x1SlotCount[level] == 4) {
            users[referrer].activeX1Levels[level] = false;
            users[referrer].x1SlotCount[level] = 0;
            users[referrer].X1recicle[level] += 1;
        }
        return;
    }

    function _transferToID1(
        address user,
        uint256 level,
        uint256 _slot,
        uint256 amount
    ) internal {
        if (_slot < 3) {
            // Slots 1-3: Direct to ID1
            USDTAddress.safeTransfer(id1, amount);
            emit FundsDistributed(user, id1, 1, level, amount);
            users[id1].totalUSDTReceived += amount;
            users[id1].x1SlotCount[level]++;
            emit SlotFilled(id1, 1, level, users[id1].x1SlotCount[level]);
        } else {
            // Slot 4: To systemRecipentAddress
            USDTAddress.safeTransfer(systemRecipentAddress, amount);
            emit FundsDistributed(
                user,
                systemRecipentAddress,
                1,
                level,
                amount
            );
            users[id1].x1SlotCount[level] = 0;
            users[id1].X1recicle[level] += 1;
            emit SlotFilled(id1, 1, level, users[id1].x1SlotCount[level]);
        }

        return;
    }

    function _updateX2lvl(
        address user,
        uint256 level,
        uint256 amount
    ) private {
        address referrer = _findActiveReferrer(user, 2, level);
        uint256 slot = users[referrer].x2SlotCount[level] % 4;

        if (slot == 0) {
            _handleSlot0Distribution(user, level, amount);
        } else if (slot == 1 || slot == 2) {
            USDTAddress.safeTransfer(referrer, amount);
            emit FundsDistributed(user, referrer, 2, level, amount);
            users[referrer].totalUSDTReceived += amount;
        } else {
            _handleSlot4DistributionX2(user, level, amount, referrer);
        }

        users[referrer].x2SlotCount[level]++;
        emit SlotFilled(referrer, 2, level, users[referrer].x2SlotCount[level]);

        if (users[referrer].x2SlotCount[level] == 4) {
            users[referrer].activeX2Levels[level] = false;
            users[referrer].x2SlotCount[level] = 0;
            users[referrer].X2recicle[level] += 1;
        }
        return;
    }

    function _handleSlot0Distribution(
        address user,
        uint256 level,
        uint256 amount
    ) private {
        uint256 memberShare = (amount * 20) / 100; // 20% per member
        uint256 distributed = 0;

        (address[3] memory randomUser, ) = getValidRandomUser(user, level);

        for (uint256 i; i < 3; i++) {
            USDTAddress.safeTransfer(randomUser[i], memberShare);
            emit FundsDistributed(user, randomUser[i], 2, level, memberShare);
            users[randomUser[i]].totalUSDTReceived += memberShare;
            distributed += memberShare;
        }

        // Send remaining funds to the system
        uint256 remaining = amount - distributed;
        USDTAddress.safeTransfer(systemRecipentAddress, remaining);
        emit FundsDistributed(user, systemRecipentAddress, 2, level, remaining);
    }

    function getValidRandomUser(address excluded, uint256 level)
        internal
        view
        returns (address[3] memory _addresss, uint256[3] memory _randomIds)
    {
        address[3] memory candidate;
        uint256[3] memory randomIds;
        uint256 maxAttempts = 5;

        for (uint256 i = 0; i < 3; i++) {
            uint256 randomId;
            bool isInvalid;
            uint256 attempts = 0;

            do {
                // Generate random ID with unique nonce
                uint256 nonce = i * maxAttempts + attempts;
                randomId = _generateRandomNumber(lastUserId - 1, nonce);

                isInvalid = false;

                // Check duplicates
                for (uint256 j = 0; j < i; j++) {
                    if (randomIds[j] == randomId) {
                        isInvalid = true;
                        break;
                    }
                }

                // Check excluded address and validity
                address candidateAddress = idToAddress[randomId];
                if (
                    candidateAddress == excluded || candidateAddress == address(0)
                ) {
                    isInvalid = true;
                }

                attempts++;
            } while (isInvalid && attempts < maxAttempts);

            // Handle invalid cases
            if (isInvalid) {
                candidate[i] = systemRecipentAddress;
                randomIds[i] = 0;
            } else {
                randomIds[i] = randomId;
                candidate[i] = idToAddress[randomId];

                // Existing lock check
                if (isLocked(candidate[i], 2, level)) {
                    candidate[i] = _findActiveReferrer(candidate[i], 2, level);
                }
            }
        }

        return (candidate, randomIds);
    }

    // Updated random generator with nonce
    function _generateRandomNumber(uint256 max, uint256 nonce)
        internal
        view
        returns (uint256)
    {
        require(max > 0, "Max must be greater than 0");
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    nonce, // Unique per call
                    block.prevrandao,
                    block.timestamp,
                    block.number,
                    msg.sender
                )
            )
        );
        return (random % max) + 1;
    }

    function _handleSlot4DistributionX2(
        address user,
        uint256 level,
        uint256 amount,
        address referrer
    ) internal {
        uint256 uplinershare = (amount * 20) / 100; // 20% per member
        if (referrer == id1) {
            uint256 systemshare = amount - uplinershare;
            USDTAddress.safeTransfer(referrer, uplinershare);
            USDTAddress.safeTransfer(systemRecipentAddress, systemshare);
            emit FundsDistributed(
                user,
                systemRecipentAddress,
                2,
                level,
                amount
            );
            users[referrer].totalUSDTReceived += systemshare;
            return;
        } else {
            address receiver = referrer;
            uint256 _systemshare = (amount * 40) / 100;
            for (int256 i = 0; i < 3; i++) {
                USDTAddress.safeTransfer(receiver, uplinershare);
                users[receiver].totalUSDTReceived += uplinershare;
                receiver = _findActiveReferrer(receiver, 2, level);
                emit FundsDistributed(user, receiver, 2, level, uplinershare);
            }

            USDTAddress.safeTransfer(systemRecipentAddress, _systemshare);
            emit FundsDistributed(
                user,
                systemRecipentAddress,
                2,
                level,
                amount
            );
            return;
        }
    }

    function lastUserid() public view returns (uint256 id) {
        return lastUserId;
    }

    function _findActiveReferrer(
        address user,
        uint8 matrix,
        uint256 level
    ) public view returns (address) {
        address referrer = users[user].referrer;

        for (uint8 i = 0; i < 5; i++) {
            // Check if the referrer is active for the given matrix and level
            bool isActive = (matrix == 1)
                ? users[referrer].activeX1Levels[level]
                : users[referrer].activeX2Levels[level];

            if (isActive) {
                return referrer;  
            }

            referrer = users[referrer].referrer;
        }

        return systemRecipentAddress;
    }

    // View and helper functions
    function isUserExists(address user) public view returns (bool) {
        return users[user].id != 0;
    }

    function getSlotsFilled(
        address user,
        uint8 matrix,
        uint256 level
    ) public view returns (uint256 _solts, uint256 _recicle) {
        return
            matrix == 1
                ? (users[user].x1SlotCount[level], users[user].X1recicle[level])
                : (
                    users[user].x2SlotCount[level],
                    users[user].X2recicle[level]
                );
    }

    function isLocked(
        address user,
        uint8 matrix,
        uint256 level
    ) public view returns (bool) {
        return
            matrix == 1
                ? !users[user].activeX1Levels[level]
                : !users[user].activeX2Levels[level];
    }

    // Admin functions
    function withdrawUSDT(address _reciver,uint256 amount) external onlyOwner {
        require(_reciver != address(0), "Invalid token address");
        USDTAddress.safeTransfer(_reciver, amount);
    }

    function updateToken(IERC20 _token) external onlyOwner {
        require(address(_token) != address(0), "Invalid token address");
        USDTAddress = _token;
    }

    function updateID1(address _newID1Addres) external onlyOwner {
        require(_newID1Addres != address(0), "Invalid token address");
        id1 = _newID1Addres;
    }

    function updateSystemRecipentAddress(address _systemRecipentAddress) external onlyOwner {
        require(_systemRecipentAddress != address(0), "Invalid token address");
        systemRecipentAddress=_systemRecipentAddress;
    }
}