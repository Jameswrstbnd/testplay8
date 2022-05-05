//
//  QPCRFID.swift
//  nativeTemplate
//
//  Created by Navon Hobby on 4/30/22.
//  Copyright © 2022 Facebook. All rights reserved.
//

import Foundation
import QuantumSDK

@objc(QPCRFID)
class QPCRFID: RCTEventEmitter, IPCDTDeviceDelegate {

   var rfidScanner=IPCDTDevices.sharedDevice()!

  @objc(requiresMainQueueSetup)
  override static func requiresMainQueueSetup() -> Bool {
    return true;
  }
  
  // we need to override this method and
    // return an array of event names that we can listen to
    override func supportedEvents() -> [String]! {
      return [PaymentConfig.RFIDMessage, PaymentConfig.RFIDError, PaymentConfig.RFIDConnectionState,PaymentConfig.RFIDCardDetected, PaymentConfig.RFIDCardRemoved]
    }
  
  
  @objc
  func initalizeRFID(_ developerKey:String)-> Void{
    let ipciq = IPCIQ.register()
    try? ipciq?.setDeveloperKey(developerKey)
  }
  
  @objc(getBatterStatus)
  func getBatterStatus(){

    //-(BOOL)getBatteryCapacity:(int *)capacity voltage:(float *)voltage error:(NSError **)error;

    var capacity:Int32 = 0
    var voltage:Float = 0.0
    var stringBatteryPercentage:String = ""
   
    do {
      try rfidScanner.getBatteryCapacity(&capacity, voltage: &voltage)
        stringBatteryPercentage = String(capacity)
    }catch{
      print("Unexpected error: \(error).")
    }
    
    sendEvent(withName: PaymentConfig.BatteryStatus, body:stringBatteryPercentage)

  }
  @objc(connectRFID)
  func connectRFID() -> Void{
    
    print("connect RFID called")
    rfidScanner.addDelegate(self)
    rfidScanner.connect()
  }
  
  @objc(removeRFID)
  func removeRFID()-> Void{
    
    rfidScanner.removeDelegate(self)
    do {
        try rfidScanner.rfClose()
    } catch {
    }
  }
  
  @objc(scanRFID)
  func scanRFID() -> Void{
      
    do {
        try rfidScanner.rfInit(CARD_SUPPORT_PICOPASS_ISO15|CARD_SUPPORT_TYPE_A|CARD_SUPPORT_TYPE_B|CARD_SUPPORT_ISO15|CARD_SUPPORT_FELICA)
      sendEvent(withName: PaymentConfig.RFIDMessage, body:PaymentConfig.RFIDMessage)
      //RFIDMessage
        
    } catch {
      sendEvent(withName: PaymentConfig.RFIDError, body:error.localizedDescription)

    }
  }
  
  func connectionState(_ state: Int32) {

      
    sendEvent(withName: PaymentConfig.RFIDConnectionState, body:"RFID Device connected")

      if state==CONN_STATES.CONNECTED.rawValue
      {
          if rfidScanner.getSupportedFeature(FEATURES.FEAT_PRINTING, error: nil) != FEAT_UNSUPPORTED {

          }
          if rfidScanner.getSupportedFeature(FEATURES.FEAT_MSR, error: nil) != FEAT_UNSUPPORTED || rfidScanner.getSupportedFeature(FEATURES.FEAT_PIN_ENTRY, error: nil)
              == FEAT_UNSUPPORTED {
          }
          if rfidScanner.getSupportedFeature(FEATURES.FEAT_EMVL2_KERNEL, error: nil) != FEAT_UNSUPPORTED {
              //tabs.append(getViewController(name: "EMV"))
             // tabs.append(getViewController(name: "EMVMS"))
          }
          if rfidScanner.getSupportedFeature(FEATURES.FEAT_RF_READER, error: nil) != FEAT_UNSUPPORTED {

          }

          do {
              try setAlgorithm(lib: rfidScanner)
          } catch {
          }
      }
      
  }
  
