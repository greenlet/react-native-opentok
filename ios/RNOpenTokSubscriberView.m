#import <Foundation/Foundation.h>
#import "RNOpenTokSubscriberView.h"

@interface RNOpenTokSubscriberView () <OTSubscriberDelegate>
@end

@implementation RNOpenTokSubscriberView {
//    OTSubscriber *_subscriber;
    NSMutableSet<OTSubscriber *> *_subscribers;
}

@synthesize sessionId = _sessionId;
@synthesize session = _session;

- (void)_init {
    _subscribers = [NSMutableSet new];
}

- (instancetype)init {
    self = [super init];
    [self _init];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self _init];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self _init];
    return self;
}

- (void)didMoveToWindow {
    [super didMoveToSuperview];
    [self mount];
}

- (void)dealloc {
    [self stopObserveSession];
    [self stopObserveConnection];
    [self stopObserveStream];
//    [self cleanupSubscriber];
    [self cleanupSubscribers];
}

- (void)didSetProps:(NSArray<NSString *> *)changedProps {
//    if (_subscriber == nil) {
//        return;
//    }
//
//    if ([changedProps containsObject:@"mute"]) {
//        _subscriber.subscribeToAudio = !_mute;
//    }
//
//    if ([changedProps containsObject:@"video"]) {
//        _subscriber.subscribeToVideo = _video;
//    }
    
    for (OTSubscriber *subscriber in _subscribers) {
        if ([changedProps containsObject:@"mute"]) {
            subscriber.subscribeToAudio = !_mute;
        }
        
        if ([changedProps containsObject:@"video"]) {
            subscriber.subscribeToVideo = _video;
        }
    }
}


#pragma mark - Private methods


- (void)mount {
    [self observeSession];
    [self observeConnection];
    [self observeStream];
    if (!_session) {
        [self connectToSession];
    }
}

- (void)onSessionDisconnect {
    [self cleanupSubscribers];
}

- (void)observeConnection {
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(onSessionDisconnect)
     name:[@"session-did-connect:" stringByAppendingString:_sessionId]
     object:nil];
}

- (void)stopObserveConnection {
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:[@"session-did-connect:" stringByAppendingString:_sessionId]
     object:nil];
}


- (void)doSubscribe:(OTStream*)stream {
//    [self unsubscribe];
//    _subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
//    _subscriber.subscribeToAudio = !_mute;
//    _subscriber.subscribeToVideo = _video;
//
//    OTError *error = nil;
//    [_session subscribe:_subscriber error:&error];
//
//    if (error) {
//        [self subscriber:_subscriber didFailWithError:error];
//        return;
//    }
//
//    [self attachSubscriberView];
    
    OTSubscriber *subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
    subscriber.subscribeToAudio = !_mute;
    subscriber.subscribeToVideo = _video;
    
    OTError *error = nil;
    [_session subscribe:subscriber error:&error];
    
    if (error) {
        [self subscriber:subscriber didFailWithError:error];
        return;
    }
    
    [_subscribers addObject:subscriber];

}

//- (void)unsubscribe {
//    OTError *error = nil;
//    [_session unsubscribe:_subscriber error:&error];
//
//    if (error) {
//        NSLog(@"%@", error);
//    }
//}
//
//- (void)attachSubscriberView {
//    [_subscriber.view setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
//    [self addSubview:_subscriber.view];
//}
//
//- (void)cleanupSubscriber {
//    [_subscriber.view removeFromSuperview];
//    [self unsubscribe];
//    _subscriber.delegate = nil;
//    _subscriber = nil;
//}

- (void)cleanupSubscriber:(OTSubscriber *)subscriber {
    if ([_subscribers containsObject:subscriber]) {
        [_subscribers removeObject:subscriber];
        
        OTError *error = nil;
        [_session unsubscribe:subscriber error:&error];
        
        if (error) {
            NSLog(@"unsubscribe %@. Error: %@", subscriber, error);
        }

    }
}

- (void)cleanupSubscribers {
    for (int i = 0; i < _subscribers.count; i++) {
        [self cleanupSubscriber:_subscribers.anyObject];
    }
}

- (void)onStreamCreated:(NSNotification *)notification {
    OTStream *stream = notification.userInfo[@"stream"];
//    if (_subscriber == nil) {
//        [self doSubscribe:stream];
//    }
    [self doSubscribe:stream];
}

- (void)observeStream {
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(onStreamCreated:)
     name:[@"stream-created:" stringByAppendingString:_sessionId]
     object:nil];
}

- (void)stopObserveStream {
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:[@"stream-created:" stringByAppendingString:_sessionId]
     object:nil];
}

#pragma mark - OTSubscriber delegate callbacks

- (void)subscriber:(OTSubscriberKit*)subscriber didFailWithError:(OTError*)error {
//    [[NSNotificationCenter defaultCenter]
//     postNotificationName:@"onSubscribeError"
//     object:nil
//     userInfo:@{@"sessionId": _sessionId, @"error": [error description]}];
//    [self cleanupSubscriber];
    [self cleanupSubscriber:(OTSubscriber *)subscriber];
}

- (void)subscriberDidConnectToStream:(OTSubscriberKit*)subscriber {
//    [[NSNotificationCenter defaultCenter]
//     postNotificationName:@"onSubscribeStart"
//     object:nil
//     userInfo:@{@"sessionId": _sessionId}];
}

- (void)subscriberDidDisconnectFromStream:(OTSubscriberKit*)subscriber {
//    [[NSNotificationCenter defaultCenter]
//     postNotificationName:@"onSubscribeStop"
//     object:nil
//     userInfo:@{@"sessionId": _sessionId}];
//    [self cleanupSubscriber];
    
    [self cleanupSubscriber:(OTSubscriber *)subscriber];
}

- (void)subscriberDidReconnectToStream:(OTSubscriberKit*)subscriber {
    [self subscriberDidConnectToStream:subscriber];
}

@end
