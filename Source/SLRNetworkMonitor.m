/**
 * Copyright (©) 2019 Madison Solarana
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

#import "SLRNetworkMonitor.h"
#if __has_feature(modules)
@import os.log;
#else
#import <os/log.h>
#endif

#if __has_feature(modules)
@import ObjectiveC.runtime;
#else
#import <objc/runtime.h>
#endif

#if TARGET_OS_IOS
#if __has_feature(modules)
@import CoreTelephony;
#else
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif
#endif

#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/if.h>
#import <resolv.h>
#import <netdb.h>

NS_ASSUME_NONNULL_BEGIN

NSNotificationName const SLRNetworkMonitorDidStartMonitoringNotification = @"com.solarana.network.monitor.SLRNetworkMonitorDidStartMonitoringNotification";
NSNotificationName const SLRNetworkMonitorDidStopMonitoringNotification = @"com.solarana.network.monitor.SLRNetworkMonitorDidStopMonitoringNotification";
NSNotificationName const SLRNetworkMonitorNetworkStateDidChangeNotification = @"com.solarana.network.monitor.SLRNetworkMonitorNetworkStateDidChangeNotification";
SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkStatusKey = @"com.solarana.network.monitor.SLRNetworkMonitorNetworkStatusKey";
SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkUsesWiFiKey = @"com.solarana.network.monitor.SLRNetworkMonitorNetworkUsesWiFiKey";
SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkUsesCellularKey = @"com.solarana.network.monitor.SLRNetworkMonitorNetworkUsesCellularKey";
SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkUsesWiredKey = @"com.solarana.network.monitor.SLRNetworkMonitorNetworkUsesWiredKey";
SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkIsExpensiveKey = @"com.solarana.network.monitor.SLRNetworkMonitorNetworkIsExpensiveKey";
SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkSupportsIPv4Key = @"com.solarana.network.monitor.SLRNetworkMonitorNetworkSupportsIPv4Key";
SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkSupportsIPv6Key = @"com.solarana.network.monitor.SLRNetworkMonitorNetworkSupportsIPv6Key";
SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkHasDNSKey = @"com.solarana.network.monitor.SLRNetworkMonitorNetworkHasDNSKey";
SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorUsableInterfacesKey = @"com.solarana.network.monitor.SLRNetworkMonitorUsableInterfacesKey";
SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorDNSServersKey = @"com.solarana.network.monitor.SLRNetworkMonitorDNSServersKey";
SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkIsConstrainedKey = @"com.solarana.network.monitor.SLRNetworkMonitorNetworkIsConstrainedKey";
SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorCellularProvidersKey = @"com.solarana.network.monitor.SLRNetworkMonitorCellularProvidersKey";
SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorCellularRadioTechnologiesKey = @"com.solarana.network.monitor.SLRNetworkMonitorCellularRadioTechnologiesKey";

@interface SLRNetworkMonitor ()

@property (atomic, assign, readwrite) SLRNetworkMonitorType monitorType;

@property (atomic, strong, nullable, readwrite) nw_path_t currentPath;

/**
 * The path monitor responsible for observing network state changes.
 */
@property (atomic, strong) nw_path_monitor_t networkMonitor;

/**
 * The queue to do operations on.
 */
@property (atomic, strong) dispatch_queue_t workQueue;

/**
 * The queue to post notifications on.
 */
@property (atomic, strong) dispatch_queue_t notificationQueue;

@end

@implementation SLRNetworkMonitor

#pragma mark - Object Lifecycle

- (instancetype)init
{
    return [self initWithMonitorType:SLRNetworkMonitorTypeAll workQueue:nil notificationQueue:nil];
}

