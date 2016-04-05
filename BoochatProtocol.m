//
//  BoochatProtocol.m
//  TopicResearchContest
//
//  Created by cialab1 on 2016/3/6.
//  Copyright (c) 2016年 Yeh Rachel. All rights reserved.
//

#define DETECT_SERVICE_UUID           @"2CD088F1-9809-4077-A0B7-07CB9D992318"
#define ECHO_SERVICE_UUID             @"68D3E367-87DB-4FE5-BADD-5D6070ED619C"

#define PUBLIC_SERVICE_UUID           @"ACF3DEE0-75F9-4381-8EF3-1859C8A8BCCA"
#define PUBLIC_CHARACTERISTIC_UUID    @"49F83D40-5722-4DBF-9215-71D30D539589"

#define ADDFRIEND_SERVICE_UUID        @"F5096C15-A391-47EC-8C14-3D4F88C0FE4A"
#define CHATID_SERVICE_UUID           @"A1B78907-E60B-46E5-8ED6-76C42A5AE6BF"
#define CHATID_CHARACTERISTIC_UUID    @"4439C0E4-CA45-4DB7-850B-2463F50BA500"

#define PRESENT_SERVICE_UUID          @"0F7F7987-0685-4D37-A397-BC79F9AC6133"
#define ANSWER_SERVICE_UUID           @"A57C6DC6-CAFF-40F7-9249-B5C4323343D7"

#define TRANSFER_SERVICE_UUID         @"E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
#define TRANSFER_CHARACTERISTIC_UUID  @"08590F7E-DB05-467E-8757-72F6FAEB13D4"

#define EXCHANGE_SERVICE_UUID         @"2E279D9B-EFCD-454F-AAE8-B34D3EF1975E"
#define CONTAIN_SERVICE_UUID          @"E30321D6-987F-49F8-A976-A9B180DE9DD2"
#define CONTAIN_CHARACTERISTIC_UUID   @"431C1EB5-BB88-44C8-8CD5-6D8C61A1F964"


#import "BoochatProtocol.h"
#import "PlistAccessManager.h"
#import "PeripheralList.h"

@interface BoochatProtocol () <UIAlertViewDelegate>
{
    PlistAccessManager *_plistManager;
    //NSString *_pname;
    //NSString *_announcementContent;
}
@end

@implementation BoochatProtocol
-(id)init
{
    if (self) {
        
        //中央Manager
        //dispatch_queue_t centralQueue = dispatch_queue_create("mycentralqueue", DISPATCH_QUEUE_SERIAL);
        //_centralManager=[[CBCentralManager alloc]initWithDelegate:self queue:centralQueue];
        _centralManager=[[CBCentralManager alloc]initWithDelegate:self queue:nil];
        _centralManager.delegate=self;
        
        //周圍Manager
        _peripheralManager=[[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
        _peripheralManager.delegate=self;
        
        //產生一PlistManager處理名字存取
        _plistManager=[[PlistAccessManager alloc]init];
        
        //搜尋機制
        self.peripheralList=[[NSMutableArray alloc]init];
        
        //公共聊天機制
        self.pname=[[NSString alloc]init];
        self.announcementContent=[[NSString alloc]init];
        self.data=[[NSMutableData alloc]init];
        
        //加友機制
        self.originSDaddress=[[NSString alloc]init];
        self.copyedSDaddress=[[NSString alloc]init];
        self.addeeName=[[NSString alloc]init];
        self.addeeChatID=[[NSString alloc]init];
        self.adderName=[[NSString alloc]init];
        self.adderChatID=[[NSString alloc]init];
        
        //在場檢驗機制
        self.aroundName=[[NSString alloc]init];
        
        //私人聊天機制
        self.messageContent=[[NSString alloc]init];
        self.whichChatIDforTransfer=[[NSString alloc]init];
        //self.receivedIncomeMessage=[[NSString alloc]init];
        self.privateChatID=[[NSString alloc]init];
        self.pri_data=[[NSMutableData alloc]init];
        
        //交換機制
        self.EXoriginSDaddress=[[NSString alloc]init];
        self.EXcopySDaddress=[[NSString alloc]init];
        self.receivedExchangeList=[[NSArray alloc]init];
        self.exchangeData=[[NSMutableData alloc]init];
        self.ex_dataToSend=[[NSData alloc]init];
        self.mediator=[[NSString alloc]init];
        
    }
    return self;
}

#pragma mark - Central 中央方法

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"無法正常使用CBCentralManager");
        return;
    }
    
    //在此的狀態已為CBCentralManagerStatePoweredOn，接著開始掃描周圍
    [self scan];
}