   func getSelectedAlgorithm() -> (Int32, Int32, [AnyHashable: Any]) {
      var params : [AnyHashable: Any] = [:]
      var keyID: Int32 = -1 //if -1, automatically selects the first available key for the specified algorithm

      var algorithm: Int32 = ALG_EH_IDTECH

      let prefs = UserDefaults.standard;
      if prefs.value(forKey: "Algorithm") != nil {
          algorithm = Int32(prefs.integer(forKey: "Algorithm"))
      }

      if(algorithm==ALG_EH_VOLTAGE)
      {
          params["encryption"] = "SPE"
          params["merchantID"] = "0123456"
      }
      if(algorithm==ALG_EH_IDTECH)
      {//Just a demo how to select key
          keyID = 0
      }
      if(algorithm==ALG_EH_MAGTEK)
      {//Just a demo how to select key
          keyID = KEY_EH_DUKPT_MASTER1
      }
      if(algorithm==ALG_EH_AES128)
      {//Just a demo how to select key
          keyID = KEY_EH_AES128_ENCRYPTION1
      }
      if(algorithm==ALG_EH_AES256)
      {//Just a demo how to select key
          keyID = KEY_EH_AES256_ENCRYPTION1
      }
      if(algorithm==ALG_PPAD_DUKPT)
      {//Just a demo how to select key, in the pinpad, the dukpt keys are between 0 and 7
          keyID = 0
      }
      if(algorithm==ALG_PPAD_3DES_CBC)
      {//Just a demo how to select key, in the pinpad, the 3des keys are from 1 to 49, key 1 is automatically selected if you pass 0
          //the key loaded needs to be data encryption 3des type, or card will not read. Assuming such is loaded on position 2:
          keyID = 2
      }
      if(algorithm==ALG_EH_IDTECH_AES128)
      {//Just a demo how to select key
          keyID = KEY_EH_DUKPT_MASTER1
      }
      if(algorithm==ALG_EH_MAGTEK_AES128)
      {//Just a demo how to select key
          keyID = KEY_EH_DUKPT_MASTER1
      }

      return (algorithm, keyID, params)
  }
  
   func setAlgorithm(lib: IPCDTDevices) throws {

      let (algorithm, keyID, params) = getSelectedAlgorithm()

      try lib.emsrSetEncryption(algorithm, keyID:keyID, params: params as [AnyHashable: AnyObject])
  }
  
  //#define CHECK_RESULT(description,result) if(result){[log appendFormat:@"%@: SUCCESS\n",description]; NSLog(@"%@: SUCCESS",description);} else {[log appendFormat:@"%@: FAILED (%@)\n",description,error.localizedDescription]; NSLog(@"%@: FAILED (%@)\n",description,error.localizedDescription); }

  //    #define DF_CMD(command,description) r=[dtdev iso14Transceive:info.cardIndex data:[NSData dataWithBytes:command length:sizeof(command)] status:&cardStatus error:&error]; \
  //    if(r) [log appendFormat:@"%@ succeed with status: %@ response: %@\n",description,dfStatus2String(cardStatus),r]; else [log appendFormat:@"%@ failed with error: %@\n",description,error.localizedDescription];


  //support functions
  //#define MIARE_USE_STORED_KEY
  func mifareAuthenticate(cardIndex: Int32, address: Int32, key:[UInt8]?) throws {

      var keyData:Data? = nil
      if key==nil
      {
          let defaultMifareKey:[UInt8] = [0xFF,0xFF,0xFF,0xFF,0xFF,0xFF]
          //use the default key
          keyData = defaultMifareKey.getNSData()
      }

      try rfidScanner.mfAuth(byKey: cardIndex, type: 0x41, address: address, key: keyData)
  }



  //helper func to write some ordinary data on mifare classic cards without touching the sectors containing the sensitive data
  //like keys being used
  func mifareSafeWrite(cardIndex: Int32, address:Int32, data:[UInt8], key:[UInt8]?) throws {

      guard address >= 4 else {
          return
      }

      var lastAuth: Int32 = -1
      var addr = address;
      var written = 0
      while written < data.count {
          if (addr % 4) == 3 {
              addr += 1;
              continue
          }
          if lastAuth != (addr / 4) {
              lastAuth = addr / 4
              try mifareAuthenticate(cardIndex: cardIndex, address: addr, key: key)
          }
          let block = data.subArray(written, end: min(16, data.count - written))

          var bytesWritten: Int32 = 0;
          try rfidScanner.mfWrite(cardIndex, address: addr, data: block.getNSData(), bytesWritten: &bytesWritten)
          written += Int(bytesWritten)
          addr += 1;
      }
  }

