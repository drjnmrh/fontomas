#pragma once
#ifndef FONTOMAS_MACROS_H_
#define FONTOMAS_MACROS_H_


#if defined(_MSC_VER)
#   if defined(_CPPUNWIND)
#       define fontomas__try try
#       define fontomas__catchall catch(...)
#       define fontomas__catch(ExceptionType, ExceptionVar) catch(ExceptionType& ExceptionVar)
#   else
        namespace fontomas { ;
        struct DummyException {
            const char* what() const noexcept { return ""; }
        };
        }
#       define fontomas__try
#       define fontomas__catchall if (false)
#       define fontomas__catch(ExceptionType, ExceptionVar) for (fontomas::DummyException ExceptionVar; false;)
#   endif
#else
#   ifdef __EXCEPTIONS
#       define fontomas__try try
#       define fontomas__catchall catch(...)
#       define fontomas__catch(ExceptionType, ExceptionVar) catch(ExceptionType& ExceptionVar)
#   else
        namespace fontomas { ;
        struct DummyException {
            const char* what() const noexcept { return ""; }
        };
        }
#       define fontomas__try
#       define fontomas__catchall if (false)
#       define fontomas__catch(ExceptionType, ExceptionVar) for (fontomas::DummyException ExceptionVar; false;)
#   endif
#endif


#define fontomas__safe_call(Call) fontomas__try { Call; } fontomas__catchall { fontomas__hardbreak; }


#endif//FONTOMAS_MACROS_H_
