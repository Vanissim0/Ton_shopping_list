pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import 'StructsForShoppingList.sol';
import 'InterfacesShoppingList.sol';

contract ShoppingList {

    constructor(uint256 pubkey) public {
        require(pubkey != 0, 120);
        tvm.accept();
        m_ownerPubkey = pubkey;
    }

    uint32 countOfShopping;
    uint256 m_ownerPubkey;

    mapping(uint32 => Shopping) m_shopping;

    modifier onlyOwner() {
        require(msg.pubkey() == tvm.pubkey(), 101);
        _;
    }

    function addShopping(string name, uint32 number, uint price) public onlyOwner {
        tvm.accept();
        countOfShopping++;
        m_shopping[countOfShopping] = Shopping(countOfShopping, name, number, now, false, 0);
    }

    function deleteShopping(uint32 id) public onlyOwner {
        require(m_shopping.exists(id), 102);
        tvm.accept();
        delete m_shopping[id];
    }

    function Buy(uint32 id, uint price) public onlyOwner {
        optional(Shopping) shopping = m_shopping.fetch(id);
        require(shopping.hasValue(), 102);
        tvm.accept();
        Shopping thisShopping = shopping.get();
        thisShopping.isBought = true;
        thisShopping.price = price;
        m_shopping[id] = thisShopping;
    }

    function getShopping() public returns (Shopping[] shop) {
        string name;
        uint32 number;
        uint64 createdAt;
        bool isBought;
        uint price;

        for((uint32 id, Shopping purchase) : m_shopping) {
            name = purchase.name;
            number = purchase.number;
            isBought = purchase.isBought;
            createdAt = purchase.createdAt;
            price = purchase.price;
            shop.push(Shopping(id, name, number, createdAt, isBought, price));
       }
    }

    function getSummaryShopping() public returns (SummaryShopping stat) {

        uint32 paidCount;
        uint32 notPaidCount;    
        uint amoundPaid;

        for((, Shopping taskShopp) : m_shopping) {
            if  (taskShopp.isBought) {
                paidCount += taskShopp.number;
                amoundPaid *= taskShopp.price;
            } else {
                notPaidCount++;
            }
        }
        stat = SummaryShopping(paidCount, notPaidCount, amoundPaid);
    }

}