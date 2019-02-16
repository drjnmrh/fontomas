#include "fontomas/di.h"

#include <list>

#include "testsglobals.h"


bool test__di__dicontainer_registerservice();
bool test__di__dicontainer_resolveservice();
bool test__di__dicontainer_resolve();


fontomas__tests_suit_begin(DI)
    fontomas__test(test__di__dicontainer_registerservice),
    fontomas__test(test__di__dicontainer_resolveservice),
    fontomas__test(test__di__dicontainer_resolve)
fontomas__tests_suit_end(DI);


namespace fontomas { ;

class DITester {
public:
    static std::unordered_map<const char*, DIContainer::BaseHolder::Ptr>& table(DIContainer& di) noexcept {
        return di._serviceTable;
    }
    
    template <typename Service>
    static Service* getEntry(DIContainer& di) noexcept {
        return static_cast<DIContainer::ServiceHolder<Service>*>(table(di)[Service::sServiceName].get())->pService.get();
    }
};

}


namespace {

    class TestService1 {
    public:
        constexpr static const char* sServiceName = "TestService1";

        virtual ~TestService1() noexcept {}
        
        virtual const char* getClassName() const noexcept = 0;
        virtual void doSomething() noexcept = 0;
    };

    class TestService1MocA : public TestService1 {
    public:
        const char* getClassName() const noexcept override { return "TestService1MocA"; }
        void doSomething() noexcept override {}
    };
    
    class TestService1MocB : public TestService1 {
    public:
        const char* getClassName() const noexcept override { return "TestService1MocB"; }
        void doSomething() noexcept override {}
    };
    
    
    class TestService2 {
    public:
        constexpr static const char* sServiceName = "TestService2";
        
        virtual ~TestService2() noexcept {}
        
        virtual const char* getClassName() const noexcept = 0;
        virtual void doSomething() noexcept = 0;
    };
    
    class TestService2MocA : public TestService2 {
    public:
        const char* getClassName() const noexcept override { return "TestService2MocA"; }
        void doSomething() noexcept override {}
    };
    
    class TestService2MocB : public TestService2 {
    public:
        const char* getClassName() const noexcept override { return "TestService2MocB"; }
        void doSomething() noexcept override {}
    };
    
    
    class ServicesUser1 {
    public:
        using Ptr = std::unique_ptr<ServicesUser1>;
        
        std::shared_ptr<TestService1> pService1;
        std::shared_ptr<TestService2> pService2;
        
        explicit ServicesUser1(fontomas::DIContainer& di)
            : pService1(di.resolveService<TestService1>())
            , pService2(di.resolveService<TestService2>())
        {}
    };

}


bool test__di__dicontainer_registerservice() {
    using namespace fontomas;

    DIContainer dicontainer;
    dicontainer.registerService<TestService1, TestService1MocA>();

    auto& table = DITester::table(dicontainer);
    fontomas__check_equal(table.size(), 1);
    fontomas__check_contains(table, TestService1::sServiceName);
    fontomas__check_notnull(table, TestService1::sServiceName);
    
    fontomas__check_notequal(DITester::getEntry<TestService1>(dicontainer), nullptr);
    fontomas__check_equal(DITester::getEntry<TestService1>(dicontainer)->getClassName(), "TestService1MocA");
    
    dicontainer.registerService<TestService1, TestService1MocB>();
    fontomas__check_equal(table.size(), 1);
    fontomas__check_contains(table, TestService1::sServiceName);
    fontomas__check_notnull(table, TestService1::sServiceName);
    
    fontomas__check_notequal(DITester::getEntry<TestService1>(dicontainer), nullptr);
    fontomas__check_equal(DITester::getEntry<TestService1>(dicontainer)->getClassName(), "TestService1MocB");
    
    dicontainer.registerService<TestService2, TestService2MocA>();
    fontomas__check_equal(table.size(), 2);
    fontomas__check_contains(table, TestService1::sServiceName);
    fontomas__check_notnull(table, TestService1::sServiceName);
    fontomas__check_contains(table, TestService2::sServiceName);
    fontomas__check_notnull(table, TestService2::sServiceName);
    
    fontomas__check_notequal(DITester::getEntry<TestService1>(dicontainer), nullptr);
    fontomas__check_equal(DITester::getEntry<TestService1>(dicontainer)->getClassName(), "TestService1MocB");
    
    fontomas__check_notequal(DITester::getEntry<TestService2>(dicontainer), nullptr);
    fontomas__check_equal(DITester::getEntry<TestService2>(dicontainer)->getClassName(), "TestService2MocA");
    
    dicontainer.registerService<TestService2, TestService2MocB>();
    fontomas__check_equal(table.size(), 2);
    fontomas__check_contains(table, TestService1::sServiceName);
    fontomas__check_notnull(table, TestService1::sServiceName);
    fontomas__check_contains(table, TestService2::sServiceName);
    fontomas__check_notnull(table, TestService2::sServiceName);
    
    fontomas__check_notequal(DITester::getEntry<TestService1>(dicontainer), nullptr);
    fontomas__check_equal(DITester::getEntry<TestService1>(dicontainer)->getClassName(), "TestService1MocB");
    
    fontomas__check_notequal(DITester::getEntry<TestService2>(dicontainer), nullptr);
    fontomas__check_equal(DITester::getEntry<TestService2>(dicontainer)->getClassName(), "TestService2MocB");

    return true;
}

