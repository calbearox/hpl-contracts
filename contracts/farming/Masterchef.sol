// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "../token/HPL.sol";
// import "../lib/SignerRecover.sol";
// import "../interfaces/INFTStakingPoint.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// // "@openzeppelin/contracts/proxy/utils/Initializable.sol";

// // interface IMigratorChef {
// //     // Perform LP token migration from legacy UniswapV2 to HPL.
// //     // Take the current LP token address and return the new LP token address.
// //     // Migrator should have full access to the caller's LP token.
// //     // Return the new LP token address.
// //     //
// //     // XXX Migrator must have allowance access to UniswapV2 LP tokens.
// //     //  must mint EXACTLY the same amount of  LP tokens or
// //     // else something bad will happen. Traditional UniswapV2 does not
// //     // do that so be careful!
// //     function migrate(IERC20 token) external returns (IERC20);
// // }

// // MasterChef is the master of HPL. He can make HPL and he is a fair guy.
// //
// // Note that it's ownable and the owner wields tremendous power. The ownership
// // will be transferred to a governance smart contract once HPL is sufficiently
// // distributed and the community can show to govern itself.
// //
// // Have fun reading it. Hopefully it's bug-free. God bless.
// contract MasterChef is Ownable, SignerRecover, Initializable {
//     using SafeMath for uint256;
//     using SafeERC20 for IERC20;
//     // Info of each user.
//     struct UserInfo {
//         uint256 amount; // How many LP tokens the user has provided.
//         uint256 rewardDebt; // Reward debt. See explanation below.
//         uint256 nftPoint;
//         uint256[] stakedNFTs;
//         mapping(uint256 => uint256) nftDepositPoint;
//         uint256 lastNFTDepositTimestamp;
//         //
//         // We do some fancy math here. Basically, any point in time, the amount of HPL
//         // entitled to a user but is pending to be distributed is:
//         //
//         //   pending reward = (user.amount * pool.accHPLPerShare) - user.rewardDebt
//         //
//         // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
//         //   1. The pool's `accHPLPerShare` (and `lastRewardBlock`) gets updated.
//         //   2. User receives the pending reward sent to his/her address.
//         //   3. User's `amount` gets updated.
//         //   4. User's `rewardDebt` gets updated.
//     }
//     // Info of each pool.
//     struct PoolInfo {
//         IERC20 lpToken; // Address of LP token contract., address is 0 if it is NFT pool
//         uint256 allocPoint; // How many allocation points assigned to this pool. HPLPoint to distribute per block.
//         uint256 lastRewardBlock; // Last block number that HPLPoint distribution occurs.
//         uint256 accHPLPerShare; // Accumulated HPLPoint per share, times 1e12. See below.
//         uint256 totalNFTPoint;
//     }
//     // The HPL TOKEN!
//     HPL public hpl;
//     IERC721 public nft;
//     INFTStakingPoint public nftStakingPointHook;
//     uint256 public lockedTime = 12 hours;

//     // the token rewards container

//     // Dev address.
//     // Block number when bonus HPL period ends.
//     uint256 public bonusEndBlock;
//     // HPL tokens created per block.
//     uint256 public hplPerBlock;
//     // Bonus muliplier for early HPL makers.
//     uint256 public constant BONUS_MULTIPLIER = 3;
//     // The migrator contract. It has a lot of power. Can only be set through governance (owner).
//     //IMigratorChef public migrator;
//     // Info of each pool.
//     PoolInfo[] public poolInfo;
//     // Info of each user that stakes LP tokens.
//     mapping(uint256 => mapping(address => UserInfo)) public userInfo;
//     // Total allocation poitns. Must be the sum of all allocation points in all pools.
//     uint256 public totalAllocPoint = 0;
//     // The block number when HPL mining starts.
//     uint256 public startBlock;
//     uint256 public nftPoolId = type(uint256).max;

