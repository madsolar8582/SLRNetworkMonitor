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

@import XCTest;
@import SLRNetworkMonitor;

NS_ASSUME_NONNULL_BEGIN

@interface SLRNetworkMonitor (XCTest)

@property (atomic, assign, readwrite) SLRNetworkMonitorType monitorType;

@property (atomic, strong, nullable, readwrite) nw_path_t currentPath;

@property (atomic, strong) nw_path_monitor_t networkMonitor;

@property (atomic, strong) dispatch_queue_t workQueue;

@property (atomic, strong) dispatch_queue_t notificationQueue;

- (void)postNotification:(NSNotificationName)notification withUserInfo:(nullable NSDictionary<id, id> *)userInfo;

@end

@interface SLRNetworkMonitorTests : XCTestCase

@end

@implementation SLRNetworkMonitorTests

/**
 * Verifies that the init method sets up the monitor correctly.
 */
- (void)testInit
{
    SLRNetworkMonitor *monitor = [[SLRNetworkMonitor alloc] init];
    
    XCTAssertNotNil(monitor);
    XCTAssertNotNil(monitor.networkMonitor);
    XCTAssertEqualObjects(@(dispatch_queue_get_label(monitor.workQueue)), ([NSString stringWithFormat:@"com.solarana.network.monitor-%p", monitor]));
    int queuePriority;
    XCTAssertEqual(dispatch_queue_get_qos_class(monitor.workQueue, &queuePriority), QOS_CLASS_UTILITY);
    XCTAssertEqual(queuePriority, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    XCTAssertEqualObjects(monitor.notificationQueue, dispatch_get_main_queue());
    XCTAssertEqual(monitor.monitorType, SLRNetworkMonitorTypeAll);
    XCTAssertNil(monitor.currentPath);
}

/**
 * Verifies that the initWithMonitorType:workQueue:notificationQueue method sets up the monitor correctly.
 */
- (void)testInitWithMonitorTypeWorkQueueNotificationQueue
{
    dispatch_queue_attr_t qosAttributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, DISPATCH_QUEUE_PRIORITY_LOW);
    dispatch_queue_t queue = dispatch_queue_create("com.solarana.test.queue", qosAttributes);
    SLRNetworkMonitor *monitor = [[SLRNetworkMonitor alloc] initWithMonitorType:SLRNetworkMonitorTypeWiFi workQueue:queue notificationQueue:dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)];
    
    XCTAssertNotNil(monitor);
    XCTAssertNotNil(monitor.networkMonitor);
    XCTAssertEqualObjects(@(dispatch_queue_get_label(monitor.workQueue)), @"com.solarana.test.queue");
    int queuePriority;
    XCTAssertEqual(dispatch_queue_get_qos_class(monitor.workQueue, &queuePriority), QOS_CLASS_BACKGROUND);
    XCTAssertEqual(queuePriority, DISPATCH_QUEUE_PRIORITY_LOW);
    XCTAssertEqualObjects(monitor.notificationQueue, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0));
    XCTAssertEqual(monitor.monitorType, SLRNetworkMonitorTypeWiFi);
    XCTAssertNil(monitor.currentPath);
}

/**
 * Verifies that the monitor class method sets up the monitor correctly.
 */
- (void)testMonitor
{
    SLRNetworkMonitor *monitor = [SLRNetworkMonitor monitor];
    
    XCTAssertNotNil(monitor);
    XCTAssertNotNil(monitor.networkMonitor);
    XCTAssertEqualObjects(@(dispatch_queue_get_label(monitor.workQueue)), ([NSString stringWithFormat:@"com.solarana.network.monitor-%p", monitor]));
    int queuePriority;
    XCTAssertEqual(dispatch_queue_get_qos_class(monitor.workQueue, &queuePriority), QOS_CLASS_UTILITY);
    XCTAssertEqual(queuePriority, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    XCTAssertEqualObjects(monitor.notificationQueue, dispatch_get_main_queue());
    XCTAssertEqual(monitor.monitorType, SLRNetworkMonitorTypeAll);
    XCTAssertNil(monitor.currentPath);
}

/**
 * Verifies that the monitorWithType:workQueue:notificationQueue sets up the monitor correctly.
 */
- (void)testMonitorWithTypeWorkQueueNotificationQueue
{
    dispatch_queue_attr_t qosAttributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, DISPATCH_QUEUE_PRIORITY_LOW);
    dispatch_queue_t queue = dispatch_queue_create("com.solarana.test.queue", qosAttributes);
    SLRNetworkMonitor *monitor = [SLRNetworkMonitor monitorWithType:SLRNetworkMonitorTypeWiFi workQueue:queue notificationQueue:dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)];
    
    XCTAssertNotNil(monitor);
    XCTAssertNotNil(monitor.networkMonitor);
    XCTAssertEqualObjects(@(dispatch_queue_get_label(monitor.workQueue)), @"com.solarana.test.queue");
    int queuePriority;
    XCTAssertEqual(dispatch_queue_get_qos_class(monitor.workQueue, &queuePriority), QOS_CLASS_BACKGROUND);
    XCTAssertEqual(queuePriority, DISPATCH_QUEUE_PRIORITY_LOW);
    XCTAssertEqualObjects(monitor.notificationQueue, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0));
    XCTAssertEqual(monitor.monitorType, SLRNetworkMonitorTypeWiFi);
    XCTAssertNil(monitor.currentPath);
}

/**
 * Verifies that the SLRNetworkMonitorDidStartMonitoringNotification notification is fired when the monitor starts.
 */
- (void)testStartMonitoring
{
    SLRNetworkMonitor *monitor = [SLRNetworkMonitor monitor];
    __unused XCTestExpectation *startMonitoringExpectation = [self expectationForNotification:SLRNetworkMonitorDidStartMonitoringNotification object:monitor handler:nil];
    
    [monitor startMonitoring];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 * Verifies that the SLRNetworkMonitorDidStopMonitoringNotification notification is fired when the monitor stops.
 */
- (void)testStopMonitoring
{
    SLRNetworkMonitor *monitor = [SLRNetworkMonitor monitor];
    __unused XCTestExpectation *stopMonitoringExpectation = [self expectationForNotification:SLRNetworkMonitorDidStopMonitoringNotification object:monitor handler:nil];
    
    [monitor stopMonitoring];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 * Verifies that the postNotification:withUserInfo method successfully posts the notification.
 */
- (void)testPostNotificationWithUserInfo
{
    SLRNetworkMonitor *monitor = [SLRNetworkMonitor monitor];
    __unused XCTestExpectation *notificationExpectation = [self expectationForNotification:@"com.solarana.test.notification" object:monitor handler:^BOOL(NSNotification *_Nonnull notification) {
        return [notification.object isEqual:monitor] && [notification.userInfo isEqualToDictionary:@{@"test" : @"test"}];
    }];
    
    [monitor postNotification:@"com.solarana.test.notification" withUserInfo:@{@"test" : @"test"}];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

@end

NS_ASSUME_NONNULL_END