- (void)scan
{
    [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:DETECT_SERVICE_UUID],[CBUUID UUIDWithString:ECHO_SERVICE_UUID], [CBUUID UUIDWithString:PUBLIC_SERVICE_UUID],[CBUUID UUIDWithString:ADDFRIEND_SERVICE_UUID],[CBUUID UUIDWithString:CHATID_SERVICE_UUID], [CBUUID UUIDWithString:PRESENT_SERVICE_UUID], [CBUUID UUIDWithString:ANSWER_SERVICE_UUID],[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID],[CBUUID UUIDWithString:EXCHANGE_SERVICE_UUID], [CBUUID UUIDWithString:CONTAIN_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    NSLog(@"開始進行scanning");
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSArray *adUUIDs=[[NSArray alloc]init];
    adUUIDs=[advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"];
    CBUUID *currentUUID = [adUUIDs objectAtIndex:0];
    
    NSString *adDeviceName=[[NSString alloc] init];
    adDeviceName=[advertisementData objectForKey:@"kCBAdvDataLocalName"];
    NSLog(@"adDeviceName:%@",adDeviceName);
    
    NSLog(@"發現周圍設備 %@ at %@", peripheral.name, RSSI);
    
    
    if([currentUUID isEqual:[CBUUID UUIDWithString:DETECT_SERVICE_UUID]])
    {
        //if (![adDeviceName containsString:@"|"]){

            BOOL checkExistTag=NO;
            for(NSMutableDictionary *dict in self.peripheralList)
            {
                if([dict[@"peripheral"] isEqual:peripheral]){
                    checkExistTag=YES;
                }
            }
            if(checkExistTag==NO) //_peripheralList陣列中不存在此周圍裝置
            {
                NSDictionary *tempDict=[NSDictionary dictionaryWithObjectsAndKeys: adDeviceName, @"name", peripheral, @"peripheral", nil]; //存下周圍裝置的資訊（名稱和周圍設備）
                [self.peripheralList addObject:tempDict];
                [self.delegate getDiscoveredPeripheral:adDeviceName];
            }
        
            //load self name
            NSArray *setName=[NSArray array];
            setName=[_plistManager getRootArrayOfPlist:@"selfname.plist" underFolder:@"BooChat"];
        
            NSLog(@"開始廣播ECHO_UUID");
            [self.peripheralManager startAdvertising:@{ CBAdvertisementDataLocalNameKey:[setName objectAtIndex:0],CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:ECHO_SERVICE_UUID]]}];
            NSLog(@"%@",setName);
        
            //在固定時間後停止廣播
            [NSTimer scheduledTimerWithTimeInterval:3.0
                                         target:self
                                       selector:@selector(stopAdvertise)
                                       userInfo:nil
                                        repeats:NO];
       // }
    }
    else if([currentUUID isEqual:[CBUUID UUIDWithString:ECHO_SERVICE_UUID]])
    {
        //if (![adDeviceName containsString:@"|"]){

            BOOL checkExistTag=NO;
            for(NSMutableDictionary *dict in self.peripheralList)
            {
                if([dict[@"peripheral"] isEqual:peripheral]){
                    checkExistTag=YES;
                }
            }
            if(checkExistTag==NO) //_peripheralList陣列中不存在此周圍裝置
            {
                NSMutableDictionary *tempDict=[NSMutableDictionary dictionaryWithObjectsAndKeys: adDeviceName, @"name", peripheral, @"peripheral", nil]; //存下周圍裝置的資訊（名稱和周圍設備）
                [self.peripheralList addObject:tempDict];
                [self.delegate getDiscoveredPeripheral:adDeviceName];
            }
        //}
    }
    else if([currentUUID isEqual:[CBUUID UUIDWithString:PUBLIC_SERVICE_UUID]])
    {
        // Ok, it's in range - have we already seen it?
        if (self.discoveredPeripheral != peripheral) {
            
            // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
            self.discoveredPeripheral = peripheral;
            
            _connectControlTag=3;
            
            // And connect
            NSLog(@"正在連線至周圍設備 %@", peripheral);
            
            [_centralManager connectPeripheral:peripheral  options:nil];
            
            //_pname=[[NSString alloc]init];
            self.pname=adDeviceName;
        }
    }
    else if([currentUUID isEqual:[CBUUID UUIDWithString:ADDFRIEND_SERVICE_UUID]])
    {
        NSLog(@"收到%@",adDeviceName);
        
        //開始剖析SDaddress字串，找出傳訊者和收訊者
        NSArray *parseSDaddress=[[NSArray alloc]init];
        NSString *sourceName=[[NSString alloc]init];
        NSString *destinationName=[[NSString alloc]init];
        parseSDaddress=[adDeviceName componentsSeparatedByString:@"|"];
        sourceName=[parseSDaddress objectAtIndex:0];
        destinationName=[parseSDaddress objectAtIndex:1];
        self.adderName=sourceName;
        
        //load user name
        NSArray *setName=[NSArray array];
        setName=[_plistManager getRootArrayOfPlist:@"selfname.plist" underFolder:@"BooChat"];

        if ([[setName objectAtIndex:0] isEqualToString:destinationName]){
            
            //暫時停止掃描，等彈出視窗被點選後再恢復
            [_centralManager stopScan];
            
            //重新組合SDaddress
            self.copyedSDaddress=destinationName;
            self.copyedSDaddress=[_copyedSDaddress stringByAppendingString:@"|"];
            self.copyedSDaddress=[_copyedSDaddress stringByAppendingString:sourceName];
            
            //確認對方想加自己，跳出視窗詢問使用者是否接受邀請
            NSLog(@"收到他人的交友邀請");
            
            NSString *describe=[[NSString alloc]initWithFormat:@"你是否願意加%@為朋友呢？",sourceName];
            UIAlertView *alertView=[[UIAlertView alloc]initWithTitle:@"交友邀請" message:describe delegate:self cancelButtonTitle:@"不願意" otherButtonTitles:@"願意", nil];
            [alertView show];
            
            NSLog(@"停止掃描");
        }
    }
    else if([currentUUID isEqual:[CBUUID UUIDWithString:CHATID_SERVICE_UUID]])
    {
        //開始剖析SDaddress字串，找出傳訊者和收訊者
        NSArray *parseSDaddress=[[NSArray alloc]init];
        parseSDaddress=[adDeviceName componentsSeparatedByString:@"|"];
        self.addeeName=[parseSDaddress objectAtIndex:0];
        NSLog(@"addeeName:%@",self.addeeName);
        
        //load user name
        NSArray *setName=[NSArray array];
        setName=[_plistManager getRootArrayOfPlist:@"selfname.plist" underFolder:@"BooChat"];
        
        if ([[setName objectAtIndex:0] isEqualToString:[parseSDaddress objectAtIndex:1]]){ //確認接收對象是自己
            //對方針對自己的加友邀請做出了回覆，得去領取特徵值（CHATID）
            _connectControlTag=1;
            self.discoveredPeripheral=peripheral;
            [_centralManager connectPeripheral:peripheral  options:nil];
        }
    }
    else if([currentUUID isEqual:[CBUUID UUIDWithString:PRESENT_SERVICE_UUID]])
    {
        BOOL knownObjectTag=NO;
        
        //get selfname
        NSArray *setName=[NSArray array];
        setName=[_plistManager getRootArrayOfPlist:@"selfname.plist" underFolder:@"BooChat"];
        
        if([[setName objectAtIndex:0] isEqualToString:adDeviceName]) //若要傳輸的對象名字為自己
        {
            knownObjectTag=YES;
        }
        
        for(NSDictionary *dict in self.peripheralList) //或是自己周圍名單中有此對象
        {
            if([dict[@"name"] isEqualToString:adDeviceName]){
                knownObjectTag=YES;
            }
        }
        //確實周遭有此對象
        if(knownObjectTag==YES)
        {
            NSLog(@"開始廣播ANSWER_UUID");
            [self.peripheralManager startAdvertising:@{ CBAdvertisementDataLocalNameKey:adDeviceName,CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:ANSWER_SERVICE_UUID]]}];
            
            [NSTimer scheduledTimerWithTimeInterval:7.0
                                             target:self
                                           selector:@selector(stopAdvertise)
                                           userInfo:nil
                                            repeats:NO];
        }
    }
    else if([currentUUID isEqual:[CBUUID UUIDWithString:ANSWER_SERVICE_UUID]])
    {
        self.aroundName=adDeviceName;
        [self.delegate certainNodeIsPresent:_aroundName];
    }
    else if([currentUUID isEqual:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]])
    {
        self.whichChatIDforTransfer=adDeviceName;
        
        //load friend plist
        NSArray *chatIdList=[NSArray array];
        chatIdList=[_plistManager getRootArrayOfPlist:@"friend.plist" underFolder:@"BooChat"];
        
        BOOL checkIdTag=NO;
        //開始查看自己是否有這組chatID
        for(NSMutableDictionary *dict in chatIdList)
        {
            if([dict[@"object"] isEqual:self.whichChatIDforTransfer]){
                checkIdTag=YES;
            }
        }
        
        if (checkIdTag) { //確定是傳給自己（有相同ID）
            _connectControlTag=2;
            self.discoveredPeripheral=peripheral;  
            [_centralManager connectPeripheral:peripheral  options:nil];
        }
    }
    
    else if([currentUUID isEqual:[CBUUID UUIDWithString:EXCHANGE_SERVICE_UUID]])
    {
        //開始剖析SDaddress字串，找出傳訊者和收訊者
        NSArray *parseSDaddress=[[[NSArray alloc]init]autorelease];
        NSString *sourceName=[[[NSString alloc]init]autorelease];
        NSString *destinationName=[[[NSString alloc]init]autorelease];
        parseSDaddress=[adDeviceName componentsSeparatedByString:@"|"];
        sourceName=[parseSDaddress objectAtIndex:0];
        destinationName=[parseSDaddress objectAtIndex:1];
        
        //load self name
        NSArray *setName=[NSArray array];
        setName=[_plistManager getRootArrayOfPlist:@"selfname.plist" underFolder:@"BooChat"];
        
        if ([[setName objectAtIndex:0] isEqualToString:destinationName]){
            
            //重新組合SDaddress
            _EXcopySDaddress=destinationName;
            _EXcopySDaddress=[_EXcopySDaddress stringByAppendingString:@"|"];
            _EXcopySDaddress=[_EXcopySDaddress stringByAppendingString:sourceName];
            
            //確認對方想獲取自己的資訊
            NSLog(@"收到他人的交換資訊請求");
            
            NSLog(@"開始廣播CONTAIN_UUID");
            [self.peripheralManager startAdvertising:@{ CBAdvertisementDataLocalNameKey:_EXcopySDaddress,CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:CONTAIN_SERVICE_UUID]]}];
            
            [NSTimer scheduledTimerWithTimeInterval:7.0
                                             target:self
                                           selector:@selector(stopAdvertise)
                                           userInfo:nil
                                            repeats:NO];
        }
    }
    else if([currentUUID isEqual:[CBUUID UUIDWithString:CONTAIN_SERVICE_UUID]])
    {
        //開始剖析SDaddress字串，找出傳訊者和收訊者
        NSArray *parseSDaddress=[[[NSArray alloc]init]autorelease];
        parseSDaddress=[adDeviceName componentsSeparatedByString:@"|"];
        self.mediator=[parseSDaddress objectAtIndex:0];
        
        //load self name
        NSArray *setName=[NSArray array];
        setName=[_plistManager getRootArrayOfPlist:@"selfname.plist" underFolder:@"BooChat"];
        
        if ([[setName objectAtIndex:0] isEqualToString:[parseSDaddress objectAtIndex:1]]){ //確認接收對象是自己
            //對方針對自己的交換資訊請求做出了回覆，得去領取特徵值（周圍裝置陣列）
            _connectControlTag=4;
            self.discoveredPeripheral=peripheral;
            [_centralManager connectPeripheral:peripheral  options:nil];
        }
    }

}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"連線至周圍設備 %@ 失敗(%@)", peripheral, [error localizedDescription]);
    [self cleanup];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"已成功連線至周圍設備");
    peripheral.delegate=self;
    
    // Stop scanning
    [_centralManager stopScan];
    NSLog(@"停止掃描");
    
    if(_connectControlTag==1)
    {
        [peripheral discoverServices:@[[CBUUID UUIDWithString:CHATID_SERVICE_UUID]]];
    }
    else if(_connectControlTag==2)
    {
        [self.pri_data setLength:0];
        [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
    }
    else if(_connectControlTag==3)
    {
        [self.data setLength:0];
        [peripheral discoverServices:@[[CBUUID UUIDWithString:PUBLIC_SERVICE_UUID]]];
    }
    else if(_connectControlTag==4)
    {
        [peripheral discoverServices:@[[CBUUID UUIDWithString:CONTAIN_SERVICE_UUID]]];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    else if (_connectControlTag==1) { //聊天序號流程
        for (CBService *service in peripheral.services) {
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CHATID_CHARACTERISTIC_UUID]] forService:service];
        }
    }
    else if (_connectControlTag==2) { //聊天流程
        for (CBService *service in peripheral.services) {
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
        }
    }
    else if (_connectControlTag==3) { //公共聊天流程
        for (CBService *service in peripheral.services) {
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:PUBLIC_CHARACTERISTIC_UUID]] forService:service];
        }
    }
    else if (_connectControlTag==4) { //交換周圍資訊流程
        for (CBService *service in peripheral.services) {
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CONTAIN_CHARACTERISTIC_UUID]] forService:service];
        }
    }

}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    else if (_connectControlTag==1) { //聊天序號流程
        for (CBCharacteristic *characteristic in service.characteristics) {
            
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHATID_CHARACTERISTIC_UUID]]) {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                NSLog(@"setNotify給周圍的CHATID服務了");
            }
        }
    }
    else if (_connectControlTag==2) { //聊天流程
        for (CBCharacteristic *characteristic in service.characteristics) {
            
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                NSLog(@"setNotify給周圍的TRANSFER服務了");
            }
        }
    }
    else if (_connectControlTag==3) { //公共聊天流程
        for (CBCharacteristic *characteristic in service.characteristics) {
            
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:PUBLIC_CHARACTERISTIC_UUID]]) {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                NSLog(@"setNotify給周圍的PUBLIC服務了");
            }
        }
    }
    else if (_connectControlTag==4) { //交換周圍資訊流程
        for (CBCharacteristic *characteristic in service.characteristics) {
            
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CONTAIN_CHARACTERISTIC_UUID]]) {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                NSLog(@"setNotify給周圍的CONTAIN服務了");
                
                /*
                NSString *error;
                self.codeArray=[[NSArray alloc]init];
                self.codeArray=[self.peripheralList copy];
                NSData *arrayData = [NSPropertyListSerialization dataFromPropertyList:_codeArray
                                                                               format:NSPropertyListXMLFormat_v1_0
                                                                     errorDescription:&error];
                
                if(arrayData){
                    NSLog(@"arrayData:%@",arrayData);}
                NSLog(@"error: %@",error);*/
            }
        }
    }

}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    NSLog(@"characterist是？？？？%@",characteristic);
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    //分流看是哪個機制
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHATID_CHARACTERISTIC_UUID]])
    {
        _addeeChatID=stringFromData;
        NSLog(@"獲得的CHATID：%@",_addeeChatID);
        NSLog(@"addeeName：%@",self.addeeName);

        [self.delegate someoneRespondedToYourAddFriendRequest:self.addeeName withChatID:self.addeeChatID];
        [_centralManager cancelPeripheralConnection:peripheral];

    }
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:PUBLIC_CHARACTERISTIC_UUID]])
    {
        // Have we got everything we need?
        if ([stringFromData isEqualToString:@"EOM"]) {
            NSLog(@"已收到EOM");
        
            // We have, so show the data,
            //[self.textview setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
            NSString *string=[[NSString alloc]initWithData:self.data encoding:NSUTF8StringEncoding];
            NSLog(@"所收到的總訊息內容為：%@",string);
        
            //已收到完整訊息，將回傳給ViewController
            [self.delegate receivedIncomingPublicMessage:string byWhom:self.pname];
        
            // Cancel our subscription to the characteristic
            [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
            // and disconnect from the peripehral
            [_centralManager cancelPeripheralConnection:peripheral];
        
            //[self scan];
        }
    
        // Otherwise, just add the data on to what we already have
        [_data appendData:characteristic.value];
    
        // Log it
        NSLog(@"Received: %@", stringFromData);
    }
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
    {
        NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        
        //若訊息已碰上EOM表示文末
        if ([stringFromData isEqualToString:@"EOM"]) {
            NSLog(@"已收到EOM");
            
            self.receivedIncomeMessage=[[NSString alloc]initWithData:self.pri_data encoding:NSUTF8StringEncoding];
            NSLog(@"所收到的總訊息內容為：%@",self.receivedIncomeMessage);
            
            [self.delegate messageFromChatID:self.whichChatIDforTransfer withContent:self.receivedIncomeMessage];
            [_centralManager cancelPeripheralConnection:peripheral];
            
        }
        //訊息尚未傳完，繼續添加後續訊息
        [self.pri_data appendData:characteristic.value];
        NSLog(@"Received: %@", stringFromData);
    }
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CONTAIN_CHARACTERISTIC_UUID]])
    {
        //先透過字串檢測是否為EOM
        NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        //若訊息已碰上EOM表示文末
        if ([stringFromData isEqualToString:@"EOM"])
        {
            NSString *errorDesc = nil;
            NSPropertyListFormat format;
            //NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:path];
            self.receivedExchangeList = (NSArray *)[NSPropertyListSerialization
                                        propertyListFromData:self.exchangeData
                                        mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                        format:&format
                                        errorDescription:&errorDesc];
            if (!self.receivedExchangeList) {
                NSLog(@"Error reading plist: %@, format: %lu", errorDesc, (unsigned long)format);
            }

            //self.receivedExchangeList=[NSKeyedUnarchiver unarchiveObjectWithData:self.exchangeData];
            NSLog(@"所收到的總訊息內容為：%@",self.receivedExchangeList);
            
            [_centralManager cancelPeripheralConnection:peripheral];
            
            //告知ViewController已收到交換資訊
            [self.delegate receivedExchangeList:self.receivedExchangeList fromMediator:self.mediator];
        }
        
        //訊息尚未傳完，繼續添加後續訊息
        [self.exchangeData appendData:characteristic.value];
        NSLog(@"Received: %@", stringFromData);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:PUBLIC_CHARACTERISTIC_UUID]] || ![characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] || ![characteristic.UUID isEqual:[CBUUID UUIDWithString:CONTAIN_CHARACTERISTIC_UUID]]) {
        return;
    }
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
    // Notification has stopped
    else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [_centralManager cancelPeripheralConnection:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"已和周圍設備斷線");
    _discoveredPeripheral = nil;
    // We're disconnected, so start scanning again
    [self scan];
}