//     event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
//     event NFTDeposit(
//         address indexed user,
//         uint256 indexed pid,
//         uint256 tokenId,
//         uint256 hplPoint
//     );
//     event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
//     event WithdrawNFT(address indexed user, uint256 indexed pid);
//     event EmergencyWithdraw(
//         address indexed user,
//         uint256 indexed pid,
//         uint256 amount
//     );
//     event EmergencyWithdrawNFT(address indexed user, uint256 indexed pid);
//     event ClaimRewards(
//         address indexed user,
//         uint256 indexed pid,
//         uint256 amount
//     );

//     function initialize(
//         address _hplNFT,
//         HPL _hpl,
//         address _nftStakingPointHook,
//         uint256 _hplPerBlock,
//         uint256 _startBlock,
//         address _tokenLock
//     ) external initializer onlyOwner {
//         nft = IERC721(_hplNFT);
//         nftStakingPointHook = INFTStakingPoint(_nftStakingPointHook);
//         hpl = _hpl;
//         hplPerBlock = _hplPerBlock;
//         startBlock = _startBlock > 0 ? _startBlock : block.number;
//         bonusEndBlock = startBlock.add(50000);

//         //add nft pool
//         add(1000, address(0), false);
//         //HPL staking pool
//         add(1000, address(hpl), false);
//     }

//     function setNFTContract(address _factory, address _nft) external onlyOwner {
//       //  factory = INFTFactory(_factory);
//         nft = IERC721(_nft);
//     }

//     function isNFTPool(uint256 pid) public view returns (bool) {
//         return address(poolInfo[pid].lpToken) == address(0);
//     }

//     function poolLength() external view returns (uint256) {
//         return poolInfo.length;
//     }

//     function setNFTContract(address _nft) external onlyOwner {
//         nft = IERC721(_nft);
//     }

//     function setNFTStakingPointHook(address _nftStakingPointHook)
//         external
//         onlyOwner
//     {
//         nftStakingPointHook = INFTStakingPoint(_nftStakingPointHook);
//     }

   

//     // Add a new lp to the pool. Can only be called by the owner.
//     // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
//     function add(
//         uint256 _allocPoint,
//         address _lpToken,
//         bool _withUpdate
//     ) public onlyOwner {
//         if (_withUpdate) {
//             massUpdatePools();
//         }
//         if (_lpToken == address(0)) {
//             require(nftPoolId == type(uint256).max, "NFT Pool already exist");
//             nftPoolId = poolInfo.length;
//         }
//         uint256 lastRewardBlock = block.number > startBlock
//             ? block.number
//             : startBlock;
//         totalAllocPoint = totalAllocPoint.add(_allocPoint);
//         poolInfo.push(
//             PoolInfo({
//                 lpToken: IERC20(_lpToken),
//                 allocPoint: _allocPoint,
//                 lastRewardBlock: lastRewardBlock,
//                 accHPLPerShare: 0,
//                 totalNFTPoint: 0
//             })
//         );
//     }

//     function setRewardPerBlock(uint256 _r, bool _withUpdate)
//         external
//         onlyOwner
//     {
//         if (_withUpdate) {
//             massUpdatePools();
//         }
//         hplPerBlock = _r;
//     }

//     // Update the given pool's HPL allocation point. Can only be called by the owner.
//     function set(
//         uint256 _pid,
//         uint256 _allocPoint,
//         bool _withUpdate
//     ) public onlyOwner {
//         if (_withUpdate) {
//             massUpdatePools();
//         }
//         totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
//             _allocPoint
//         );
//         poolInfo[_pid].allocPoint = _allocPoint;
//     }

//     // // Set the migrator contract. Can only be called by the owner.
//     // function setMigrator(IMigratorChef _migrator) public onlyOwner {
//     //     migrator = _migrator;
//     // }

//     // // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
//     // function migrate(uint256 _pid) public {
//     //     require(address(migrator) != address(0), "migrate: no migrator");
//     //     PoolInfo storage pool = poolInfo[_pid];
//     //     IERC20 lpToken = pool.lpToken;
//     //     uint256 bal = lpToken.balanceOf(address(this));
//     //     lpToken.safeApprove(address(migrator), bal);
//     //     IERC20 newLpToken = migrator.migrate(lpToken);
//     //     require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
//     //     pool.lpToken = newLpToken;
//     // }

