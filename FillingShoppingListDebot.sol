pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "AShoppingListDebot.sol";
import "ShoppingList.sol";

contract FillingShoppingListDebot is AShoppingListDebot {
    function _menu() internal override {
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
                MenuItem("Show purchase list","",tvm.functionId(showShopping)),
                MenuItem("Delete purchase","",tvm.functionId(deleteShopping))
            ]
        );
    }
}