  //helper func to read some ordinary data from mifare classic cards without touching the sectors containing the sensitive data
  //like keys being used
  func mifareSafeRead(cardIndex: Int32, address:Int32, length: Int, key:[UInt8]?) throws -> [UInt8] {
      var data = [UInt8]()
      var lastAuth: Int32 = -1
      var addr = address;
      var read = 0
      while read < length {
          if (addr % 4) == 3 {
              addr += 1;
              continue
          }
          if lastAuth != (addr / 4) {
              lastAuth = addr / 4
              try mifareAuthenticate(cardIndex: cardIndex, address: addr, key: key)
          }

          let block = try rfidScanner.mfRead(cardIndex, address: addr, length: 16)
          data.append(contentsOf: block)
          read += block.count
          addr += 1;
      }
      return data
  }

  func dfStatus2String(status: UInt8) -> String
  {
      switch (status)
      {
      case 0x00:
          return "OPERATION_OK";
      case 0x0C:
          return "NO_CHANGES";
      case 0x0E:
          return "OUT_OF_EEPROM_ERROR";
      case 0x1C:
          return "ILLEGAL_COMMAND_CODE";
      case 0x1E:
          return "INTEGRITY_ERROR";
      case 0x40:
          return "NO_SUCH_KEY";
      case 0x7E:
          return "LENGTH_ERROR";
      case 0x9D:
          return "PERMISSION_DENIED";
      case 0x9E:
          return "PARAMETER_ERROR";
      case 0xA0:
          return "APPLICATION_NOT_FOUND";
      case 0xA1:
          return "APPL_INTEGRITY_ERROR";
      case 0xAE:
          return "AUTHENTICATION_ERROR";
      case 0xAF:
          return "ADDITIONAL_FRAME";
      case 0xBE:
          return "BOUNDARY_ERROR";
      case 0xC1:
          return "PICC_INTEGRITY_ERROR";
      case 0xCD:
          return "PICC_DISABLED_ERROR";
      case 0xCE:
          return "COUNT_ERROR";
      case 0xDE:
          return "DUPLICATE_ERROR";
      case 0xEE:
          return "EEPROM_ERROR";
      case 0xF0:
          return "FILE_NOT_FOUND";
      case 0xF1:
          return "FILE_INTEGRITY_ERROR";
      default:
          return "UNKNOWN";
      }
  }

  func dfCommand(description: String, cardIndex: Int32, data:[UInt8]) -> Bool {

      do {
          var status: UInt8 = 0
          let r = try rfidScanner.iso14Transceive(cardIndex, data: data.getNSData(), status: &status)
          let statusStr = dfStatus2String(status: status)
        print("\(description) succeeded with status \(statusStr)(\(status)) and response: \(r.toHexString())\n")
          return true
      } catch {
        print("\(description) failed: \(error.localizedDescription)\n")
      }
      return false
  }

  //rf delegates
  func rfCardRemoved(_ cardIndex: Int32) {
    
    let cardIndexString = String(cardIndex)
    print("\nCard removed")
    sendEvent(withName: PaymentConfig.RFIDCardRemoved, body:cardIndexString)

    }

