#pragma once
#ifndef FONTOMAS_DI_H_
#define FONTOMAS_DI_H_


#include <memory>
#include <unordered_map>
#include <mutex>

#include <fontomas/debug.h>
#include <fontomas/exports.h>


namespace fontomas { ;



class fontomas_public DIContainer final {
public:
    template <class Interface, typename Impl, typename... Args>
    void registerService(Args &&... args) noexcept {
        auto foundIt = _serviceTable.find(Interface::sServiceName);
        if (foundIt != _serviceTable.end()) {
            _serviceTable.erase(foundIt);
        }

        auto res = _serviceTable.insert(std::make_pair(Interface::sServiceName,
            ServiceHolder<Interface>::template New<Impl>(std::forward<Args>(args)...)));
        if (!res.second) {
            // failed to register - just break the execution
            fontomas__hardbreak;
        }
    }

    template <class Interface>
    std::shared_ptr<Interface> resolveService() noexcept {
        auto foundIt = _serviceTable.find(Interface::sServiceName);
        if (foundIt == _serviceTable.end())
            // let the callee to decide, what to do if service was not found
            return std::shared_ptr<Interface>();

        return static_cast<ServiceHolder<Interface>*>(foundIt->second.get())->pService;
    }

    template <typename ServiceUser, typename... Args>
    typename ServiceUser::Ptr resolve(Args &&... args) noexcept {
        using ServiceUserPtr = typename ServiceUser::Ptr;
        return ServiceUserPtr(new ServiceUser(*this, std::forward<typename std::remove_reference<Args>::type>(args)...));
    }

    template <typename ServiceUser>
    bool setup(ServiceUser& user) noexcept {
        return user.setupServices(*this);
    }

private:
    friend class DITester;

    struct BaseHolder {
        using Ptr = std::unique_ptr<BaseHolder>;

        virtual ~BaseHolder() noexcept {}
    };

    template <class Service>
    struct ServiceHolder : BaseHolder {
        std::shared_ptr<Service> pService;

        template <class Impl, typename... Args>
        static Ptr New(Args &&... args) noexcept {
            Service* pImpl = new Impl(std::forward<typename std::remove_reference<Args>::type>(args)...);
            return Ptr(new ServiceHolder(pImpl));
        }

        explicit ServiceHolder(Service* pImpl)
            : pService(pImpl)
        {}
    };

    std::unordered_map<const char*, BaseHolder::Ptr> _serviceTable;
};



}


#define fontomas__provide_as_singleton(Interface, T, ...)                       \
    namespace fontomas_client {                                                 \
        namespace Interface##DI {                                               \
            static Interface& GetInstance() noexcept {                          \
                static T sInstance = T(__VA_ARGS__);                            \
                return sInstance;                                               \
            }                                                                   \
            struct Factory {                                                    \
                Interface& get() noexcept { return GetInstance(); }             \
            };                                                                  \
        }                                                                       \
    }


#define fontomas__provide_as_shared(Interface, T, ...)                          \
    namespace fontomas_client {                                                 \
        namespace Interface##DI {                                               \
            struct Factory {                                                    \
                Factory() {                                                     \
                    std::unique_lock<std::mutex> lock(sObjectM);                \
                    if (!sObject) sObject.reset(new T(__VA_ARGS__));            \
                }                                                               \
                Interface& get() noexcept { return *sObject; }                  \
                static std::shared_ptr<T> sObject;                              \
                static std::mutex sObjectM;                                     \
            };                                                                  \
            std::shared_ptr<T> Factory::sObject;                                \
            std::mutex Factory::sObjectM;                                       \
        }                                                                       \
    }


#define fomtomas__provide_as_local(Interface)                                   \
    namespace fontomas_client {                                                 \
        namespace Interface##DI {                                               \
            struct Factory {                                                    \
                Interface& get() noexcept { return *sObject; }                  \
                static Interface* sObject;                                      \
            };                                                                  \
            Interface* Factory::sObject = 0;                                    \
        }                                                                       \
    }

#define fontomas__provide(Interface, Object)                                    \
    fontomas_client:: Interface##DI::Factory::sObject = Object;


#define fontomas__inject(Interface, Field)                                      \
    struct Interface##Proxy {                                                   \
        Interface* operator ->() noexcept { return &factory.get(); }            \
        fontomas_client:: Interface##DI::Factory factory;                       \
    } Field;


#endif//FONTOMAS_DI_H_
