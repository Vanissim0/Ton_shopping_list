pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "base/Debot.sol";
import "base/Terminal.sol";
import "base/Menu.sol";
import "base/AddressInput.sol";
import "base/Upgradable.sol";
import "base/Sdk.sol";
import "StructsForShoppingList.sol";
import "InterfacesShoppingList.sol";


abstract contract AShoppList {
   constructor(uint256 pubkey) public {}
}

abstract contract AShoppingListDebot is Debot, Upgradable {
    bytes m_icon;

    TvmCell m_ShopListCode; 
    address m_address;  
    SummaryShopping m_SummaryShopping;  
    uint32 m_ShoppingId;    
    string m_ShoppingValue;
    uint256 m_masterPubKey; 
    address m_msigAddress;  

    uint32 INITIAL_BALANCE =  200000000; 


    function setShopListCode(TvmCell code) public {
        require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        m_ShopListCode = code;
    }


    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Operation failed. sdkError {}, exitCode {}", sdkError, exitCode));
        _menu();
    }

    function onSuccess() public view {
        _getSummaryShopping(tvm.functionId(setSummaryShopping));
    }

    function start() public override {
        Terminal.input(tvm.functionId(savePublicKey),"Please enter your public key",false);
    }

    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "ShoppingList DeBot";
        version = "1.0.0";
        publisher = "Ivan Reshetar";
        key = "Shopping list manager";
        author = "Ivan Reshetar";
        support = address(0);
        hello = "Hi, I'm a ShoppingList DeBot!";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID ];
    }

    function savePublicKey(string value) public {
        (uint res, bool status) = stoi("0x"+value);
        if (status) {
            m_masterPubKey = res;

            Terminal.print(0, "Checking your a Shopping list ...");
            TvmCell deployState = tvm.insertPubkey(m_ShopListCode, m_masterPubKey);
            m_address = address.makeAddrStd(0, tvm.hash(deployState));
            Terminal.print(0, format( "Your Shopping list contract address is {}", m_address));
            Sdk.getAccountType(tvm.functionId(checkStatus), m_address);

        } else {
            Terminal.input(tvm.functionId(savePublicKey),"Wrong public key. Try again!\nPlease enter your public key",false);
        }
    }


    function checkStatus(int8 acc_type) public {
        if (acc_type == 1) { // acc is active and  contract is already deployed
            _getSummaryShopping(tvm.functionId(setSummaryShopping));

        } else if (acc_type == -1)  { // acc is inactive
            Terminal.print(0, "You don't have a TODO list yet, so a new contract with an initial balance of 0.2 tokens will be deployed");
            AddressInput.get(tvm.functionId(creditAccount),"Select a wallet for payment. We will ask you to sign two transactions");

        } else  if (acc_type == 0) { // acc is uninitialized
            Terminal.print(0, format(
                "Deploying new contract. If an error occurs, check if your TODO contract has enough tokens on its balance"
            ));
            deploy();

        } else if (acc_type == 2) {  // acc is frozen
            Terminal.print(0, format("Can not continue: account {} is frozen", m_address));
        }
    }


    function creditAccount(address value) public {
        m_msigAddress = value;
        optional(uint256) pubkey = 0;
        TvmCell empty;
        ITransactionShoppList(m_msigAddress).sendTransaction{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(waitBeforeDeploy),
            onErrorId: tvm.functionId(onErrorRepeatCredit)  // Just repeat if something went wrong
        }(m_address, INITIAL_BALANCE, false, 3, empty);
    }

    function onErrorRepeatCredit(uint32 sdkError, uint32 exitCode) public {
        // TODO: check errors if needed.
        sdkError;
        exitCode;
        creditAccount(m_msigAddress);
    }


    function waitBeforeDeploy() public  {
        Sdk.getAccountType(tvm.functionId(checkIfStatusIs0), m_address);
    }

    function checkIfStatusIs0(int8 acc_type) public {
        if (acc_type ==  0) {
            deploy();
        } else {
            waitBeforeDeploy();
        }
    }


    function deploy() private view {
            TvmCell image = tvm.insertPubkey(m_ShopListCode, m_masterPubKey);
            optional(uint256) none;
            TvmCell deployMsg = tvm.buildExtMsg({
                abiVer: 2,
                dest: m_address,
                callbackId: tvm.functionId(onSuccess),
                onErrorId:  tvm.functionId(onErrorRepeatDeploy),    // Just repeat if something went wrong
                time: 0,
                expire: 0,
                sign: true,
                pubkey: none,
                stateInit: image,
                call: {AShoppList, m_masterPubKey}
            });
            tvm.sendrawmsg(deployMsg, 1);
    }


    function onErrorRepeatDeploy(uint32 sdkError, uint32 exitCode) public view {
        sdkError;
        exitCode;
        deploy();
    }

    function setSummaryShopping(SummaryShopping summaryShopping) public {
        m_SummaryShopping = summaryShopping;
        _menu();
    }

    function _menu() virtual internal {
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "You have {}/{}/{} (todo/done/total) purchases",
                    m_SummaryShopping.notPaidCount,
                    m_SummaryShopping.paidCount,
                    m_SummaryShopping.paidCount + m_SummaryShopping.notPaidCount
            ),
            sep,
            [
                MenuItem("Add new purchase","",tvm.functionId(addShopping)),
                MenuItem("Show Shopping list","",tvm.functionId(showShopping)),
                MenuItem("Buy","",tvm.functionId(Buy)),
                MenuItem("Delete purchase","",tvm.functionId(deleteShopping))
            ]
        );
    }

    function addShopping(uint32 index) public{
        index = index;
        Terminal.input(tvm.functionId(addShopping_), "One line please:", false);
    }

    function addShopping_(string value) public {
        m_ShoppingValue = value;
        Terminal.input(tvm.functionId(addShopping__),"Quantity:", false);
    }

    function addShopping__(string value) public view {
        optional(uint256) pubkey = 0;
        (uint256 num,) = stoi(value);
        IShoppingList(m_address).addShopping{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(m_ShoppingValue, uint32(num));
    }

    function showShopping(uint32 index) public view {
        index = index;
        optional(uint256) none;
        IShoppingList(m_address).getShoppingStat{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showShopping_),
            onErrorId: 0
        }();
    }

    function showShopping_( Shopping[] purchases ) public {
        uint32 i;
        
        if (purchases .length > 0 ) {
            Terminal.print(0, "Your shopping list:");
            for (i = 0; i < purchases .length; i++) {
                Shopping shopping = purchases [i];
                string completed;
                if (shopping.isBought) {
                    completed = '✓';
                } else {
                    completed = ' ';
                }
                Terminal.print(0, format("{} {}  \"{}\" quantity: {} cost: {}  at {}", shopping.id, completed, shopping.name, shopping.number, shopping.price, shopping.createdAt));
            }
        } else {
            Terminal.print(0, "Your shopping list is empty");
        }
        _menu();
    }

    function Buy(uint32 index) public {
        index = index;
        if (m_SummaryShopping.paidCount + m_SummaryShopping.notPaidCount > 0) {
            Terminal.input(tvm.functionId(Buy_), "Enter purchase number:", false);
        } else {
            Terminal.print(0, "Sorry, you have no purchases to buy");
            _menu();
        }
    }

    function Buy_(string value) public {
        (uint256 num,) = stoi(value);
        m_ShoppingId = uint32(num);
        Terminal.input(tvm.functionId(Buy__),"Cost:", false);
    }

    function Buy__(string value) public view {
        optional(uint256) pubkey = 0;
        (uint256 num,) = stoi(value);
        IShoppingList(m_address).Buy{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(m_ShoppingId, uint32(num));
    }


    function deleteShopping(uint32 index) public{
        index = index;
        if (m_SummaryShopping.completeCount + m_SummaryShopping.incompleteCount > 0) {
            Terminal.input(tvm.functionId(deleteShopping_), "Enter purchase number:", false);
        } else {
            Terminal.print(0, "Sorry, you have no purchases to delete");
            _menu();
        }
    }

    function deleteShopping_(string value) public view {
        (uint256 num,) = stoi(value);
        optional(uint256) pubkey = 0;
        IShoppingList(m_address).deleteShopping{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(uint32(num));
    }

    function _getSummaryShopping(uint32 answerId) private view {
        optional(uint256) none;
        IShoppingList(m_address).getSummaryShopping{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: answerId,
            onErrorId: 0
        }();
    }

    function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }
}