  func rfCardDetected(_ cardIndex: Int32, info: DTRFCardInfo!) {

    //  Progress.show(self);
      RunLoop.current.run(until: Date.init(timeIntervalSinceNow: 0.1)) //just to show the progress, the correct way is to get all this on a separate thread

    do {
        let sound: [Int32] = [2730,150,0,30,2730,150];
        try rfidScanner.playSound(100, beepData: sound, length: Int32(sound.count*4))
    } catch {
      print("Error in beep")
    }
    
    let cardData = "\(info.typeStr!) card detected\n" + "Serial: \(info.uid.toHexString())\n"
    
    sendEvent(withName: PaymentConfig.RFIDCardDetected, body:info.uid.toHexString())

    print(cardData)
      
    var success = true

      switch (info.type)
      {
      case .CARD_MIFARE_DESFIRE:
          //delay the communication a bit, giving time the card to be more fully inserted into the field
          //it can happen that the card is detected, but not having enough power to do cryptography
          Thread.sleep(forTimeInterval: 0.3)

          do {
              let ats = try rfidScanner.iso14GetATS(cardIndex)
             // tvInfo.text.append("ATS Data: \(ats.toHexString())\n")
            print(ats.toHexString())
          } catch {
             // tvInfo.text.append("Get ATS failed: \(error.localizedDescription)\n")
              print("Get ATS failed: \(error.localizedDescription)\n")
              success = false
          }

          let SELECT_APPID_MASTER: [UInt8] = [ 0x5A, 0x00, 0x00, 0x00 ]
          //            let SELECT_APPID_WRONG: [UInt8] = [ 0x5A, 0x00, 0x00, 0x01 ]
          let AUTH_ROUND_ONE: [UInt8] = [ 0xAA, 0x00 ]

          if !dfCommand(description: "Select master application", cardIndex: cardIndex, data: SELECT_APPID_MASTER) {
              success = false
          }

          if !dfCommand(description: "Authenticate round 1", cardIndex: cardIndex, data: AUTH_ROUND_ONE) {
              success = false
          }

          break

      case .CARD_MIFARE_MINI, .CARD_MIFARE_CLASSIC_1K, .CARD_MIFARE_CLASSIC_4K, .CARD_MIFARE_PLUS:
          //16 bytes reading and 16 bytes writing
          //it is best to store the keys you are going to use once in the device memory, then use mfAuthByStoredKey function to authenticate blocks rahter than having the key in your program

          do {
              let dataToWrite:[UInt8]=[0xFF,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F,0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D,0x2E,0x2F];
              try mifareSafeWrite(cardIndex: cardIndex, address: 8, data: dataToWrite, key: nil)
             // tvInfo.text.append("Mifare write complete!\n")
          } catch {
            
              print("Mifare write failed: \(error.localizedDescription)\n")
              success = false
          }
          do {
              let block = try mifareSafeRead(cardIndex: cardIndex, address: 8, length: 4*16, key: nil)
              print("Mifare read complete: \(block.toHexString())\n")
              //tvInfo.text.append("Mifare read complete: \(block.toHexString())\n")
          } catch {
                print("Mifare read failed: \(error.localizedDescription)\n")
              success = false
          }
          break

      case .CARD_MIFARE_ULTRALIGHT, .CARD_MIFARE_ULTRALIGHT_C:
          //16 bytes reading, 4 bytes writing
          Thread.sleep(forTimeInterval: 0.5) //give the card some time if we are going to try crypto operations
          //try reading a block
          do {
              let block = try rfidScanner.mfRead(cardIndex, address: 8, length: 16)
            print("Mifare read complete: \(block.toHexString())\n")
          } catch {
            print("Mifare read failed: \(error.localizedDescription)\n")

              success = false
          }

          do {
              try rfidScanner.mfUlcAuth(byKey: cardIndex, key: "BREAKMEIFYOUCAN!".data(using: .ascii))
            print("Mifare authenticate complete\n")
          } catch {
            
            print("Mifare authenticate failed: \(error.localizedDescription)\n")
              success = false
          }
          /*
          do {
              let key: Data = [0x3F , 0xEA , 0x14 , 0x44 , 0xAB , 0x7F , 0xAE , 0x60 , 0xD6 , 0x19 , 0x94 , 0x13 , 0x65 , 0x6E , 0x25 , 0x60]
              let device = IPCDTDevices.sharedDevice()

              try device?.mfUlcAuth(byKey: cardIndex, key: Data(bytes: key))



          } catch {

              print("auth id failed======\(error)")


          }
*/
          do {
              let block = try rfidScanner.mfRead(cardIndex, address: 8, length: 16)
              print("Mifare read complete: \(block.toHexString())\n")

          } catch {
            
            print("Mifare read failed: \(error.localizedDescription)\n")
              success = false
          }

          //change key
          do {
              try rfidScanner.mfWrite(cardIndex, address: 0x2C, data: "12345678abcdefgh!".data(using: .ascii), bytesWritten: nil)
            print("Mifare write complete\n")

          } catch {
            
            print("Mifare write failed: \(error.localizedDescription)\n")
              success = false
          }
          break;

      case .CARD_ISO15693:
          //block size is different between cards
          //tvInfo.text.append("Block size: \(info.blockSize)\n")
         // tvInfo.text.append("Number of blocks: \(info.nBlocks)\n")

          do {
              let security = try rfidScanner.iso15693GetBlocksSecurityStatus(cardIndex, startBlock: 0, nBlocks: 16)
            print("Security status: \(security.toHexString())\n")

          } catch {
              print("Security status failed: \(error.localizedDescription)\n")
              success = false
          }

          //write something to the card
          do {
              let dataToWrite:[UInt8]=[0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07]
              try rfidScanner.iso15693Write(cardIndex, startBlock: 0, data: dataToWrite.getNSData(), bytesWritten: nil)
            
              print("Write complete\n")

          } catch {
            print("Write failed: \(error.localizedDescription)\n")

              success = false
          }

          //try reading 2 blocks
          do {
              let block = try rfidScanner.iso15693Read(cardIndex, startBlock: 0, length: 2*info.blockSize)
            print("Read complete: \(block.toHexString())\n")

          } catch {
              print("Read failed: \(error.localizedDescription)\n")
              success = false
          }
          break;

      case .CARD_FELICA:
          //16 byte blocks for both reading and writing

          //custom command
          do {
              let readCmd:[UInt8]=[0x01,0x09,0x00,0x01,0x80,0x00]
              let cmdResponse = try rfidScanner.felicaSendCommand(cardIndex, command: 0x06, data: readCmd.getNSData())
            print("Custom command: \(cmdResponse.toHexString())\n")

          } catch {

              print("Custom command failed: \(error.localizedDescription)\n")
              success = false
          }

          //check if the card is FeliCa SmartTag or normal felica
          let uid = info.uid.getBytes()!
          if uid[0]==0x03 && uid[1]==0xFE && uid[2]==0x00 && uid[3]==0x1D
          {//SmartTag
              //read battery, call this command ALWAYS before communicating with the card
              do {
                  var battery:Int32 = 0;
                  try rfidScanner.felicaSmartTagGetBatteryStatus(cardIndex, status: &battery)
                  var batteryString = "Unknown"
                  switch FELICA_SMARTTAG_BATERY_STATUSES(rawValue: battery)! {
                  case .BATTERY_NORMAL1, .BATTERY_NORMAL2:
                      batteryString = "Normal"
                      break

                  case .BATTERY_LOW1:
                      batteryString = "Low"
                      break

                  case .BATTERY_LOW2:
                      batteryString = "Very low"
                      break
                  }

                print("SmartTag battery: \(batteryString)\n")

              } catch {
                
                print("SmartTag battery failed: \(error.localizedDescription)\n")

                  success = false
              }


          }else
          {//Normal

              //write 1 block
              do {
                  let dataToWrite:[UInt8]=[0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F]
                  try rfidScanner.felicaWrite(cardIndex, serviceCode: 0x0900, startBlock: 0, data: dataToWrite.getNSData(), bytesWritten: nil)
                
                print("Write complete\n")

              } catch {
                print("Write failed: \(error.localizedDescription)\n")
                  success = false
              }

              //read 1 block
              do {
                  let block = try rfidScanner.felicaRead(cardIndex, serviceCode: 0x0900, startBlock: 0, length: info.blockSize)
                print("Read complete: \(block.toHexString())\n")

              } catch {
                
                print("Read failed: \(error.localizedDescription)\n")

                  success = false
              }
          }

          break

      default:
          break
      }

      // here you can do operation if you wanna do some specific action in case of success or failure
      if success {
        
      } else {
      }

      //Progress.hide()

      do {
          try rfidScanner.rfRemoveCard(cardIndex)
      } catch {
      }
  }

   
}
