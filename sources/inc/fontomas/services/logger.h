#pragma once
#ifndef FONTOMAS_SERVICES_LOGGER_H_
#define FONTOMAS_SERVICES_LOGGER_H_


#include <cstdint>

#include <fontomas/exports.h>


namespace fontomas { ;
namespace services { ;



/*
 * Provides basic logging functionality.
 * All methods must be thread-safe.
 * Client code should provide this service via one of the 'provide' macros
 * (see fontomas/di.h).
 */
class fontomas_public Logger {
public:
    constexpr static const char* sServiceName = "Logger";

    enum class Level : uint8_t {
        Critical = 1, Error = 2, Info = 4, Warning = 8, Debug = 16
    };

    virtual ~Logger() noexcept {}

    /*
     * Checks if a message of the given level will be visible or ignored.
     *
     * @param level a message level to check visibility of.
     * @return true if a message of such level will be visible, false if
     *         a message of such level will be ignored.
     */
    virtual bool visible(Level level) const noexcept = 0;

    /*
     * Requests a logger service to print given message of the specified level.
     *
     * @param level a level of the message to print.
     * @param message characters to print in a utf8 encoding.
     */
    virtual void print(Level level, const char* message) noexcept = 0;
};



}
}


#endif//FONTOMAS_SERVICES_LOGGER_H_
