#include "fontomas/debug.h"

#include <csignal>
#include <cstdlib>
#include <iostream>


using namespace fontomas;


void debug::softbreak(const char* file, int32_t line, int32_t counter) {
    std::cerr << "SOFTBREAK: " << file << " at " << line << " [" << counter << "]\n";
    debug::debugbreak();
}


void debug::hardbreak(const char* file, int32_t line, int32_t counter) {
    std::cerr << "HARDBREAK: " << file << " at " << line << " [" << counter << "]\n";
    std::abort();
}


void debug::debugbreak() {
#ifdef _DEBUG
    std::raise(SIGTRAP);
#else
    std::cerr << "DEBUGBREAK fired\n";
#endif
}
