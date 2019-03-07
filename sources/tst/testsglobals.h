#pragma once
#ifndef FONTOMAS_TST_TESTSGLOBALS_H_
#define FONTOMAS_TST_TESTSGLOBALS_H_


#include <cassert>
#include <list>
#include <vector>
#include <sstream>
#include <type_traits>
#include <unordered_map>

#include <fontomas/debug.h>
#include <fontomas/macros.h>


namespace fontomas { ;
namespace testing { ;



struct Test {
    typedef bool (*test_func_t)();

    test_func_t func;
    char name[256];
};



class Log {
public:
    static Log& Instance() noexcept;

    void append(const std::string& msg) noexcept;
    void format(const char* fmt, ...) noexcept;

    Log& operator << (const std::string& msg) noexcept;

    Log& operator << (const char* msg) noexcept {
        if (!msg)
            return *this;

        append(msg);
        return *this;
    }

    Log& operator << (const unsigned char* msg) noexcept {
        if (!msg)
            return *this;

        fontomas__try {
            std::stringstream str;
            str << msg;
            append(str.str());
        } fontomas__catchall {
            fontomas__hardbreak;
        }
        return *this;
    }

    template <typename T>
    Log& operator << (const T& v) noexcept {
        fontomas__try {
            std::stringstream str;
            str << v;
            append(str.str());
        } fontomas__catchall {
            fontomas__hardbreak;
        }
        return *this;
    }

private:
    Log() = default;
    ~Log() = default;

    std::string _remainder;
};


class Sandbox final {
public:
    using Func = Test::test_func_t;

    bool execute(Func func) noexcept;
};


template <typename Key, class Container>
struct CheckContains;

template <typename Key, typename Value>
struct CheckContains<Key, std::unordered_map<Key, Value> > {
    static bool Check(const std::unordered_map<Key, Value>& c, Key k) {
        auto foundIt = c.find(k);
        return foundIt != c.end();
    }
};

template <typename Key, class Container>
bool check_contains(const Container& c, Key k) {
    return CheckContains<Key, Container>::Check(c, k);
}


template <typename Key, class Container>
struct CheckIsNotNull;

template <typename Key, typename Value>
struct CheckIsNotNull<Key, std::unordered_map<Key, Value> > {
    static bool Check(const std::unordered_map<Key, Value>& c, Key k) {
        auto foundIt = c.find(k);
        if (foundIt == c.end())
            return false;
        return !!foundIt->second;
    }
};


template <typename Key, class Container>
bool check_notnull(const Container& c, Key k) {
    return CheckIsNotNull<Key, Container>::Check(c, k);
}


void shuffle(std::vector<std::size_t>& buffer) noexcept;


template <typename T>
std::size_t count_all(const T* buffer, std::size_t sz, T value) {
    std::size_t counter = 0;
    for (std::size_t i = 0; i < sz; ++i) {
        if (value == buffer[i])
            ++counter;
    }
    return counter;
}

template <typename OutType, typename InType, class Predicate>
std::list<OutType> collect_all(const InType* buffer, OutType sz, InType value, Predicate filter) {
    std::list<OutType> result;
    for (OutType i = 0; i < sz; ++i) {
        if (filter(i) && buffer[i] == value)
            result.push_back(i);
    }
    return result;
}

template <typename T>
bool equal_unordered(const T* buffer, const std::list<T>& l) {
    std::unordered_map<T, std::size_t> table;

    for (const auto& e : l) {
        auto foundIt = table.find(e);
        if (foundIt == table.end()) {
            auto res = table.insert(std::make_pair(e, 0));
            assert(res.second);
            foundIt = res.first;
        }

        foundIt->second += 1;
    }

    for (const auto& p : table) {
        std::size_t nb = count_all(buffer, l.size(), p.first);
        if (p.second != nb)
            return false;
    }

    return true;
}



}
}


#define fontomas__test(TestFunc) fontomas::testing::Test{ TestFunc, #TestFunc }


template <typename Tin>
inline constexpr std::size_t CountOf() {
    using T = typename std::remove_reference_t<Tin>;
    static_assert(std::is_array_v<T>,
        "CountOf() requires an array argument");
    static_assert(std::extent_v<T> > 0,
        "zero- or unknown-size array");
    return std::extent_v<T>;
}

#define CountOf(a)          CountOf<decltype(a)>()
#define CountOf32(a) ((ui32)CountOf<decltype(a)>())


#define fontomas__tests_suit_begin(SuitName)                                    \
void add_suit_ ## SuitName (std::list< fontomas::testing::Test >& allTests);    \
namespace { static const fontomas::testing::Test s_ ## SuitName ## Tests[] = {

#define fontomas__tests_suit_end(SuitName)                                      \
};}                                                                             \
void add_suit_ ## SuitName (std::list< fontomas::testing::Test >& allTests) {   \
    for (std::size_t i = 0, nb = CountOf(s_ ## SuitName ## Tests); i < nb; ++i) \
        allTests.push_back(s_ ## SuitName ## Tests[i]);                         \
}


#define fontomas__enable_suit(SuitName, TestsList)                              \
    extern void add_suit_ ## SuitName (std::list< fontomas::testing::Test >&);  \
    add_suit_ ## SuitName (TestsList)


#define fontomas__check_equal(ExprA, ExprB)                                     \
    if ( (ExprA) != (ExprB) ) {                                                 \
        LOG.format("check_equal failed in %s at %d (%d)\n",                     \
                   __FILE__, __LINE__, __COUNTER__);                            \
        return false;                                                           \
    }

#define fontomas__check_notequal(ExprA, ExprB)                                  \
    if ( (ExprA) == (ExprB) ) {                                                 \
        LOG.format("check_notequal failed in %s at %d (%d)\n",                  \
                   __FILE__, __LINE__, __COUNTER__);                            \
        return false;                                                           \
    }

#define fontomas__check_contains(Container, Key)                                \
    if ( !fontomas::testing::check_contains(Container, Key) ) {                 \
        LOG.format("check_contains failed in %s at %d (%d)\n",                  \
                   __FILE__, __LINE__, __COUNTER__);                            \
        return false;                                                           \
    }

#define fontomas__check_notnull(Container, Key)                                 \
    if ( !fontomas::testing::check_notnull(Container, Key) ) {                  \
        LOG.format("check_notnull failed in %s at %d (%d)\n",                   \
                   __FILE__, __LINE__, __COUNTER__);                            \
        return false;                                                           \
    }

#define fontomas__check_true(Expr)                                              \
    if ( !(Expr) ) {                                                            \
        LOG.format("check_true failed in %s at %d (%d)\n",                      \
                   __FILE__, __LINE__, __COUNTER__);                            \
        return false;                                                           \
    }

#define fontomas__check_false(Expr)                                             \
    if ( !!(Expr) ) {                                                           \
        LOG.format("check_false failed in %s at %d (%d)\n",                     \
                   __FILE__, __LINE__, __COUNTER__);                            \
        return false;                                                           \
    }


#define LOG fontomas::testing::Log::Instance()


#endif//FONTOMAS_TST_TESTSGLOBALS_H_
