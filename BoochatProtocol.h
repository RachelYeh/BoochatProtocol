//
//  BoochatProtocol.h
//  TopicResearchContest
//
//  Created by cialab1 on 2016/3/6.
//  Copyright (c) 2016年 Yeh Rachel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol BoochatProtocolDelegate <NSObject>

@required

//1.搜尋機制
-(void) getDiscoveredPeripheral:(NSString *)newPeripheralName;

//2.加友機制
-(void) someoneRespondedToYourAddFriendRequest:(NSString *)addeeName withChatID:(NSString *)addeeChatID;
-(void) someoneWantsToAddYouAsFriend:(NSString *)adderName withChatID:(NSString *)adderChatID;

//3.在場檢驗機制
-(void) certainNodeIsPresent:(NSString *)aroundName;

//4.公共聊天機制
-(void)receivedIncomingPublicMessage: (NSString *)message byWhom:(NSString *)name;
-(void)sentOutgoingPublicMessage: (NSString *)message;

//5.私人傳訊機制
-(void) messageFromChatID:(NSString *)whichChatIDforTransfer withContent:(NSString *) receivedIncomeMessage;
-(void) sucessfullySentMessageToChatID: (NSString *)chatId withContent:(NSString *)messageContent;

//6.交換資訊機制
-(void) receivedExchangeList:(NSArray *)exchangeArray fromMediator:(NSString *)name;

@end


@interface BoochatProtocol : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate>
{
    // Delegate to respond back
    id <BoochatProtocolDelegate> _delegate;
    //NSArray *_codeArray;
    
}
@property (nonatomic,assign)id delegate;

//central elements
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;
@property (strong, nonatomic) NSMutableData *data;

@property (strong, nonatomic) NSMutableArray *peripheralList;
@property (strong, nonatomic) NSMutableArray *codeArray;

//periphrel elements
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic *chatIDCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *publicCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *transferCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *containCharacteristic;
@property (strong, nonatomic) NSData *dataToSend;
@property (nonatomic, readwrite) NSInteger sendDataIndex;

//公共聊天機制
@property (strong, nonatomic) NSString *pname;
@property (strong, nonatomic) NSString *announcementContent;

//加友機制
@property (strong, nonatomic) NSString *originSDaddress;
@property (strong, nonatomic) NSString *copyedSDaddress;
@property (strong, nonatomic) NSString *addeeName;
@property (strong, nonatomic) NSString *addeeChatID;
@property (strong, nonatomic) NSString *adderName;
@property (strong, nonatomic) NSString *adderChatID;

@property (nonatomic, readwrite) NSInteger connectControlTag;

//在場檢驗機制
@property (strong, nonatomic) NSString *aroundName;

//私人聊天機制
@property (strong, nonatomic) NSString *messageContent;
@property (strong, nonatomic) NSMutableData *pri_data;
@property (strong, nonatomic) NSData *pri_dataToSend;
@property (nonatomic, readwrite) NSInteger pri_sendDataIndex;
@property (strong, nonatomic) NSString *whichChatIDforTransfer;
@property (strong, nonatomic) NSString *receivedIncomeMessage;
@property (strong, nonatomic) NSString *privateChatID;

@property (nonatomic, readwrite) NSInteger whichSessionTag;

//交換機制
@property (strong, nonatomic) NSString *EXoriginSDaddress;
@property (strong, nonatomic) NSString *EXcopySDaddress;
@property (strong, nonatomic) NSArray *receivedExchangeList;
@property (strong, nonatomic) NSMutableData *exchangeData;
@property (strong, nonatomic) NSData *ex_dataToSend;
@property (nonatomic, readwrite) NSInteger ex_sendDataIndex;
@property (strong, nonatomic) NSString *mediator;

#define NOTIFY_MTU 20

//各機制的方法api
-(void) detectSurrounding;
-(void) publicAnnounce:(NSString *)announcement;
-(void) addFriendRequest:(NSString *)peripheralName;
-(void) checkBeside:(NSString *)peripheralName;
-(void) transferMessage:(NSString *)message ToChatID:(NSString *)chatID;
-(void) exchangeInfo:(NSString *)peripheralName;

@end