- (void)cleanup
{
    // Don't do anything if we're not connected
    if (self.discoveredPeripheral.state != CBPeripheralStateConnected)
    {
        return;
    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (_discoveredPeripheral.services != nil) {
        for (CBService *service in _discoveredPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:PUBLIC_CHARACTERISTIC_UUID]]) {
                        if (characteristic.isNotifying) {
                            // It is notifying, so unsubscribe
                            [_discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            
                            // And we're done.
                            return;
                        }
                    }
                }
            }
        }
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [_centralManager cancelPeripheralConnection:_discoveredPeripheral];
}

-(void) peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices
{
    NSLog(@"didModifyServices() called. by peripheral:%@  with services:%@",peripheral,invalidatedServices);
    [self scan];
}

#pragma mark - Peripheral 周圍方法

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    // Opt out from any other state
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    // We're in CBPeripheralManagerStatePoweredOn state...
    NSLog(@"self.peripheralManager powered on.");
    
    //註冊Characteristic
    self.chatIDCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:CHATID_CHARACTERISTIC_UUID] properties:CBCharacteristicPropertyNotify
                                    value:nil
                                    permissions:CBAttributePermissionsReadable];
    self.publicCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:PUBLIC_CHARACTERISTIC_UUID] properties:CBCharacteristicPropertyNotify
                                    value:nil
                                    permissions:CBAttributePermissionsReadable];
    self.transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID] properties:CBCharacteristicPropertyNotify
                                      value:nil
                                      permissions:CBAttributePermissionsReadable];
    self.containCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:CONTAIN_CHARACTERISTIC_UUID] properties:CBCharacteristicPropertyNotify
                                     value:nil
                                     permissions:CBAttributePermissionsReadable];
    
    //註冊Service
    CBMutableService *publicService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:PUBLIC_SERVICE_UUID] primary:YES];
    CBMutableService *detectService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:DETECT_SERVICE_UUID] primary:YES];
    CBMutableService *echoService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:ECHO_SERVICE_UUID] primary:YES];
    CBMutableService *friendService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:ADDFRIEND_SERVICE_UUID] primary:YES];
    CBMutableService *chatIDService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:CHATID_SERVICE_UUID] primary:YES];
    CBMutableService *presentService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:PRESENT_SERVICE_UUID] primary:YES];
    CBMutableService *answerService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:ANSWER_SERVICE_UUID]primary:YES];
    CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID] primary:YES];
    CBMutableService *containService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:CONTAIN_SERVICE_UUID] primary:YES];

    
    //將characteristic加到service裡
    chatIDService.characteristics = @[self.chatIDCharacteristic];
    publicService.characteristics = @[self.publicCharacteristic];
    transferService.characteristics = @[self.transferCharacteristic];
    containService.characteristics = @[self.containCharacteristic];
    //將serveice加給peripheral manager
    [self.peripheralManager addService:publicService];
    [self.peripheralManager addService:detectService];
    [self.peripheralManager addService:echoService];
    [self.peripheralManager addService:friendService];
    [self.peripheralManager addService:chatIDService];
    [self.peripheralManager addService:presentService];
    [self.peripheralManager addService:answerService];
    [self.peripheralManager addService:transferService];
    [self.peripheralManager addService:containService];
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic");
    
    //先停止廣播
    [self.peripheralManager stopAdvertising];
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHATID_CHARACTERISTIC_UUID]]){
        
        NSLog(@"將產生一CHATID給對方");
        
        //利用當下的時間（細緻到秒）產生一專屬ID以利日後判別聊天
        NSDateFormatter *dateFormatter=[[[NSDateFormatter alloc]init]autorelease];
        [dateFormatter setDateFormat:@"yyMMddHHmmss"];
        NSString *strCHATID=[dateFormatter stringFromDate:[NSDate date]];
        NSLog(@"%@", strCHATID);
        
        [self.peripheralManager updateValue:[strCHATID dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.chatIDCharacteristic onSubscribedCentrals:nil];
        
        _adderChatID=strCHATID;

        [self.delegate someoneWantsToAddYouAsFriend:self.adderName withChatID:self.adderChatID];
    }
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:PUBLIC_CHARACTERISTIC_UUID]]){
        
        //設定control tag
        _whichSessionTag=0;
    
        // Get the data
        self.dataToSend = [_announcementContent dataUsingEncoding:NSUTF8StringEncoding];
    
        // Reset the index
        self.sendDataIndex = 0;
    
        // Start sending
        [self sendData];
    }
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]){
        
        //設定control tag
        _whichSessionTag=1;
        
        //獲取要傳出去的訊息內容
        self.pri_dataToSend=[self.messageContent dataUsingEncoding:NSUTF8StringEncoding];
        //重設訊息索引
        self.pri_sendDataIndex=0;
        //開始傳送
        [self sendPrivateData];
    }
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CONTAIN_CHARACTERISTIC_UUID]]){
        
        NSLog(@"did subscribe");
        
        //設定control tag
        _whichSessionTag=2;
        
        //獲取要傳出去的訊息內容
        //剛好要傳輸的內容是一陣列（和之前單純的字串不同），故得使用NSKeyedArchiver
        
        //首先把_peripheralList中的名字字串取出(去除周圍裝置)
        self.codeArray=[[NSMutableArray alloc] init];
        for (NSDictionary *dict in self.peripheralList) {
            [self.codeArray addObject:dict[@"name"]];
        }
        NSLog(@"codeArray:%@", self.codeArray);

        //PeripheralList *peri=[[PeripheralList alloc]init];
        //peri.array=self.peripheralList;        //peri.array=@"i don't know";
        //NSData *encodedData=[[NSData alloc]init];
        //encodedData=[NSKeyedArchiver archivedDataWithRootObject:peri];
        
        NSString *error;
        NSData *arrayData = [NSPropertyListSerialization dataFromPropertyList:self.codeArray
                                                                       format:NSPropertyListXMLFormat_v1_0
                                                             errorDescription:&error];
        NSLog(@"arrayData:%@",arrayData);
        NSLog(@"error: %@",error);
        if(arrayData) {
        self.ex_dataToSend=arrayData;
        //重設訊息索引
        self.ex_sendDataIndex=0;
        //開始傳送
        [self sendExchangeData];
        }
        
    }
}

