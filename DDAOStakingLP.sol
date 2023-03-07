/* ============================================= DEFI HUNTERS DAO ================================================================
                                           https://defihuntersdao.club/                                                                                                             
-------------------------------------------------- December 2022 -----------------------------------------------------------------
#######    #######    ######       ####                  ######   #########  ######    #####  #### ########  ###   #####   #######  
 ##   ###   ##   ###     ###      ### ###               ### ###   #  ##  ##     ###      #    ###      #      ###    ##  ###   ###  
 ##    ##   ##    ##    ## ##    ##     ##             ##     #   #  ##  ##    ## ##     #  ###        #      ####   ##  ##     ##  
 ##     ##  ##     ##  ##  ##   ##       #              ###          ##       ##  ##     ####          #      ## ##  ##  #          
 ##     ##  ##     ##  #######  ##       ##               #####      ##       #######    ######        #      ##  ## ##  #   ###### 
 ##     #   ##     #  ##    ##   ##     ##             ##     ##     ##      ##    ##    #   ###       #      ##  #####  #      ##  
 ##   ###   ##   ###  ##     ##  ###   ###             ##    ###     ##      ##     ##   #    ##       #      ##   ####  ###    ##  
########   ########  ####   ####   #####               ########    #######  ####   #########   ### ########  #####  ###    #######  
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./admin.sol";


interface ITxs
{
    function TxsAdd(address addr,uint256 amount,string memory name,uint256 id1,uint256 id2)external returns(uint256);
    function TxsCount(address addr)external returns(uint256);
    function EventAdd(uint256 txcount,address addr,uint256 user_id,uint256 garden,uint256 level,uint256 amount,string memory name)external returns(uint256);

}
interface IToken
{
    function approve(address spender,uint256 amount)external;
    function allowance(address owner,address spender)external view returns(uint256);
    function balanceOf(address addr)external view returns(uint256);
    function decimals() external view  returns (uint8);
    function name() external view  returns (string memory);
    function symbol() external view  returns (string memory);
    function totalSupply() external view  returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
//    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1, uint32 _blockTimestampLast);
}

contract DDAOStakingLP is admin
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event eLog(uint256 nn,string name,uint256 value);

    address public lp_ddao_weth;
    address public lp_gnft_weth;
    address public lp_gnft_usdc;
    address public lp_weth_usdc;

    uint256 public DeployTime = block.timestamp;
//    uint256 public constant RewardCalcTime = 3600;
    uint256 public constant RewardCalcTime = 60;
    uint256 public RewardStartTime;

    mapping(uint8 => uint256)public BalanceLP;

//    bool public AdminUnstakeAllow = false;
    bool public AdminUnstakeAllow = true;

    uint256 public UpdateTime = block.timestamp;
    mapping(uint256 => uint256)public Exited;


    struct stake_struct
    {
	address addr;
	uint256 koef;
    }
    mapping (uint8 => stake_struct)public StakeLP;
    mapping (uint8 => mapping(uint256 => uint256))public StakeAmount;
    mapping (uint8 => uint256)public StakeAmountLastTime;

	address public TxAddr = 0xB7CC7b951DAdADacEa3A8E227F25cd2a45c64284;
	address[] public Users;
	address public TokenAddress;
	event StakeLog(string name,address addr,uint256 time,uint256 amount, uint256 frozen,uint256 unlock);

    struct user_struct
    {
	address addr;
	bool set;
	uint256 time;
    }
    mapping(address => user_struct)public UserSet;
    address[] public UserList;

	constructor() 
	{
	

	DeployTime = block.timestamp;
	RewardStartTime = Utime(DeployTime);


	_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
	Admins.push(_msgSender());
	AdminAdd(0x208b02f98d36983982eA9c0cdC6B3208e0f198A3);
	if(_msgSender() != 0x80C01D52e55e5e870C43652891fb44D1810b28A2)
	AdminAdd(0x80C01D52e55e5e870C43652891fb44D1810b28A2);


	    if(block.chainid == 137)
	    {
		// DDAO
		TokenAddress = 0x90F3edc7D5298918F7BB51694134b07356F7d0C7;
                lp_ddao_weth = 0xfC067766349d0960bdC993806EA2E13fcFC03C4D;
                lp_gnft_weth = 0x03B67a0cE884E806673CC92e9A1C4A77D5BC770B;
                lp_gnft_usdc = 0x3fd0CC5f7Ec9A09F232365bDED285e744E0446e2;
                lp_weth_usdc = 0x34965ba0ac2451A34a0471F04CCa3F990b8dea27;

	    }

	    if(block.chainid == 80001)
	    {
                lp_ddao_weth = 0xCB92a252907E21fB0c7A88C7E9de0BbE8d158B1e;
                lp_gnft_weth = 0x55267F9e60Bb86e7D3e442F06eE458F766496220;
                lp_gnft_usdc = 0x2Ec0c97061D2E7a342B6fab39d4544eE3bcFC5e4;

	    }
	    if(block.chainid == 31337)
	    {
                lp_ddao_weth = 0x34156Ba6Fa6af8970c7c506aC484a63da8A52f1A;
                lp_gnft_weth = 0x2CD61c9206A14177986221CcBEE516DD5f2bBE30;
                lp_gnft_usdc = 0x42F97E37c5CbAba02b7022Ab8B00209E5919bBc6;

	    }
	StakeLP[1].addr = lp_ddao_weth;
	StakeLP[2].addr = lp_gnft_weth;
	StakeLP[3].addr = lp_gnft_usdc;

	}

    function TxsAddrChange(address addr)public onlyAdmin
    {
	require(TxAddr != addr,"This address already set");
	TxAddr = addr;
    }
    // End: Admin functions

    function AddCoin()public payable returns(bool)
    {
	return true;
    }
    function name()public pure returns(string memory)
    {
	return "DDAO LPStaking";
    }
    function symbol() public pure returns(string memory)
    {
	return "lpDDAO";
    }
    function decimals()public view returns(uint8)
    {
	return IToken(TokenAddress).decimals();
    }
    function totalSupply()public view returns(uint256)
    {
	return IToken(TokenAddress).balanceOf(address(this));
    }

    function RateDDAO()public view returns(uint256 rate)
    {
	uint256 r1;
	uint256 r2;
	(r1,r2,) = IToken(lp_ddao_weth).getReserves();
	rate = 10**18 * r1 / r2;
	rate *= RateWETH();
	rate /= 10**18;
	
    }

    function RateGNFT()public view returns(uint256 rate)
    {
	uint256 r1;
	uint256 r2;
	(r1,r2,) = IToken(lp_gnft_weth).getReserves();
	rate = 10**18 * r1 / r2;
	rate *= RateWETH();
	rate /= 10**18;
	
    }

    function RateGNFT2()public view returns(uint256 rate)
    {
	uint256 r1;
	uint256 r2;
	(r1,r2,) = IToken(lp_gnft_usdc).getReserves();
	rate = 10**18 * r1 / r2;
	rate *= 10**12;
	
    }

    function RateWETH()public view returns(uint256 rate)
    {
	uint256 r1;
	uint256 r2;
	(r1,r2,) = IToken(lp_weth_usdc).getReserves();
	rate = 10**18 * 10**12 * r1 / r2;
    }
    function getReserves(address addr)public view returns(uint256 r1,uint256 r2,uint32 time)
    {
	(r1,r2,time) = IToken(addr).getReserves();
    }
    function Stake(address addr,address lp,uint256 amount,uint256 interval)public
    {
	uint8 grp;
	uint256 nn;
	address lp2;
	require(interval == 90 ||interval == 180 || interval == 360 || interval == 720,"Interval must be 90,180, 360 or 720 days");
	require(lp == StakeLP[1].addr || lp == StakeLP[2].addr || lp == StakeLP[3].addr,"Unknown address of LP.");
	if(addr == address(0))addr = _msgSender();
	if(lp == StakeLP[1].addr){lp2 = StakeLP[1].addr;grp = 1;}
	if(lp == StakeLP[2].addr){lp2 = StakeLP[2].addr;grp = 2;}
	if(lp == StakeLP[3].addr){lp2 = StakeLP[3].addr;grp = 3;}

	require(IToken(lp2).allowance(_msgSender(),address(this)) >= amount,"Check allowance from you LP to this contract.");

	IToken(lp).transferFrom(_msgSender(),address(this),amount);

	nn = StakeNum[addr]*1 + 1;
	StakeNum[addr] = nn;
	StakeUser[addr][nn].nn 		= nn;
	StakeUser[addr][nn].owner 	= addr;
	StakeUser[addr][nn].lp 		= lp;
	StakeUser[addr][nn].grp 	= grp;
	StakeUser[addr][nn].amount 	= amount;
	StakeUser[addr][nn].time 	= block.timestamp;
	StakeUser[addr][nn].interval 	= interval;

	BalanceLP[grp] += amount;
	StakeAmount[grp][Utime(0)] = BalanceLP[grp];
	if(UserSet[addr].set == false)
	{
	    UserSet[addr].set = true;
	    UserSet[addr].addr = addr;
	    UserSet[addr].time = block.timestamp;
	    UserList.push(addr);
	}
	UpdateTime = block.timestamp;
	StakeAllNum++;
	StakeAll[StakeAllNum].addr = addr;
	StakeAll[StakeAllNum].nn = nn;

    }
    function StakeAmountAllShow(uint8 grp)public view returns(uint256[] memory)
    {
	uint256 nn = 0;
	uint256 start = RewardStartTime;
	uint256 i;
	uint256 last = Utime(0);
	uint256 l;
	l = (last - start) / RewardCalcTime;
	uint256[] memory out = new uint256[](2 * l);
	for(i=start;i<=last;i+=RewardCalcTime)
	{
	    out[nn++] = i;
	    out[nn++] = StakeAmount[grp][i];
	}
	return out;
    }
    function Unstake(uint256 nn)public
    {
	address addr = _msgSender();
	uint256 amount = StakeUser[addr][nn].amount;
	require(StakeUser[addr][nn].closed == false,"This position already unstaked.");
	require(StakeUser[addr][nn].time + StakeUser[addr][nn].interval * RewardCalcTime <= block.timestamp || AdminUnstakeAllow,"You try unstake locked tokens. Check interval.");


	StakeUser[addr][nn].closed = true;
	StakeUser[addr][nn].closed_time = block.timestamp;
	BalanceLP[StakeUser[addr][nn].grp] -= amount;
	StakeAmount[StakeUser[addr][nn].grp][Utime(0)] = BalanceLP[StakeUser[addr][nn].grp];

	IToken(StakeUser[addr][nn].lp).transfer(_msgSender(),amount);
	UpdateTime = block.timestamp;
	UnstakeAllNum++;
	UnstakeAll[UnstakeAllNum].addr = addr;
	UnstakeAll[UnstakeAllNum].nn = nn;
    }
    struct stake_struct2
    {
	uint256 nn;
	address owner;
	uint8   grp;
	address lp;
	uint256 amount;
	uint256 time;
	uint256 interval;
	bool closed;
	uint256 closed_time;
	uint256 claim_time;
//	uint256 claimed;
    }
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))public Claimed;
    struct stake_all_struct
    {
	address addr;
	uint256 nn;
    }
    mapping(uint256 => stake_all_struct)public StakeAll;
    mapping(uint256 => stake_all_struct)public UnstakeAll;
    uint256 public StakeAllNum;
    uint256 public UnstakeAllNum;

    uint256[] public StakeUserNum;
    mapping(address => uint256) public StakeNum;
    mapping(address => mapping(uint256 => stake_struct2)) public StakeUser;

    uint256 public RewardNum = 0;
    struct reward_struct
    {
	address tkn;
	uint256 amount;
	uint256 start_time;
	uint256 interval;
	bool stoped;
	bool hidden;
	bool exited;
	address owner;
	uint256 stoped_time;	
	uint256 hidden_time;
	uint256 koef1;
	uint256 koef2;
	uint256 koef3;
//	uint256 claimed;
    }
    mapping(uint256 => reward_struct)public RewardData;
    mapping(uint256 => uint256)public RewardClaimed;
    function RewardAdd(address tkn,uint256 amount,uint256 interval)public 
    {
	require(IToken(tkn).allowance(_msgSender(),address(this)) >= amount,"Check allowance from you tokens's to this contract.");
	require(interval >= 5,"Minimal interval is 5");
	require(interval <= 180,"Maximum interval is 180");
	RewardNum++;
	RewardData[RewardNum].tkn 	= tkn;
	RewardData[RewardNum].amount 	= amount;
	RewardData[RewardNum].owner 	= _msgSender();
	RewardData[RewardNum].interval 	= interval;
	RewardData[RewardNum].start_time 	= block.timestamp;
	RewardData[RewardNum].stoped_time 	= block.timestamp;
	RewardData[RewardNum].stoped 	= true;

	IToken(tkn).transferFrom(_msgSender(),address(this),amount);
	UpdateTime = block.timestamp;
    }
    function RewardStop(uint256 num, bool true_or_false)public onlyAdmin
    {
	require(RewardData[num].exited == false,"This reward alredyt exit.");
	require(RewardData[num].stoped != true_or_false,"This reward already has this state.");
	RewardData[RewardNum].stoped = true_or_false;
	RewardData[RewardNum].stoped_time = true_or_false?block.timestamp:0;
	UpdateTime = block.timestamp;
    }
    function RewardHide(uint256 num, bool true_or_false)public onlyAdmin
    {
	require(RewardData[num].hidden != true_or_false,"This reward already has this state.");
	RewardData[RewardNum].hidden = true_or_false;
	RewardData[RewardNum].hidden_time = true_or_false?block.timestamp:0;
	UpdateTime = block.timestamp;
    }
    function RewardKoef(uint256 num,uint256 koef1,uint256 koef2,uint256 koef3)public onlyAdmin
    {
	require(RewardData[num].exited == false,"This reward alredyt exit.");
        require(RewardData[num].koef1 == 0 && RewardData[num].koef2 == 0 && RewardData[num].koef3 == 0,"Coefficients already set.");
        RewardData[num].koef1 = koef1;
        RewardData[num].koef2 = koef2;
        RewardData[num].koef3 = koef3;
	RewardData[num].stoped 	= false;
	UpdateTime = block.timestamp;
    }

    function RewardExit(uint256 num,address addr)public onlyAdmin
    {
	require(RewardData[num].exited == false,"This reward alredyt exit.");
	if(addr == address(0))addr = RewardData[num].owner;
	uint256 amount;
	RewardData[num].exited = true;
	RewardData[num].stoped_time = block.timestamp;
	
	amount = RewardData[num].amount - RewardClaimed[num];
	if(amount > 0)
	{
	IToken(RewardData[num].tkn).transfer(addr,amount);
	Exited[num] = amount;
	}
	UpdateTime = block.timestamp;
    }


//    function RewardSummaryOnTime(uint8 grp,uint256 num,uint256 time)public view returns(uint256 out,uint256 i2,uint256 t2,uint256 t,uint256 koef,uint256 time2)
    function RewardSummaryOnTime(uint8 grp,uint256 num,uint256 time)public view returns(uint256 out)
    {
//	if(RewardData[num].hidden == true)return (0,0,0,0,0,0);
	if(RewardData[num].hidden == true)return 0;

	if(time == 0)time = Utime(block.timestamp);
	uint256 i;

	uint256 t;
	uint256 t2;
	uint256 koef;
	t = Utime(RewardData[num].start_time);
	t2  = RewardData[num].start_time + RewardData[num].interval * RewardCalcTime;
	if(RewardData[num].stoped == true)t2 = RewardData[num].stoped_time;
	t2 = Utime(t2);
	if(grp == 1)koef = RewardData[num].koef1;
	if(grp == 2)koef = RewardData[num].koef2;
	if(grp == 3)koef = RewardData[num].koef3;

	for(i = t;i < t2;i += RewardCalcTime)
	{
	    if(i == time)
	    {
		out = RewardData[num].amount / RewardData[num].interval * koef / (RewardData[num].koef1 + RewardData[num].koef2 + RewardData[num].koef3);
		//i2 = i;
		break;
	    }
	}
	//time2 = time;
    }
    function Utime(uint256 time)public view returns(uint256 out)
    {
	if(time == 0)time = block.timestamp;
	out = time / RewardCalcTime * RewardCalcTime + RewardCalcTime;
    }
    
    function BalanceStaked(address addr,uint8 grp)public view returns(uint256)
    {
	uint256 b;
	uint256 nn;
	for(nn=1;nn <= StakeNum[addr];nn++)
	{
	    if(StakeUser[addr][nn].grp == grp)
	    {
		if(StakeUser[addr][nn].closed == false)
	        b += StakeUser[addr][nn].amount;
	    }
	}
	return b;
    }
    function BalanceWallet(address addr,uint256 flag)public view returns(uint256,uint256,uint256[] memory)
    {
	uint256 r;
	uint256 r2;
	uint256 amount = 0;
	uint256 nn = 0;
	uint256[] memory out = new uint256[](8*3 + 3);
	uint256 b;
	uint256 t;
	uint256 a;

	// ddao_weth
	out[nn++] = uint256(uint160(StakeLP[1].addr));
	if(flag == 1)
	t = BalanceStaked(addr,1);
	else
	t = IToken(StakeLP[1].addr).balanceOf(addr);
	a = IToken(StakeLP[1].addr).totalSupply();
	b = 10**18 * t / a;
	out[nn++] = a;
	out[nn++] = t;
	out[nn++] = b;
	(r,,) = IToken(StakeLP[1].addr).getReserves();
	out[nn++] = r;
	r2 = RateWETH();
	out[nn++] = r2;
	r *= 2;
	r *= r2;
	r /= 10**18;
	out[nn++] = r;
	out[nn++] = r * b / 10**18;

	amount += r * b / 10**18;


	// gnft_weth
	out[nn++] = uint256(uint160(StakeLP[2].addr));
	if(flag == 1)
	t = BalanceStaked(addr,2);
	else
	t = IToken(StakeLP[2].addr).balanceOf(addr);
	a = IToken(StakeLP[2].addr).totalSupply();
	b = 10**18 * t / a;
	out[nn++] = a;
	out[nn++] = t;
	out[nn++] = b;
	(r,,) = IToken(StakeLP[2].addr).getReserves();
	out[nn++] = r;
	r2 = RateWETH();
	out[nn++] = r2;
	r *= 2;
	r *= r2;
	r /= 10**18;
	out[nn++] = r;
	out[nn++] = r * b / 10**18;
	amount += r * b / 10**18;

	// gnft_usdc
	out[nn++] = uint256(uint160(StakeLP[3].addr));
	if(flag == 1)
	t = BalanceStaked(addr,3);
	else
	t = IToken(StakeLP[3].addr).balanceOf(addr);
	a = IToken(StakeLP[3].addr).totalSupply();
	b = 10**18 * t / a;
	out[nn++] = a;
	out[nn++] = t;
	out[nn++] = b;
	(r,,) = IToken(StakeLP[3].addr).getReserves();
	r *= 10**12;
	out[nn++] = r;
	r2 = 10**18;
	out[nn++] = r2;
	r *= 2;
	r *= r2;
	r /= 10**18;
	out[nn++] = r;
	out[nn++] = r * b / 10**18;
	amount += r * b / 10**18;

	r = RateDDAO();
	r2 = 10**18 * amount / r;
	out[nn++] = amount;
	out[nn++] = r;
	out[nn++] = r2;

	return (amount,r2,out);
    }
    function balanceOf(address addr)public view returns(uint256)
    {
	uint256 out;
//	(out,,) = BalanceWallet(addr,1);
	(,out,) = BalanceWallet(addr,1);
	return out;
    }
    struct reward_num_by_addr_struct
    {
	uint256 stake_all;
	uint256 stake;
	uint256 reward;
	uint256 nn;
	uint8 grp;
    }
//    function transfer(address addr,uint256 amount)public
    function transfer(address,uint256)public
    {
	require(false,"This is not a transferable token. To change the balance, go to https://app.defihuntersdao.clud");
    }
//    function transferFrom(address from,address addr,uint256 amount)public
    function transferFrom(address,address,uint256)public
    {
	require(false,"This is not a transferable token. To change the balance, go to https://app.defihuntersdao.clud");
    }
//    function approve(address spender,address addr,uint256 amount)public
    function approve(address,address,uint256)public
    {
	require(false,"This is not a transferable token. To change the balance, go to https://app.defihuntersdao.clud");
    }
//    function allowance(address owner,address spender)public pure returns(uint256)
    function allowance(address,address)public pure returns(uint256)
    {
	return 0;
    }

//    function RewardNumByAddr(uint256 num,address addr,uint256 nn,uint256 time)public view returns(uint256,uint256,uint256[] memory)
    function RewardNumByAddr(uint256 num,address addr,uint256 nn,uint256 time)public view returns(uint256)
    {
	if(StakeUser[addr][nn].closed)return 0;
	if(RewardData[num].exited)return 0;
	uint256 amount;
	uint256 time2;
	if(time == 0)time = Utime(block.timestamp);
	reward_num_by_addr_struct memory res;
	//res.nn = 0;
	uint256 i;
//	uint256 t = Utime(DeployTime);
	uint256 t;
//	t = Utime(RewardData[num].start_time) + RewardCalcTime;
	t = Utime(RewardData[num].start_time);

	if(RewardData[num].stoped)
	time2 = Utime(RewardData[num].stoped_time);
	else
	time2 = t + RewardData[num].interval * RewardCalcTime;

	if(time > time2)time = time2;
        //uint256 l = (time - t) / RewardCalcTime;
	//uint256[] memory out = new uint256[](l*7+1);
	//out[res.nn++] = l;

	uint256 t2;
	res.grp = StakeUser[addr][nn].grp;
        amount = StakeUser[addr][nn].amount;
	for(i = t;i <= time;i += RewardCalcTime)
	{

	    if(i == t)
	    res.stake_all = StakeByGroupByTime(res.grp,i,0,0);
	    else
	    res.stake_all = StakeByGroupByTime(res.grp,i,res.stake_all,i-RewardCalcTime);

	    //out[res.nn++] = i;
	    if(res.stake_all > 0)
	    {

	    //out[res.nn++] = res.stake_all;


//	    if(StakeUser[addr][nn].closed)amount = 0;
	    //out[res.nn++] = amount;

//	    res.stake = amount * 10**18 / res.stake_all;
	    res.stake = amount * 10**24 / res.stake_all;
	    //out[res.nn++] = res.stake;

//	    (t2,,,,,) = RewardSummaryOnTime(res.grp,num,i);
	    t2 = RewardSummaryOnTime(res.grp,num,i);
	    //out[res.nn++] = t2;
//	    t2 = t2 * res.stake / 10**18;
	    t2 = t2 * res.stake / 10**24;
	    res.reward += t2;

	    //out[res.nn++] = t2;
	    //out[res.nn++] = res.reward;
	    }
	    else
	    {
	    //out[res.nn++] = 0;
	    //out[res.nn++] = 0;
	    //out[res.nn++] = 0;
	    //out[res.nn++] = 0;
	    //out[res.nn++] = 0;
	    }
	}
//	res.reward -= StakeUser[addr][nn].claimed;
	res.reward -= Claimed[addr][nn][num];
	//return (res.reward,l,out);
	return (res.reward);
    }
    function StakeListByGroup(uint8 grp)public view returns(uint256[] memory)
    {
	uint256 nn = 0;
	uint256 time = Utime(block.timestamp);
	uint256 i;
	uint256 t = Utime(DeployTime);
	uint256 l = (time - t) / RewardCalcTime + 1;
	uint256[] memory out = new uint256[](l*2+1);
	out[nn++] = l;
	uint256 last = 0;

	for(i = t;i <= time;i += RewardCalcTime)
	{
	    out[nn++] = i;
	    if(StakeAmount[grp][i] != 0)last = StakeAmount[grp][i];
	    out[nn++] = last;
	}

	return out;
	
    }
    function StakeByGroupByTime(uint8 grp,uint256 time,uint256 last,uint256 last_time)public view returns(uint256)
    {
	uint256 time_end = Utime(block.timestamp);
	uint256 i;
	uint256 t;
	if(last_time == 0)
	t = Utime(DeployTime);
	else
	t = last_time;
//	uint256 last = 0;

	for(i = t;i <= time_end;i += RewardCalcTime)
	{
	    if(StakeAmount[grp][i] != 0)last = StakeAmount[grp][i];
	    if(i==time)return last;
	}

	return 0;
	
    }

    function ClaimReward(uint256 num,uint256 nn)public returns(uint256)
    {
	address addr = _msgSender();
	uint256 time = Utime(block.timestamp);
	require(StakeUser[addr][nn].claim_time < time,"Reward on this period already claimed.");


	uint256 amount;
//	(amount,,) = RewardNumByAddr(num,addr,nn,time);
	amount = RewardNumByAddr(num,addr,nn,time);
	StakeUser[addr][nn].claim_time = time;
//	StakeUser[addr][nn].claimed += amount;
	Claimed[addr][nn][num] += amount;
	RewardClaimed[num] += amount;
//	RewardData[num].claimed += amount;
	if(amount > 0)
	IToken(RewardData[num].tkn).transfer(addr,amount);
	UpdateTime = block.timestamp;
	return amount;
    }
    function ClaimRewardMulti(uint256 num)public returns(uint256)
    {
	uint256 amount = 0;
	uint256 i;
	address addr = _msgSender();
	uint256 l = StakeNum[addr];
	for(i = 1; i <= l;i++)
	{
	    amount += ClaimReward(num,i);
	}
	UpdateTime = block.timestamp;
	return amount;
    }
    function AdminUnstakeAllowChange(bool true_or_false)public onlyAdmin
    {
	AdminUnstakeAllow = true_or_false;
    }
    function PeriodStepView(uint256 time)public view returns(uint256 out)
    {
	if(time == 0)time = block.timestamp;
	out = PeriodTimeView(time);
	out /= RewardCalcTime;
	out += 1;
    }
    function PeriodTimeView(uint256 time)public view returns(uint256 out)
    {
	if(time == 0)time = block.timestamp;
	out = Utime(time) - RewardStartTime;
    }
    function Blk()public view returns(uint256)
    {
        return block.number;
    }
    function BlkTime()public view returns(uint256)
    {
        return block.timestamp;
    }
    function UserListCount()public view returns(uint256)
    {
	return UserList.length;
    }
}