- (instancetype)initWithMonitorType:(SLRNetworkMonitorType)monitorType workQueue:(nullable dispatch_queue_t)workQueue notificationQueue:(nullable dispatch_queue_t)notificationQueue
{
    if ((self = [super init])) {
        
        if (!workQueue) {
            dispatch_queue_attr_t qosAttributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, DISPATCH_QUEUE_PRIORITY_DEFAULT);
            dispatch_queue_attr_t queueAttributes = dispatch_queue_attr_make_with_autorelease_frequency(qosAttributes, DISPATCH_AUTORELEASE_FREQUENCY_WORK_ITEM);
            _workQueue = dispatch_queue_create([NSString stringWithFormat:@"com.solarana.network.monitor-%p", self].UTF8String, queueAttributes);
        }
        else {
            _workQueue = workQueue;
        }
        
        if (!notificationQueue) {
            _notificationQueue = dispatch_get_main_queue();
        }
        else {
            _notificationQueue = notificationQueue;
        }
        
        _monitorType = monitorType;
        switch (monitorType) {
            case SLRNetworkMonitorTypeWiFi: {
                _networkMonitor = nw_path_monitor_create_with_type(nw_interface_type_wifi);
                break;
            }
            case SLRNetworkMonitorTypeCellular: {
                _networkMonitor = nw_path_monitor_create_with_type(nw_interface_type_cellular);
                break;
            }
            case SLRNetworkMonitorTypeWired: {
                _networkMonitor = nw_path_monitor_create_with_type(nw_interface_type_wired);
                break;
            }
            case SLRNetworkMonitorTypeAll: {
                _networkMonitor = nw_path_monitor_create();
                break;
            }
        }
        
        nw_path_monitor_set_queue(_networkMonitor, _workQueue);
        
        __weak __auto_type weakSelf = self;
        nw_path_monitor_set_update_handler(_networkMonitor, ^(nw_path_t _Nonnull path) {
            __strong __auto_type strongSelf = weakSelf;
            dispatch_assert_queue_debug(strongSelf.workQueue);
            
            // Get Network Information
            
            strongSelf.currentPath = path;
            nw_path_status_t status = nw_path_get_status(path);
            BOOL usesWiFi = self.monitorType == SLRNetworkMonitorTypeWiFi ? YES : nw_path_uses_interface_type(path, nw_interface_type_wifi);
            BOOL usesCellular = self.monitorType == SLRNetworkMonitorTypeCellular ? YES : nw_path_uses_interface_type(path, nw_interface_type_cellular);
            BOOL usesWired = self.monitorType == SLRNetworkMonitorTypeWired ? YES : nw_path_uses_interface_type(path, nw_interface_type_wired);
            BOOL isExpensive = nw_path_is_expensive(path);
            BOOL supportsIPv4 = nw_path_has_ipv4(path);
            BOOL supportsIPv6 = nw_path_has_ipv6(path);
            BOOL hasDNS = nw_path_has_dns(path);
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
            BOOL isConstrained = NO;
            if (@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)) {
                isConstrained = nw_path_is_constrained(path);
            }
#endif
            NSArray<NSString *> *usableInterfaces;
            NSArray<NSString *> *dnsServers;
            NSDictionary<NSString *, NSArray<NSString *> *> *interfaceAddresses;
#if TARGET_OS_IOS
            NSDictionary<NSString *, NSString *> *currentCellStatuses;
            NSDictionary<NSString *, CTCarrier *> *currentCellProviders;
#endif
            
            /**
             * It would be nice if there was an API on nw_path_t to:
             * 1 - Get the interface being used.
             * 2 - Get the address(es) for said interface.
             * 3 - Get the address(es) of the DNS servers for said interface.
             *
             * I logged rdar://44799529 to Apple to see if they would add these features. They declined.
             * Apple said that they consciously decided to not expose the address information as they don't want consumers making decisions based on those addresses.
             * They suggested to create a nw_connection_t and then copy the path from the connection, but that takes too much time as this needs to be non-blocking.
             *
             * So, to make a best guess approximation, we can enumerate through the interfaces on the path and then get the address(es) from the BSD socket API.
             */
            if (status == nw_path_status_satisfied) {
                usableInterfaces = [SLRNetworkMonitor usableInterfacesForPath:path usesWiFi:usesWiFi usesCellular:usesCellular usesWired:usesWired];
                interfaceAddresses = [SLRNetworkMonitor interfaceAddressesForInterfaces:usableInterfaces];
                
                if (hasDNS) {
                    dnsServers = [SLRNetworkMonitor activeDNSServers];
                }
                
#if TARGET_OS_IOS
                if (usesCellular) {
                    CTTelephonyNetworkInfo *cellNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
                    currentCellStatuses = cellNetworkInfo.serviceCurrentRadioAccessTechnology;
                    currentCellProviders = cellNetworkInfo.serviceSubscriberCellularProviders;
                }
#endif
            }
            
            // Post Update
            
            NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary dictionaryWithCapacity:10];
            userInfo[SLRNetworkMonitorNetworkStatusKey] = @(status);
            userInfo[SLRNetworkMonitorNetworkUsesWiFiKey] = @(usesWiFi);
            userInfo[SLRNetworkMonitorNetworkUsesCellularKey] = @(usesCellular);
            userInfo[SLRNetworkMonitorNetworkUsesWiredKey] = @(usesWired);
            userInfo[SLRNetworkMonitorNetworkIsExpensiveKey] = @(isExpensive);
            userInfo[SLRNetworkMonitorNetworkSupportsIPv4Key] = @(supportsIPv4);
            userInfo[SLRNetworkMonitorNetworkSupportsIPv6Key] = @(supportsIPv6);
            userInfo[SLRNetworkMonitorNetworkHasDNSKey] = @(hasDNS);
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
            if (@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)) {
                userInfo[SLRNetworkMonitorNetworkIsConstrainedKey] = @(isConstrained);
            }
