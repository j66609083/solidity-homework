// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

contract BeggingContract {
    
    // 记录每个捐赠者的捐赠金额
    mapping(address account => uint256 balance) public donations;

    // 开始时间（时间戳）
    uint256 public startTime;         
    // 结束时间（时间戳） 
    uint256 public endTime;            

    // 合约拥有者
    address private _contractOwner; 

    // 记录每次捐赠的地址和金额
    event Donation(address indexed donor, uint256 amount);

    // 显示捐赠金额最多的前 3 个地址
    address[3] public topDonors;

    constructor(uint256 _startTime, uint256 _endTime){
        require(_endTime > _startTime, "End time must be after start time");
        startTime = _startTime;
        endTime = _endTime;
        _contractOwner = msg.sender;
    }

    /**
     * 修饰器
     */
    modifier onlyOwner() {
        require(msg.sender == _contractOwner, "Only owner can call this function");
        _;
    }

    // 允许用户向合约发送以太币，并记录捐赠信息
    function donate() public payable {
        // 只有在特定时间段内才能捐赠
        require(block.timestamp >= startTime, "Donation not started");
        require(block.timestamp <= endTime, "Donation ended");

        // 捐赠金额必须大于0
        require(msg.value > 0, "Donation amount must be greater than zero");

        // 记录捐赠信息
        donations[msg.sender] += msg.value;

        // 记录捐赠金额最多的前 3 个地址
        if (donations[msg.sender] > donations[topDonors[0]]) {
            topDonors[2] = topDonors[1];
            topDonors[1] = topDonors[0];
            topDonors[0] = msg.sender;
        } else if (donations[msg.sender] > donations[topDonors[1]] && msg.sender != topDonors[0]) {
            topDonors[2] = topDonors[1];
            topDonors[1] = msg.sender;
        } else if (donations[msg.sender] > donations[topDonors[2]] && msg.sender != topDonors[0] && msg.sender != topDonors[1]) {
            topDonors[2] = msg.sender;
        }
        // 发送捐赠事件
        emit Donation(msg.sender, msg.value);
    }

    // 允许合约所有者提取所有资金
    function withdraw() public payable onlyOwner{
        uint256 balance = address(this).balance;
        require(balance > 0, "no balance");
        (bool ok, ) = payable(_contractOwner).call{value: balance}("");
        require(ok, "transfer failed");
    }

    // 允许查询某个地址的捐赠金额
    function getDonation(address donationAddr) public view returns (uint256) {
        return donations[donationAddr];
    }

    // 管理员修改时间限制
    function updateTime(uint256 _newStart, uint256 _newEnd) external onlyOwner {
        require(_newEnd > _newStart, "Invalid time range");
        startTime = _newStart;
        endTime = _newEnd;
    }
}