pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../AShoppingListDebot.sol";

contract ShoppingDebot is AShoppingListDebot {
    function _menu() internal override {
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "You have {}/{}/{} (buy/bought/summary) purchases",
                    m_SummaryShopping.notPaidCount,
                    m_SummaryShopping.paidCount,
                    m_SummaryShopping.paidCount + m_SummaryShopping.notPaidCount
            ),
            sep,
            [
                MenuItem("Show purchase list","",tvm.functionId(showShopping)),
                MenuItem("Delete purchase","",tvm.functionId(deleteShopping)),
                MenuItem("Buy","",tvm.functionId(Buy))
            ]
        );
    }

}