bool test__di__dicontainer_resolveservice() {
    using namespace fontomas;
    
    DIContainer dicontainer;
    
    fontomas__check_equal(dicontainer.resolveService<TestService1>().get(), nullptr);
    
    dicontainer.registerService<TestService1, TestService1MocA>();
    fontomas__check_notequal(dicontainer.resolveService<TestService1>().get(), nullptr);
    fontomas__check_equal(dicontainer.resolveService<TestService1>()->getClassName(), "TestService1MocA");
    
    dicontainer.registerService<TestService1, TestService1MocB>();
    fontomas__check_notequal(dicontainer.resolveService<TestService1>().get(), nullptr);
    fontomas__check_equal(dicontainer.resolveService<TestService1>()->getClassName(), "TestService1MocB");
    
    dicontainer.registerService<TestService2, TestService2MocA>();
    fontomas__check_notequal(dicontainer.resolveService<TestService1>().get(), nullptr);
    fontomas__check_equal(dicontainer.resolveService<TestService1>()->getClassName(), "TestService1MocB");
    fontomas__check_notequal(dicontainer.resolveService<TestService2>().get(), nullptr);
    fontomas__check_equal(dicontainer.resolveService<TestService2>()->getClassName(), "TestService2MocA");
    
    return true;
}

bool test__di__dicontainer_resolve() {
    using namespace fontomas;
    
    DIContainer dicontainer;
    
    ServicesUser1::Ptr pUser1 = dicontainer.resolve<ServicesUser1>();
    fontomas__check_notequal(pUser1.get(), nullptr);
    fontomas__check_equal(pUser1->pService1.get(), nullptr);
    fontomas__check_equal(pUser1->pService2.get(), nullptr);
    
    dicontainer.registerService<TestService1, TestService1MocA>();
    pUser1 = dicontainer.resolve<ServicesUser1>();
    fontomas__check_notequal(pUser1.get(), nullptr);
    fontomas__check_notequal(pUser1->pService1.get(), nullptr);
    fontomas__check_equal(pUser1->pService1->getClassName(), "TestService1MocA");
    fontomas__check_equal(pUser1->pService2.get(), nullptr);
    
    dicontainer.registerService<TestService1, TestService1MocB>();
    pUser1 = dicontainer.resolve<ServicesUser1>();
    fontomas__check_notequal(pUser1.get(), nullptr);
    fontomas__check_notequal(pUser1->pService1.get(), nullptr);
    fontomas__check_equal(pUser1->pService1->getClassName(), "TestService1MocB");
    fontomas__check_equal(pUser1->pService2.get(), nullptr);
    
    dicontainer.registerService<TestService2, TestService2MocA>();
    pUser1 = dicontainer.resolve<ServicesUser1>();
    fontomas__check_notequal(pUser1.get(), nullptr);
    fontomas__check_notequal(pUser1->pService1.get(), nullptr);
    fontomas__check_equal(pUser1->pService1->getClassName(), "TestService1MocB");
    fontomas__check_notequal(pUser1->pService2.get(), nullptr);
    fontomas__check_equal(pUser1->pService2->getClassName(), "TestService2MocA");
    
    return true;
}
