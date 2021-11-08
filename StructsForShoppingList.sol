pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

    struct Shopping {
        uint32 id;
        string name;
        uint32 number;
        uint64 createdAt;
        bool isBought;
        uint price;
    }

    struct SummaryShopping {
        uint32 paidCount;
        uint32 notPaidCount;    
        uint amoundPaid;
    }