- (void)sendExchangeData
{
    // First up, check if we're meant to be sending an EOM
    static BOOL sendingEOM = NO;
    
    if (sendingEOM) {
        
        // send it
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.containCharacteristic onSubscribedCentrals:nil];
        
        // Did it send?
        if (didSend) {
            
            // It did, so mark it as sent
            sendingEOM = NO;
            NSLog(@"Sent: EOM");
        }
        
        // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're not sending an EOM, so we're sending data
    
    // Is there any left to send?
    
    if (self.ex_sendDataIndex >= self.ex_dataToSend.length) {
        
        // No data left.  Do nothing
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    
    BOOL didSend = YES;
    
    while (didSend) {
        
        // Make the next chunk
        
        // Work out how big it should be
        NSInteger amountToSend = self.ex_dataToSend.length - self.ex_sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.ex_dataToSend.bytes+self.ex_sendDataIndex length:amountToSend];
        
        // Send it
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.containCharacteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            return;
        }
        
        NSLog(@"已傳了chuck");
        //NSArray *arrayFromData = [NSKeyedUnarchiver unarchiveObjectWithData:chunk];
         //NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        //NSLog(@"Sent: %@", arrayFromData);
        
        // It did send, so update our index
        self.ex_sendDataIndex += amountToSend;
        
        // Was it the last one?
        if (self.ex_sendDataIndex >= self.ex_dataToSend.length) {
            
            // It was - send an EOM
            
            // Set this so if the send fails, we'll send it next time
            sendingEOM = YES;
            
            // Send it
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.containCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                // It sent, we're all done
                sendingEOM = NO;
                
                NSLog(@"Sent: EOM");
            }
            
            return;
        }
    }
}


- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central unsubscribed from characteristic");
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]){
        
        //告知ViewController已將訊息順利傳出
        [self.delegate sucessfullySentMessageToChatID:self.privateChatID withContent:_messageContent];
        
        //來到這裡表示訊息已傳完了
        _messageContent=nil;
        
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:PUBLIC_CHARACTERISTIC_UUID]]){
        
        //告知ViewController已將訊息順利傳出
        [self.delegate sentOutgoingPublicMessage:_announcementContent];
        
        //來到這裡表示訊息已傳完了
        _announcementContent=nil;
        
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CONTAIN_CHARACTERISTIC_UUID]]){
        
        NSLog(@"有人已獲取自己的周圍資訊");
    }
    
    //已傳完訊息，開始掃描
    [self scan];
}

- (void)sendData
{
    // First up, check if we're meant to be sending an EOM
    static BOOL sendingEOM = NO;
    
    if (sendingEOM) {
        
        // send it
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.publicCharacteristic onSubscribedCentrals:nil];
        
        // Did it send?
        if (didSend) {
            
            // It did, so mark it as sent
            sendingEOM = NO;
            NSLog(@"Sent: EOM");
        }
        
        // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're not sending an EOM, so we're sending data
    
    // Is there any left to send?
    
    if (self.sendDataIndex >= self.dataToSend.length) {
        
        // No data left.  Do nothing
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    
    BOOL didSend = YES;
    
    while (didSend) {
        
        // Make the next chunk
        
        // Work out how big it should be
        NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
        
        // Send it
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.publicCharacteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            return;
        }
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"Sent: %@", stringFromData);
        
        // It did send, so update our index
        self.sendDataIndex += amountToSend;
        
        // Was it the last one?
        if (self.sendDataIndex >= self.dataToSend.length) {
            
            // It was - send an EOM
            
            // Set this so if the send fails, we'll send it next time
            sendingEOM = YES;
            
            // Send it
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.publicCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                // It sent, we're all done
                sendingEOM = NO;
                
                NSLog(@"Sent: EOM");
            }
            
            return;
        }
    }
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    // Start sending again
    if (_whichSessionTag==0) { //public
        [self sendData];
    }
    if (_whichSessionTag==1) { //private
        [self sendPrivateData];
    }
    if (_whichSessionTag==2) { //exchange
        [self sendExchangeData];
    }
}

