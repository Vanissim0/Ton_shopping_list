pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

import 'StructsForShoppingList.sol';

abstract contract HasConstructorWithPubKey {
   constructor(uint256 pubkey) public {}
}

interface IShoppingList {
   function addShopping(string text, uint32 number) external;
   function createShopping(string name, uint32 number, uint price) external;
   function deleteShopping(uint32 id) external;
   function Buy(uint32 id, uint price, bool isBought) external;
   function getShoppingStat() external returns (SummaryShopping);
}
 
interface ITransactionShoppList {
   function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload) external;
}
