#include "../../timing/dphpc_timing.h"



long fib(int n) {
    if (n <= 2) {
        return 1;
    }
    long sn = 1;
    long sn_1 = 1;
    for (int i = 3; i <= n; i++) {
        long tmp = sn_1;
        sn_1 = sn;
        sn = sn + tmp;
    }
    return sn;

}

int main() {

    dphpc_time3(
        , // no reset/init code in this case
        fib(1000),
        "S"
    );

    dphpc_time3(
        ,
        fib(10000),
        "M"
    );

    dphpc_time3(
        ,
        fib(100000),
        "L"
    );
}