//     // Return reward multiplier over the given _from to _to block.
//     function getMultiplier(uint256 _from, uint256 _to)
//         public
//         view
//         returns (uint256)
//     {
//         if (_to <= bonusEndBlock) {
//             return _to.sub(_from).mul(BONUS_MULTIPLIER);
//         } else if (_from >= bonusEndBlock) {
//             return _to.sub(_from);
//         } else {
//             return
//                 bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
//                     _to.sub(bonusEndBlock)
//                 );
//         }
//     }

//     // View function to see pending HPL on frontend.
//     function pendingHPL(uint256 _pid, address _user)
//         external
//         view
//         returns (uint256)
//     {
//         PoolInfo storage pool = poolInfo[_pid];
//         UserInfo storage user = userInfo[_pid][_user];
//         uint256 accHPLPerShare = pool.accHPLPerShare;
//         uint256 lpSupply = 0;
//         if (isNFTPool(_pid)) {
//             lpSupply = pool.totalNFTPoint;
//         } else {
//             lpSupply = pool.lpToken.balanceOf(address(this));
//         }
//         if (block.number > pool.lastRewardBlock && lpSupply != 0) {
//             uint256 multiplier = getMultiplier(
//                 pool.lastRewardBlock,
//                 block.number
//             );
//             uint256 hplReward = multiplier
//                 .mul(hplPerBlock)
//                 .mul(pool.allocPoint)
//                 .div(totalAllocPoint);
//             accHPLPerShare = accHPLPerShare.add(
//                 hplReward.mul(1e12).div(lpSupply)
//             );
//         }
//         uint256 amount = isNFTPool(_pid) ? user.nftPoint : user.amount;
//         return amount.mul(accHPLPerShare).div(1e12).sub(user.rewardDebt);
//     }

//     // Update reward vairables for all pools. Be careful of gas spending!
//     function massUpdatePools() public {
//         uint256 length = poolInfo.length;
//         for (uint256 pid = 0; pid < length; ++pid) {
//             updatePool(pid);
//         }
//     }

//     // Update reward variables of the given pool to be up-to-date.
//     function updatePool(uint256 _pid) public {
//         PoolInfo storage pool = poolInfo[_pid];
//         if (block.number <= pool.lastRewardBlock) {
//             return;
//         }
//         uint256 lpSupply = 0;
//         if (!isNFTPool(_pid)) {
//             lpSupply = pool.lpToken.balanceOf(address(this));
//         } else {
//             lpSupply = pool.totalNFTPoint;
//         }
//         if (lpSupply == 0) {
//             pool.lastRewardBlock = block.number;
//             return;
//         }
//         uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
//         uint256 hplReward = multiplier
//             .mul(hplPerBlock)
//             .mul(pool.allocPoint)
//             .div(totalAllocPoint);

//         pool.accHPLPerShare = pool.accHPLPerShare.add(
//             hplReward.mul(1e12).div(lpSupply)
//         );
//         pool.lastRewardBlock = block.number;
//     }

//     // Deposit LP tokens to MasterChef for HPL allocation.
//     function deposit(uint256 _pid, uint256 _amount) external {
//         require(!isNFTPool(_pid), "Pool ID must not be NFT pool");
//         PoolInfo storage pool = poolInfo[_pid];
//         UserInfo storage user = userInfo[_pid][msg.sender];
//         updatePool(_pid);
//         if (user.amount > 0) {
//             uint256 pending = user
//                 .amount
//                 .mul(pool.accHPLPerShare)
//                 .div(1e12)
//                 .sub(user.rewardDebt);
//             addRecordedReward(msg.sender, pending);
//         }
//         pool.lpToken.safeTransferFrom(
//             address(msg.sender),
//             address(this),
//             _amount
//         );
//         user.amount = user.amount.add(_amount);
//         user.rewardDebt = user.amount.mul(pool.accHPLPerShare).div(1e12);
//         emit Deposit(msg.sender, _pid, _amount);
//     }

//     function depositNFT(uint256[] memory _tokenIds) public {
//         require(nftPoolId != type(uint256).max, "NFT Pool not exist");
//         require(_tokenIds.length > 0, "Empty token list");
//         PoolInfo storage pool = poolInfo[nftPoolId];
//         UserInfo storage user = userInfo[nftPoolId][msg.sender];
//         updatePool(nftPoolId);