- (void)sendPrivateData
{
    // First up, check if we're meant to be sending an EOM
    static BOOL sendingEOM = NO;
    
    if (sendingEOM) {
        // send it
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        // Did it send?
        if (didSend) {
            // It did, so mark it as sent
            sendingEOM = NO;
            NSLog(@"Sent: EOM");
        }
        // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're not sending an EOM, so we're sending data
    if (self.pri_sendDataIndex >= self.pri_dataToSend.length){ // Is there any left to send?
        // No data left.  Do nothing
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    BOOL didSend = YES;
    
    while (didSend) {
        // Make the next chunk
        // Work out how big it should be
        NSInteger amountToSend = self.pri_dataToSend.length - self.pri_sendDataIndex;
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.pri_dataToSend.bytes+self.pri_sendDataIndex length:amountToSend];
        // Send it
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            return;
        }
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"Sent: %@", stringFromData);
        // It did send, so update our index
        self.pri_sendDataIndex += amountToSend;
        // Was it the last one?
        if (self.pri_sendDataIndex >= self.pri_dataToSend.length) {
            // It was - send an EOM
            // Set this so if the send fails, we'll send it next time
            sendingEOM = YES;
            // Send it
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                // It sent, we're all done
                sendingEOM = NO;
                NSLog(@"Sent: EOM");
            }
            return;
        }
    }
}