#endif
            userInfo[SLRNetworkMonitorUsableInterfacesKey] = interfaceAddresses ?: @{};
            userInfo[SLRNetworkMonitorDNSServersKey] = dnsServers ?: @[];
#if TARGET_OS_IOS
            userInfo[SLRNetworkMonitorCellularProvidersKey] = currentCellProviders ?: @{};
            userInfo[SLRNetworkMonitorCellularRadioTechnologiesKey] = currentCellStatuses ?: @{};
#endif
            
            os_log_info(OS_LOG_DEFAULT, "<%{public}s: %p> network connectivity status changed to %d", class_getName([strongSelf class]), strongSelf, status);
            [strongSelf postNotification:SLRNetworkMonitorNetworkStateDidChangeNotification withUserInfo:[userInfo copy]];
        });
        
        nw_path_monitor_set_cancel_handler(_networkMonitor, ^{
            __strong __auto_type strongSelf = weakSelf;
            dispatch_assert_queue_debug(strongSelf.workQueue);
            [strongSelf postNotification:SLRNetworkMonitorDidStopMonitoringNotification withUserInfo:nil];
        });
    }
    
    return self;
}

+ (instancetype)monitorWithType:(SLRNetworkMonitorType)monitorType workQueue:(nullable dispatch_queue_t)workQueue notificationQueue:(nullable dispatch_queue_t)notificationQueue
{
    return [[self alloc] initWithMonitorType:monitorType workQueue:workQueue notificationQueue:notificationQueue];
}

+ (instancetype)monitor
{
    return [[self alloc] initWithMonitorType:SLRNetworkMonitorTypeAll workQueue:nil notificationQueue:nil];
}

- (void)dealloc
{
    [self stopMonitoring];
}

#pragma mark - NSObject

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%s: %p> {\n\tMonitor Type: %lu\n\tMonitor: %@\n\tWork Queue: %@\n\tNotification Queue: %@\n\tCurrent Path: %@\n}",
            class_getName([self class]),
            self,
            (unsigned long)self.monitorType,
            self.networkMonitor,
            self.workQueue,
            self.notificationQueue,
            self.currentPath];
}

#pragma mark - Public API

- (void)startMonitoring
{
    os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> starting network monitoring", class_getName([self class]), self);
    nw_path_monitor_start(self.networkMonitor);
    [self postNotification:SLRNetworkMonitorDidStartMonitoringNotification withUserInfo:nil];
}

- (void)stopMonitoring
{
    os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> stopping network monitoring", class_getName([self class]), self);
    nw_path_monitor_cancel(self.networkMonitor);
}

#pragma mark - Private API

/**
 * Determines the interfaces that a path uses.
 * @param path         The path to examine.
 * @param usesWiFi     Boolean flag indicating whether or not the path uses WiFi.
 * @param usesCellular Boolean flag indicating whether or not the path uses Cellular.
 * @param usesWired    Boolean flag indicating whether or not the path uses Ethernet.
 * @return An array of interfaces that the path uses.
 */
