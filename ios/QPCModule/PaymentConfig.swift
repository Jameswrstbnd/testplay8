//
//  SampleConfig.swift
//  QuantumPaySDK_Swift_Test
//
//  Created by Kyle M on 2/23/21.
//

import Foundation

import QuantumPayClient
import QuantumPayMobile
import QuantumPayPeripheral

@objcMembers
public class PaymentConfig: NSObject {
    // Developer key that works with this bundle ID: "com.ipc.QPayObjC"
    public static let developerKey = "vSpVLHzYL3eBE4gEW5tbwPkMw1TKQREyVJg+qmVy5ADAXl0jWSVBuNR+V9s26rKgRlmByse7IWs6ghTTDHfaRw=="//"vSpVLHzYL3eBE4gEW5tbwPkMw1TKQREyVJg+qmVy5ADAXl0jWSVBuNR+V9s26rKgRlmByse7IWs6ghTTDHfaRw=="

    // ******* Create a payment device **********
    // Attached device. Serial will be collecting directly from the device
    public static let peripheral = QPC250()
    
    // BLE device need the serial to scan for and connect to
    // Set the corresponding BLE payment object and its serial
    //public static let peripheral = QPR250(serial: "2321000335")
    // ******************************************
    
    public static let hostKey:String = "us"
    
    // QuantumPay Cloud Server Tenant Key
    public static let tenantKey:String = "demo2"
    
    // QuantumPay Device Administrator Username
    public static let username: String = "devicemanager@demo2.com"
    
    // QuantumPay Device Administrator Password
    public static let password: String = "Tr!4lrun2"
    
    // QuantumPay Service Account Key - controls the merchant account the payment will be sent to
    public static let service: String = "EvoPayTest"
    
    // Your unique POS ID that your transactions will be registered against
    // This ID is important, and must the same at every load for app to operate correctly.
    public static let posId: String = Bundle.main.bundleIdentifier!
        
    // Sample code transaction reference
    public static var testReference: String = ""
    
    // Sample code transaction amount
    public static let testAmount: Decimal = 1.00
    
    // Sample code transaction currency
    public static let testCurrency: Currency = Currency.USD;
    
    // Sample code secure format
    public static let useSecureFormat: SecureFormat = SecureFormat.idTech;
  
  // React Native Emitter events
  public static let onConnectedWithBlueTooth:String = "onConnectedWithBlueTooth"
  public static let onDisconnectedWithBlueTooth:String = "onDisconnectedWithBlueTooth"
  public static let onScanBarCode:String = "onScanBarCode"
  public static let onUpdateFirmWare:String = "onUpdateFirmWare"

  // Transactions
  public static let transactionUploaded:String = "transactionUploaded"
  public static let transactionResult:String = "transactionResult"
  public static let transactionReciept:String = "transactionReciept"
  public static let transactionState:String = "transactionState"
  public static let transactionStop:String = "transactionStop"
  public static let transactionStopError:String = "transactionStopError"

  public static let transactionList:String = "transactionList"
  public static let transactionNotfound:String = "transactionNotfound"
  public static let transactionEmpty:String = "transactionEmpty"
  public static let transactionUploadingError:String = "transactionUploadingError"

  // Start Engine handlers
  public static let engineCreated:String = "engineCreated"
  public static let engineConnectedState:String = "engineConnectedState"
  
  //Peripheral
  public static let PeripheralState:String = "PeripheralState"
  public static let PeripheralMessage:String = "PeripheralMessage" 
  
  //Errors
  public static let errorEVM: String = "errorEVM"
  public static let errorTransaction:String = "errorTransaction"

  
  // RFID
  public static let RFIDConnectionState: String = "RFIDConnection"
  public static let magneticCardEncryptedData:String = "magneticCardEncryptedData"
  public static let magneticCardData:String = "magneticCardData"
  
  public static let RFIDMessage:String = "Put RFID Card in the field"
  public static let RFIDError:String = "RFID Error: "
  public static let RFIDCardDetected:String = "RFIDCardDetected"
  public static let RFIDCardRemoved:String = "RFIDCardRemoved"
  public static let BatteryStatus:String = "BatteryStatus"


  
}