//         if (user.nftPoint > 0) {
//             uint256 pending = user
//                 .nftPoint
//                 .mul(pool.accHPLPerShare)
//                 .div(1e12)
//                 .sub(user.rewardDebt);
//             addRecordedReward(msg.sender, pending);
//         }

//         uint256 addedPoint = 0;
//         for (uint256 i = 0; i < _tokenIds.length; i++) {
//             uint256 _tokenId = _tokenIds[i];

//             nft.transferFrom(msg.sender, address(this), _tokenId);
//             user.stakedNFTs.push(_tokenId);

//             uint256 stakingPoint = nftStakingPointHook.getStakingPoint(
//                 _tokenId,
//                 address(nft)
//             );
//             require(
//                 stakingPoint > 0,
//                 "depositNFT:NFT is not allocated for staking point"
//             );
//             user.nftDepositPoint[_tokenId] = stakingPoint;
//             addedPoint = addedPoint.add(stakingPoint);

//             emit NFTDeposit(msg.sender, nftPoolId, _tokenId, stakingPoint);
//         }

//         user.nftPoint = user.nftPoint.add(addedPoint);
//         user.rewardDebt = user.nftPoint.mul(pool.accHPLPerShare).div(1e12);
//         pool.totalNFTPoint = pool.totalNFTPoint.add(addedPoint);

//         user.lastNFTDepositTimestamp = block.timestamp;
//     }

//     // Withdraw LP tokens from MasterChef.
//     function withdraw(uint256 _pid, uint256 _amount) public {
//         require(!isNFTPool(_pid), "Pool ID must not be NFT pool");
//         PoolInfo storage pool = poolInfo[_pid];
//         UserInfo storage user = userInfo[_pid][msg.sender];
//         require(user.amount >= _amount, "withdraw: not good");
//         updatePool(_pid);
//         uint256 pending = user.amount.mul(pool.accHPLPerShare).div(1e12).sub(
//             user.rewardDebt
//         );
//         addRecordedReward(msg.sender, pending);
//         user.amount = user.amount.sub(_amount);
//         user.rewardDebt = user.amount.mul(pool.accHPLPerShare).div(1e12);
//         pool.lpToken.safeTransfer(address(msg.sender), _amount);
//         emit Withdraw(msg.sender, _pid, _amount);
//     }

//     function claimRewards(uint256 _pid) public {
//         require(!isNFTPool(_pid), "claimRewards: must not be NFT pool");
//         PoolInfo storage pool = poolInfo[_pid];
//         UserInfo storage user = userInfo[_pid][msg.sender];
//         updatePool(_pid);
//         uint256 pending;
//         if (_pid == nftPoolId) {
//             pending = user.nftPoint.mul(pool.accHPLPerShare).div(1e12).sub(
//                 user.rewardDebt
//             );
//         } else {
//             pending = user.amount.mul(pool.accHPLPerShare).div(1e12).sub(
//                 user.rewardDebt
//             );
//         }

//         addRecordedReward(msg.sender, pending);
//         if (_pid == nftPoolId) {
//             user.rewardDebt = user.nftPoint.mul(pool.accHPLPerShare).div(
//                 1e12
//             );
//         } else {
//             user.rewardDebt = user.amount.mul(pool.accHPLPerShare).div(1e12);
//         }
//         emit ClaimRewards(msg.sender, _pid, pending);
//     }

//     function claimRewardsNFTPool() external {
//         require(nftPoolId != type(uint256).max, "NFT Pool not exist");
//         UserInfo storage user = userInfo[nftPoolId][msg.sender];
//         require(
//             user.lastNFTDepositTimestamp.add(lockedTime) <= block.timestamp,
//             "Can only claim rewards after 12hs of stake"
//         );
//         uint256 _pid = nftPoolId;
//         PoolInfo storage pool = poolInfo[_pid];
//         updatePool(nftPoolId);
//         uint256 pending;
//         pending = user.nftPoint.mul(pool.accHPLPerShare).div(1e12).sub(
//             user.rewardDebt
//         );

