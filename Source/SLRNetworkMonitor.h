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

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#if __has_feature(modules)
@import Network;
#else
#import <Network/Network.h>
#endif

#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Convenience typedef for user info keys in notifications posted from instances of @c SLRNetworkMonitor.
 */
typedef NSString *SLRNetworkMonitorUserInfoKey NS_TYPED_ENUM;

/**
 * Notification posted when an instance of @c SLRNetworkMonitor begins monitoring the device's network connectivity status.
 */
FOUNDATION_EXPORT NSNotificationName const SLRNetworkMonitorDidStartMonitoringNotification;

/**
 * Notification posted when an instance of @c SLRNetworkMonitor stops monitoring the device's network connectivity status.
 */
FOUNDATION_EXPORT NSNotificationName const SLRNetworkMonitorDidStopMonitoringNotification;

/**
 * Notification posted when an instance of @c SLRNetworkMonitor detects a change in the device's network connectivity status. Details are in the @c userInfo object.
 */
FOUNDATION_EXPORT NSNotificationName const SLRNetworkMonitorNetworkStateDidChangeNotification;

/**
 * Notification user info key that contains the current network connectivity status (@c nw_path_status_t) wrapped in a @c NSNumber.
 */
FOUNDATION_EXPORT SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkStatusKey;

/**
 * Notification user info key that contains a boolean of whether or not the current network uses WiFi wrapped in a @c NSNumber.
 */
FOUNDATION_EXPORT SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkUsesWiFiKey;

/**
 * Notification user info key that contains a boolean of whether or not the current network uses Cellular wrapped in a @c NSNumber.
 */
FOUNDATION_EXPORT SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkUsesCellularKey;

/**
 * Notification user info key that contains a boolean of whether or not the current network uses Ethernet wrapped in a @c NSNumber.
 */
FOUNDATION_EXPORT SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkUsesWiredKey;

/**
 * Notification user info key that contains a boolean of whether or not the current network uses an expensive route wrapped in a @c NSNumber.
 */
FOUNDATION_EXPORT SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkIsExpensiveKey;

/**
 * Notification user info key that contains a boolean of whether or not the current network supports IPv4 wrapped in a @c NSNumber.
 */
FOUNDATION_EXPORT SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkSupportsIPv4Key;

/**
 * Notification user info key that contains a boolean of whether or not the current network supports IPv6 wrapped in a @c NSNumber.
 */
FOUNDATION_EXPORT SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkSupportsIPv6Key;

/**
 * Notification user info key that contains a boolean of whether or not the current network has a DNS configuration wrapped in a @c NSNumber.
 */
FOUNDATION_EXPORT SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkHasDNSKey;

/**
 * Notification user info key that contains a boolean of whether or not the current network is constrained.
 */
FOUNDATION_EXPORT SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorNetworkIsConstrainedKey API_AVAILABLE(macos(10.15), ios(13.0), watchos(6.0), tvos(13.0));

/**
 * Notification user info key that contains a @c NSDictionary of interface names (@c NSString) to a @c NSArray of their usable address(es).
 */
FOUNDATION_EXPORT SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorUsableInterfacesKey;

/**
 * Notification user info key that contains a @c NSArray of DNS server addresses as @c NSStrings.
 */
FOUNDATION_EXPORT SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorDNSServersKey;

#if TARGET_OS_IOS

/**
 * Notification user info key that contains a @c NSDictionary of cellular services (@c NSString) to a @c CTCarrier objects that contain information about the cellular provider.
 */
FOUNDATION_EXPORT SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorCellularProvidersKey;

/**
 * Notification user info key that contains a @c NSDictionary of cellular services (@c NSString) to a @c NSString representation of their active radio technology.
 */
FOUNDATION_EXPORT SLRNetworkMonitorUserInfoKey const SLRNetworkMonitorCellularRadioTechnologiesKey;

#endif

/**
 * @enum SLRNetworkMonitorType
 * Defines the types of @c SLRNetworkMonitors that can be created.
 */
typedef NS_ENUM(NSUInteger, SLRNetworkMonitorType) {
    /// Monitor that only monitors internet connectivity via WiFi.
    SLRNetworkMonitorTypeWiFi = 0,
    /// Monitor that only monitors internet connectivity via Cellular.
    SLRNetworkMonitorTypeCellular,
    /// Monitor that only monitors internet connectivity via Ethernet.
    SLRNetworkMonitorTypeWired,
    /// Monitor that only monitors internet connectivity via any available interface type.
    SLRNetworkMonitorTypeAll
};

/**
 * @class SLRNetworkMonitor
 * Provides a way of monitoring network connectivity on a device.
 * Objects created with the default configuration create their own serial queue to handle events and then use the main queue to post notifications on.
 */
@interface SLRNetworkMonitor : NSObject

/**
 * The type of the monitor.
 */
@property (atomic, assign, readonly) SLRNetworkMonitorType monitorType;

/**
 * The current network path being monitored.
 */
@property (atomic, strong, nullable, readonly) nw_path_t currentPath;

/**
 * Designated initializer that creates a new instance of a @c SLRNetworkMonitor of a specific type, work queue, & notification queue.
 * @note Use @c -init to get the default configuration.
 * @param monitorType       The type of monitor to create.
 * @param workQueue         The queue that handles monitor operations.
 * @param notificationQueue The queue to post status notifications to.
 * @return A new instance of @c SLRNetworkMonitor with the specified configuration.
 */
- (instancetype)initWithMonitorType:(SLRNetworkMonitorType)monitorType workQueue:(nullable dispatch_queue_t)workQueue notificationQueue:(nullable dispatch_queue_t)notificationQueue NS_DESIGNATED_INITIALIZER;

/**
 * Convenience initializer that creates a new instance of a @c SLRNetworkMonitor of a specific type, work queue, & notification queue.
 * @note Use @c +monitor to get the default configuration.
 * @param monitorType       The type of monitor to create.
 * @param workQueue         The queue that handles monitor operations.
 * @param notificationQueue The queue to post status notifications to.
 * @return A new instance of @c SLRNetworkMonitor with the specified configuration.
 */
+ (instancetype)monitorWithType:(SLRNetworkMonitorType)monitorType workQueue:(nullable dispatch_queue_t)workQueue notificationQueue:(nullable dispatch_queue_t)notificationQueue;

/**
 * Convenience initializer that creates a new instance of a @c SLRNetworkMonitor with the default configuration.
 * @return A new instance of @c SLRNetworkMonitor with the default configuration.
 */
+ (instancetype)monitor;

/**
 * Tells a @c SLRNetworkMonitor to begin monitoring for network connectivity status changes.
 */
- (void)startMonitoring;

/**
 * Tells a @c SLRNetworkMonitor to stop monitoring for network connectivity status changes.
 */
- (void)stopMonitoring;

@end    

NS_ASSUME_NONNULL_END