#pragma mark - 各個機制方法

-(void) stopAdvertise
{
    [_peripheralManager stopAdvertising];
}

- (void) detectSurrounding
{
    //進入搜尋機制
    [self.peripheralList removeAllObjects]; //移除原有內容重新搜尋
    
    //load self name
    NSArray *setName=[NSArray array];
    setName=[_plistManager getRootArrayOfPlist:@"selfname.plist" underFolder:@"BooChat"];
    
    NSLog(@"開始廣播DETECT_UUID");
    [self.peripheralManager startAdvertising:@{ CBAdvertisementDataLocalNameKey:[setName objectAtIndex:0],CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:DETECT_SERVICE_UUID]]}];
    
    [self scan];
    
    [NSTimer scheduledTimerWithTimeInterval:7.0
                                     target:self
                                   selector:@selector(stopAdvertise)
                                   userInfo:nil
                                    repeats:NO];
}

-(void) publicAnnounce:(NSString *)announcement
{
    //進入公共聊天機制（無法確定是否有人收到，只能單純廣播）
    self.announcementContent=announcement; //存下要傳遞的訊息內容
    NSLog(@"%@",_announcementContent);
    
    //暫時停止掃描（怕與連線衝突）
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    [self cleanup];
    
    //load self name
    NSArray *setName=[NSArray array];
    setName=[_plistManager getRootArrayOfPlist:@"selfname.plist" underFolder:@"BooChat"];
    
    NSLog(@"開始廣播PUBLIC_UUID");
    [self.peripheralManager startAdvertising:@{ CBAdvertisementDataLocalNameKey:[setName objectAtIndex:0],CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:PUBLIC_SERVICE_UUID]] }];
    
    [NSTimer scheduledTimerWithTimeInterval:7.0
                                     target:self
                                   selector:@selector(stopAdvertise)
                                   userInfo:nil
                                    repeats:NO];
}