+ (NSArray<NSString *> *)usableInterfacesForPath:(nw_path_t)path usesWiFi:(BOOL)usesWiFi usesCellular:(BOOL)usesCellular usesWired:(BOOL)usesWired
{
    NSParameterAssert(path != nil);
    
    /**
     * This is not (currently) a concurrent operation. If it turns into one, a read/write lock is necessary so that the mutable array doesn't crash.
     * Interfaces are enumerated in order of preference determined by the path.
     * Because we don't know the exact interface, we cannot optimize by returning early when we find one matching interface since devices could have multiple interfaces for a given type.
     */
    __block NSMutableArray<NSString *> *usableInterfaces = [NSMutableArray array];
    nw_path_enumerate_interfaces(path, ^bool(nw_interface_t _Nonnull interface) {
        NSString *interfaceName = @(nw_interface_get_name(interface));
        nw_interface_type_t interfaceType = nw_interface_get_type(interface);
        
        if (usesWiFi && interfaceType == nw_interface_type_wifi) {
            os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> Adding interface %{public}@ as a viable WiFi interface", class_getName([self class]), self, interfaceName);
            [usableInterfaces addObject:interfaceName];
        }
        else if (usesCellular && interfaceType == nw_interface_type_cellular) {
            os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> Adding interface %{public}@ as a viable Cellular interface", class_getName([self class]), self, interfaceName);
            [usableInterfaces addObject:interfaceName];
        }
        else if (usesWired && interfaceType == nw_interface_type_wired) {
            os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> Adding interface %{public}@ as a viable Wired interface", class_getName([self class]), self, interfaceName);
            [usableInterfaces addObject:interfaceName];
        }
        else {
            // This is a VPN or Loopback interface. VPNs will ultimately use another interface and Loopbacks don't give us Internet connectivity, so ignore.
            os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> Skipping interface %{public}@ as a viable interface", class_getName([self class]), self, interfaceName);
        }
        
        return true;
    });
    
    os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> Found %lu interfaces to examine", class_getName([self class]), self, (unsigned long)usableInterfaces.count);
    return [usableInterfaces copy];
}

/**
 * Obtains the addresses for the specified interfaces.
 * @param interfaces The interfaces to get addresses for.
 * @return A dictionary containing mappings for interfaces and their addresses.
 */
+ (NSDictionary<NSString *, NSArray<NSString *> *> *)interfaceAddressesForInterfaces:(NSArray<NSString *> *)interfaces
{
    NSParameterAssert(interfaces != nil);
    
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *interfaceAddresses = [NSMutableDictionary dictionaryWithCapacity:interfaces.count];
    struct ifaddrs *deviceInterfaces = NULL;
    struct ifaddrs *currentInterface = NULL;
    
    if (getifaddrs(&deviceInterfaces) == EXIT_SUCCESS) {
        currentInterface = deviceInterfaces;
        
        while (currentInterface) {
            // Skip interfaces that are not active or are loopbacks.
            if (!(currentInterface->ifa_flags & IFF_UP) || (currentInterface->ifa_flags & IFF_LOOPBACK)) {
                currentInterface = currentInterface->ifa_next;
                continue;
            }
            
            NSString *interfaceName = @(currentInterface->ifa_name);
            
            if ([interfaces containsObject:interfaceName]) {
                os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> Checking interface %{public}@ for addresses", class_getName([self class]), self, interfaceName);
                
                NSMutableArray<NSString *> *addressStrings = interfaceAddresses[interfaceName];
                if (!addressStrings) {
                    addressStrings = [NSMutableArray array];
                    interfaceAddresses[interfaceName] = addressStrings;
                }
                
                if (currentInterface->ifa_addr->sa_family == AF_INET) { // IPv4 address
                    char buffer[INET_ADDRSTRLEN];
                    struct sockaddr_in *address = (struct sockaddr_in *)currentInterface->ifa_addr;
                    
                    if (inet_ntop(AF_INET, &(address->sin_addr), buffer, sizeof(buffer))) {
                        NSString *addressString = @(buffer);
                        os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> Adding %{public}@ for interface %{public}@", class_getName([self class]), self, addressString, interfaceName);
                        [addressStrings addObject:addressString];
                    }
                    else {
                        os_log_error(OS_LOG_DEFAULT, "<%{public}s: %p> unable to convert IPv4 address to string for interface %{public}@", class_getName([self class]), self, interfaceName);
                    }
                }
                else if (currentInterface->ifa_addr->sa_family == AF_INET6) { // IPv6 address
                    char buffer[INET6_ADDRSTRLEN];
                    struct sockaddr_in6 *address = (struct sockaddr_in6 *)currentInterface->ifa_addr;
                    
                    if (inet_ntop(AF_INET6, &(address->sin6_addr), buffer, sizeof(buffer))) {
                        NSString *addressString = @(buffer);
                        os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> Adding %{public}@ for interface %{public}@", class_getName([self class]), self, addressString, interfaceName);
                        [addressStrings addObject:addressString];
                    }
                    else {
                        os_log_error(OS_LOG_DEFAULT, "<%{public}s: %p> unable to convert IPv6 address to string for interface %{public}@", class_getName([self class]), self, interfaceName);
                    }
                }
            }
            else {
                os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> Skipping interface %{public}@", class_getName([self class]), self, interfaceName);
            }
            
            currentInterface = currentInterface->ifa_next;
        }
    }
    else {
        os_log_error(OS_LOG_DEFAULT, "<%{public}s: %p> unable to get network interfaces", class_getName([self class]), self);
    }
    
    freeifaddrs(deviceInterfaces);
    
    NSMutableDictionary<NSString *, NSArray<NSString *> *> *result = [NSMutableDictionary dictionaryWithCapacity:interfaceAddresses.count];
    for (NSString *key in interfaceAddresses.allKeys) {
        result[key] = [interfaceAddresses[key] copy];
        os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> Found %lu addresses for interface %{public}@", class_getName([self class]), self, (unsigned long)interfaceAddresses[key].count, key);
    }
    
    return [result copy];
}

