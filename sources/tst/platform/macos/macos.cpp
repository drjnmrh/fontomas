#include <csetjmp>
#include <csignal>
#include <iostream>
#include <string>

#include <execinfo.h>

#include "testsglobals.h"


namespace fontomas::testing { ;
namespace platform { ;


void append_log_message(const std::string& msg) noexcept;
bool run_in_sandbox(Sandbox::Func func) noexcept;


}
}


using namespace fontomas::testing;


void platform::append_log_message(const std::string& msg) noexcept {
    std::cout << msg << "\n";
}



static int s_SignalsToHandle[] = { SIGFPE, SIGILL, SIGSEGV, SIGBUS, SIGABRT, SIGTRAP };
static jmp_buf s_Env;
static int s_JumpVal = 0;



static void signal_error(int sig, siginfo_t* info, void* ptr) {
    char s_Buffer[1024];
    std::cerr << "signal_error:" << "\n";

    #if __WORDSIZE == 64
        void* eaddr = (void*)((ucontext_t*)ptr)->uc_mcontext->__ss.__rip;
    #else
        void* eaddr = (void*)((ucontext_t*)ptr)->uc_mcontext->__ss.__eip;
    #endif

    sprintf(s_Buffer, "\nsignal %d (%s), address is %p from %p\n",
            sig, strsignal(sig), info->si_addr, (void *)eaddr);

    void* trace[50];
    int trsize = backtrace(trace, 50);
    trace[1] = eaddr;

    char** messages = backtrace_symbols(trace, trsize);
    if (messages) {
        for (int i = 1; i < trsize; ++i) {
            sprintf(s_Buffer, "%s[bt]: (%d) %s\n",
                    s_Buffer, i, messages[i]);
        }

        free(messages);
    }

    std::cerr << s_Buffer << "\n";

    longjmp(s_Env, s_JumpVal);
}

struct raii_signal_handler {
    raii_signal_handler() noexcept {
        sigact.sa_flags = SA_SIGINFO;
        sigact.sa_sigaction = signal_error;

        sigemptyset(&sigact.sa_mask);
        for (std::size_t i = 0, sz = CountOf(s_SignalsToHandle); i < sz; ++i)
            sigaction(s_SignalsToHandle[i], &sigact, 0);
    }

    ~raii_signal_handler() noexcept {
        for (std::size_t i = 0, sz = CountOf(s_SignalsToHandle); i < sz; ++i)
            signal(s_SignalsToHandle[i], SIG_DFL);
    }

    struct sigaction sigact;
};


bool platform::run_in_sandbox(Sandbox::Func test_func) noexcept {
    volatile raii_signal_handler sh;

    s_JumpVal = setjmp(s_Env);
    if (0 == s_JumpVal) {
        return test_func();
    } else {
        return false;
    }
}
