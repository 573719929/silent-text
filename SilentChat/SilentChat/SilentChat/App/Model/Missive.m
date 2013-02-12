/*
Copyright © 2012-2013, Silent Circle, LLC.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Any redistribution, use, or modification is done solely for personal 
      benefit and not for any commercial purpose or for monetary gain
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name Silent Circle nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL SILENT CIRCLE, LLC BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
//
//  Missive.m
//  SilentText
//

#if !__has_feature(objc_arc)
#  error Please compile this class with ARC (-fobjc-arc).
#endif

#import "Missive.h"
#import "Conversation.h"
#import "App.h"
#import "XMPP.h"
#import "Siren.h"
#import "SCloudObject.h"

#import "XMPPMessage+SilentCircle.h"


#define CLASS_DEBUG 1
#import "DDGMacros.h"

NSString *const kMissiveEntity = @"Missive";
NSString *const kShredDate = @"shredDate";
NSString *const kScppID = @"scppID";
 

@interface Missive ()

@property (strong, nonatomic, readwrite) Siren *siren;

@end

@implementation Missive

// Attributes
@dynamic data;
@dynamic date;
@dynamic flags;
@dynamic scppID;
@dynamic shredDate;
@dynamic toJID;

// Relations
@dynamic conversation;

@synthesize siren = _siren;
 
@dynamic isShredable;

- (Siren *) siren {
    
    if (_siren) { return _siren; }

 //   DDGDesc(self.data);
    
    NSData *jsonData = [self.conversation decryptData: self.data];
    
    Siren *siren = [Siren sirenWithJSONData: jsonData];
    
    _siren = siren;
    
    return siren;
    
} // -siren


- (BOOL) isShredable {
    
    if (self.shredDate) { return YES; }
    
    if (self.siren.shredAfter) { return YES; }
    
    return NO;
    
} // -isShredable


#pragma mark - Public methods.


- (void) viewedOnDate: (NSDate *) date {
    
    if (self.isShredable && !self.shredDate) {
        
        self.shredDate = [date dateByAddingTimeInterval: self.siren.shredAfter];
    }
    
} // -viewedOnDate:

 

+ (Missive *) insertMissiveForXMPPMessage: (XMPPMessage *) xmppMessage 
                   inManagedObjectContext: (NSManagedObjectContext *) moc 
                            withEncryptor: (Cryptor) encryptor { 

    NSDate *timestamp = [xmppMessage timestamp];
    if(!timestamp)  timestamp = [xmppMessage addTimestamp];
    
    timestamp = NSDate.date; // [timestamp dateByAddingTimeInterval:App.sharedApp.serverTimeOffset ];
    
    Siren *siren = [Siren sirenWithChatMessage: xmppMessage];
    
    Missive *missive = [NSEntityDescription insertNewObjectForEntityForName: kMissiveEntity 
                                                     inManagedObjectContext: moc];
    missive.date   = timestamp;
    missive.scppID = siren.chatMessageID;
    missive.data   = encryptor(siren.jsonData);
    missive.toJID  = siren.to.full;
    missive.siren  = siren;
    
    return missive;

} // +insertMissiveForXMPPMessage:inManagedObjectContext:withEncryptor:


#pragma mark - NSManagedObject methods.


- (void) willTurnIntoFault {
    
    _siren = nil;
    
} // -willTurnIntoFault

@end