-(void) addFriendRequest:(NSString *)peripheralName
{
    //進入加好友機制
    
    //load self name
    NSArray *setName=[NSArray array];
    setName=[_plistManager getRootArrayOfPlist:@"selfname.plist" underFolder:@"BooChat"];
    
    //開始組成SDadress字串
    _originSDaddress=[setName objectAtIndex:0]; //先接上自己的名字
    _originSDaddress=[_originSDaddress stringByAppendingString:@"|"]; //再接上連接符號
    _originSDaddress=[_originSDaddress stringByAppendingString:peripheralName]; //最後街上對方的名字
    
    NSLog(@"開始廣播ADDFRIEND_UUID  %@",_originSDaddress);
    
    [self.peripheralManager startAdvertising:@{ CBAdvertisementDataLocalNameKey:_originSDaddress ,
                                                CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:ADDFRIEND_SERVICE_UUID]]}];
    [NSTimer scheduledTimerWithTimeInterval:7.0
                                     target:self
                                   selector:@selector(stopAdvertise)
                                   userInfo:nil
                                    repeats:NO];
}

-(void) checkBeside:(NSString *)peripheralName
{
    //進入在場檢測機制
    self.aroundName=nil;
    
    NSLog(@"開始廣播PRESENT_UUID");
    [self.peripheralManager startAdvertising:@{ CBAdvertisementDataLocalNameKey:peripheralName,CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:PRESENT_SERVICE_UUID]]}];
    
    [NSTimer scheduledTimerWithTimeInterval:7.0
                                     target:self
                                   selector:@selector(stopAdvertise)
                                   userInfo:nil
                                    repeats:NO];
}

-(void) transferMessage:(NSString *)message ToChatID:(NSString *)chatID
{
    //進入聊天機制
    self.messageContent=message; //存下要傳遞的訊息內容
    self.privateChatID=chatID;
    
    NSLog(@"開始廣播TRANSFER_UUID給特定的CHATID");
    NSLog(@"chatID: %@",chatID);
    [self.peripheralManager startAdvertising:@{ CBAdvertisementDataLocalNameKey:self.privateChatID,CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] }];
    
    [NSTimer scheduledTimerWithTimeInterval:7.0
                                     target:self
                                   selector:@selector(stopAdvertise)
                                   userInfo:nil
                                    repeats:NO];
}

-(void) exchangeInfo:(NSString *)peripheralName
{
    //進入交換資訊機制
    //load self name
    NSArray *setName=[NSArray array];
    setName=[_plistManager getRootArrayOfPlist:@"selfname.plist" underFolder:@"BooChat"];
    
    //開始組成SDadress字串
    _EXoriginSDaddress=[setName objectAtIndex:0]; //先接上自己的名字
    _EXoriginSDaddress=[_EXoriginSDaddress stringByAppendingString:@"|"]; //再接上連接符號
    _EXoriginSDaddress=[_EXoriginSDaddress stringByAppendingString:peripheralName]; //最後街上對方的名字
    
    NSLog(@"開始廣播EXCHANGE_UUID");
    [self.peripheralManager startAdvertising:@{ CBAdvertisementDataLocalNameKey:_EXoriginSDaddress ,CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:EXCHANGE_SERVICE_UUID]]}];
    
    [NSTimer scheduledTimerWithTimeInterval:7.0
                                     target:self
                                   selector:@selector(stopAdvertise)
                                   userInfo:nil
                                    repeats:NO];
}

#pragma mark - 其他彈出視窗
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex==0)
    {
        self.adderName=nil;
        self.adderChatID=nil;
        NSLog(@"使用者不願意加朋友");
        
        //恢復掃描
        [self scan];
    }
    else if(buttonIndex==1)
    {
        NSLog(@"使用者願意加朋友");
        
        //廣播告知對方意願並前來擷取CHATID
        NSLog(@"開始廣播CHATID_UUID");
        //NSLog(@"_copySDaddress:%@", self.copyedSDaddress);
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataLocalNameKey:_copyedSDaddress,CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:CHATID_SERVICE_UUID]]}];
    }
}

#pragma mark - NSCoding相關

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.codeArray=[decoder decodeObjectForKey:@"peripheralList"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.codeArray forKey:@"peripheralList"];
}

@end
