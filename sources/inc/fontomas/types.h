#pragma once
#ifndef FONTOMAS_TYPES_H_
#define FONTOMAS_TYPES_H_


#include <cinttypes>


namespace fontomas { ;


using tagid_t = uint16_t;
using nodeid_t = uint16_t;



}


#if __has_include(<optional>)
    #include <optional>

    namespace fontomas {
        template <class T>
        using optional_t = std::optional<T>;
        using std::nullopt;
    }
#else
    #warning "The system doesn't provide unexperimental optional"

    #include <experimental/optional>

    namespace fontomas {

        template <class T>
        using optional_t = std::experimental::optional<T>;
        using std::experimental::nullopt;

    }
#endif


#endif//FONTOMAS_TYPES_H_