//         addRecordedReward(msg.sender, pending);
//         user.rewardDebt = user.nftPoint.mul(pool.accHPLPerShare).div(1e12);
//         emit ClaimRewards(msg.sender, _pid, pending);
//     }

//     function setLockedTime(uint256 _lockedTime) external onlyOwner {
//         lockedTime = _lockedTime;
//     }

//     //always withdraw all NFTs
//     function withdrawNFT() external {
//         require(nftPoolId != type(uint256).max, "NFT Pool not exist");
//         //checking last timestamp NFT deposited

//         PoolInfo storage pool = poolInfo[nftPoolId];
//         UserInfo storage user = userInfo[nftPoolId][msg.sender];
//         require(user.stakedNFTs.length > 0, "withdrawNFT: not good");
//         require(
//             user.lastNFTDepositTimestamp.add(lockedTime) <= block.timestamp,
//             "withdrawNFT: NFTs only available for withdrawal after deposit locked time"
//         );

//         updatePool(nftPoolId);
//         uint256 pending = user
//             .nftPoint
//             .mul(pool.accHPLPerShare)
//             .div(1e12)
//             .sub(user.rewardDebt);

//         //transfer nfts back
//         for (uint256 i = 0; i < user.stakedNFTs.length; i++) {
//             nft.transferFrom(address(this), msg.sender, user.stakedNFTs[i]);
//         }
//         delete user.stakedNFTs;

//         addRecordedReward(msg.sender, pending);
//         pool.totalNFTPoint = pool.totalNFTPoint.sub(user.nftPoint);
//         user.nftPoint = 0;
//         user.rewardDebt = user.nftPoint.mul(pool.accHPLPerShare).div(1e12);
//         emit WithdrawNFT(msg.sender, nftPoolId);
//     }

//     // Withdraw without caring about rewards. EMERGENCY ONLY.
//     function emergencyWithdraw(uint256 _pid) public {
//         require(!isNFTPool(_pid), "Pool ID must not be NFT pool");
//         PoolInfo storage pool = poolInfo[_pid];
//         UserInfo storage user = userInfo[_pid][msg.sender];
//         pool.lpToken.safeTransfer(address(msg.sender), user.amount);
//         emit EmergencyWithdraw(msg.sender, _pid, user.amount);
//         user.amount = 0;
//         user.rewardDebt = 0;
//     }

//     function emergencyWithdrawNFT() public {
//         PoolInfo storage pool = poolInfo[nftPoolId];
//         UserInfo storage user = userInfo[nftPoolId][msg.sender];

//         for (uint256 i = 0; i < user.stakedNFTs.length; i++) {
//             if (nft.ownerOf(user.stakedNFTs[i]) == address(this)) {
//                 nft.transferFrom(address(this), msg.sender, user.stakedNFTs[i]);
//             }
//         }
//         delete user.stakedNFTs;
//         if (pool.totalNFTPoint >= user.nftPoint) {
//             pool.totalNFTPoint = pool.totalNFTPoint.sub(user.nftPoint);
//         }
//         user.nftPoint = 0;
//         emit EmergencyWithdrawNFT(msg.sender, nftPoolId);
//         user.amount = 0;
//         user.rewardDebt = 0;
//     }

//     // Safe HPL transfer function, just in case if rounding error causes pool to not have enough HPL.
//     function addRecordedReward(address _to, uint256 _amount) internal {
//         factory.addBoxReward(_to, _amount);
//     }

//     function getUserInfo(uint256 _pid, address _user)
//         external
//         view
//         returns (
//             uint256 amount, // How many LP tokens the user has provided.
//             uint256 rewardDebt, // Reward debt. See explanation below.
//             uint256 nftPoint,
//             uint256[] memory stakedNFTs,
//             uint256 lastNFTDepositTimestamp
//         )
//     {
//         UserInfo storage user = userInfo[_pid][_user];
//         return (
//             user.amount,
//             user.rewardDebt,
//             user.nftPoint,
//             user.stakedNFTs,
//             user.lastNFTDepositTimestamp
//         );
//     }
// }
