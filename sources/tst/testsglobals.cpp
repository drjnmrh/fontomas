#include "testsglobals.h"

#include <stdarg.h>


namespace fontomas::testing { ;
namespace platform { ;

extern void append_log_message(const std::string& msg) noexcept;
extern bool run_in_sandbox(Sandbox::Func func) noexcept;

}
}


using namespace fontomas::testing;


/*static*/
Log& Log::Instance() noexcept {
    static Log sInstance;
    return sInstance;
}


void Log::append(const std::string& msg) noexcept {
    std::size_t pos = 0;
    while (pos < msg.length()) {
        if (msg[pos] == '\n') {
            platform::append_log_message(_remainder);
            _remainder = "";
        } else {
            _remainder += msg[pos];
        }
        ++pos;
    }
}


void Log::format(const char* fmt, ...) noexcept {
    char buffer[1024];

    va_list args;
    va_start(args, fmt);
    int nb = std::vsnprintf(buffer, 1024, fmt, args);
    va_end(args);

    if (nb <= 0)
        return;

    append(buffer);
}


Log& Log::operator << (const std::string& msg) noexcept {
    append(msg);
    return *this;
}


bool Sandbox::execute(Func func) noexcept {
    return platform::run_in_sandbox(func);
}