/**
 * Obtains the currently configured DNS servers.
 * @return The active DNS servers of the device.
 */
+ (NSArray<NSString *> *)activeDNSServers
{
    NSMutableArray<NSString *> *dnsServers = [NSMutableArray arrayWithCapacity:NI_MAXSERV];
    res_state state = malloc(sizeof(struct __res_state));
    
    if (res_ninit(state) == EXIT_SUCCESS) {
        union res_sockaddr_union servers[NI_MAXSERV];
        int numberOfServersFound = res_getservers(state, servers, NI_MAXSERV);
        
        for (int i = 0; i < numberOfServersFound; i++) {
            union res_sockaddr_union server = servers[i];
            if (server.sin.sin_family == AF_INET) { // IPv4 address
                char buffer[INET_ADDRSTRLEN];
                
                if (inet_ntop(AF_INET, &server.sin.sin_addr, buffer, sizeof(buffer))) {
                    NSString *dnsServer = @(buffer);
                    os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> Adding %{public}@ as a DNS server", class_getName([self class]), self, dnsServer);
                    [dnsServers addObject:dnsServer];
                }
                else {
                    os_log_error(OS_LOG_DEFAULT, "<%{public}s: %p> unable to convert IPv4 address to string for DNS server", class_getName([self class]), self);
                }
            }
            else if (server.sin6.sin6_family == AF_INET6) { // IPv6 address
                char buffer[INET6_ADDRSTRLEN];
                
                if (inet_ntop(AF_INET6, &server.sin6.sin6_addr, buffer, sizeof(buffer))) {
                    NSString *dnsServer = @(buffer);
                    os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> Adding %{public}@ as a DNS server", class_getName([self class]), self, dnsServer);
                    [dnsServers addObject:dnsServer];
                }
                else {
                    os_log_error(OS_LOG_DEFAULT, "<%{public}s: %p> unable to convert IPv6 address to string for DNS server", class_getName([self class]), self);
                }
            }
        }
        
        res_ndestroy(state);
    }
    else {
        os_log_error(OS_LOG_DEFAULT, "<%{public}s: %p> unable to get DNS servers", class_getName([self class]), self);
    }
    
    free(state);
    
    os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> found %lu DNS servers", class_getName([self class]), self, (unsigned long)dnsServers.count);
    return [dnsServers copy];
}

/**
 * Convenience method for posting notifications.
 * @param notification The notification to post.
 * @param userInfo     The user info dictionary to accompany the notification.
 */
- (void)postNotification:(NSNotificationName)notification withUserInfo:(nullable NSDictionary<id, id> *)userInfo
{
    NSParameterAssert(notification != nil);
    os_log_debug(OS_LOG_DEFAULT, "<%{public}s: %p> posting notification: %{public}@", class_getName([self class]), self, notification);
    
    __weak __auto_type weakSelf = self;
    dispatch_async(self.notificationQueue, ^{
        __strong __auto_type strongSelf = weakSelf;
        [NSNotificationCenter.defaultCenter postNotificationName:notification object:strongSelf userInfo:userInfo];
    });
}

@end

NS_ASSUME_NONNULL_END
