//
//  QPCConfigBridge.m
//  ReactNativeQPC
//
//  Created by Christopher Maheu on 3/4/22.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_REMAP_MODULE(RNQPCPaymentController,QPCConfig, RCTEventEmitter)

/// ** A payment transaction flow
/// 1. Create PaymentEngine and connect to payment device.
/// 2. Setup callbacks to see transaction progress
/// 3. Create Invoice (optional on EVO, required on FreedomPay)
/// 4. Create Transaction with the Invoice created
/// 5. Start Transaction

RCT_EXTERN_METHOD(initializeQPCDevice)
RCT_EXTERN_METHOD(printReceipt)
RCT_EXTERN_METHOD(onClickStartEngine)
RCT_EXTERN_METHOD(onClickConnect)
RCT_EXTERN_METHOD(onClickStartTransaction)
RCT_EXTERN_METHOD(onClickStopTransaction)
RCT_EXTERN_METHOD(onClickPrintReciept)
RCT_EXTERN_METHOD(connectScannerDevice)

RCT_EXTERN_METHOD(onClickCheckDatabaseTransactions)
RCT_EXTERN_METHOD(onClickUploadStoredTransaction)
RCT_EXTERN_METHOD(onClickUpdateFirmware)

//Function with params
RCT_EXTERN_METHOD(addText:(NSString *)txtDescription)

RCT_EXTERN_METHOD(startNewTransaction:(NSString *)amount:(NSString *)companyName:(NSString *)referenceNumber:(NSString*)productCode:(NSString*)unitPrice:(NSString *)invoiceDescription:(NSString *)productDescription:(NSString *)quantity:(NSString *)invoiceNumber)


// RFID

RCT_EXTERN_METHOD(connectRFID)


+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

@end
