pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

import 'StructsForShoppingList.sol';

abstract contract HasConstructorWithPubKey {
   constructor(uint256 pubkey) public {}
}

interface IShoppingList {
   function addShopping(string text, uint32 number) external;
   function deleteShopping(uint32 id) external;
   function Buy(uint32 id, uint price) external;
   function getShopping() external returns (Shopping[] purchase);
   function getSummaryShopping() external returns (SummaryShopping);
}
 
interface ITransactionShoppList {
   function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload) external;
}
