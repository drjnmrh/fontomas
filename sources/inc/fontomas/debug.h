#pragma once
#ifndef FONTOMAS_DEBUG_H_
#define FONTOMAS_DEBUG_H_


#include <cinttypes>

#include <fontomas/exports.h>


namespace fontomas { ;
namespace debug { ;



fontomas_public void softbreak(const char* file, int32_t line, int32_t counter);
fontomas_public void hardbreak(const char* file, int32_t line, int32_t counter);

fontomas_public void debugbreak();



}
}


#define fontomas__softbreak \
    fontomas::debug::softbreak(__FILE__, __LINE__, __COUNTER__)

#define fontomas__hardbreak \
    fontomas::debug::hardbreak(__FILE__, __LINE__, __COUNTER__)


#endif//FONTOMAS_DEBUG_H_
