  //
  //  QPCConfig.swift
  //  ReactNativeQPC
  //
  //  Created by Christopher Maheu on 3/4/22.
  //

  import Foundation
  import QuantumPayClient
  import QuantumPayMobile
  import QuantumSDK
  import QuantumPayPeripheral

  @objc(QPCConfig)
  class QPCConfig: RCTEventEmitter, IPCDTDeviceDelegate {
    
    var pEngine: PaymentEngine?
    var transaction: Transaction?
    var transactionResult: TransactionResult?
    var connectedPrinter: CBPeripheral?
    /// Printer BLE device
    let printerWPP250 = "PMM000014UN20"
    
    /// Payment device
    
    var paymentDevice: QuantumPayPeripheral.InfinitePeripheralsDevice!
        
    @objc(requiresMainQueueSetup)
    override static func requiresMainQueueSetup() -> Bool {
      return true;
    }
    
   
    @objc
    func initializeQPCDevice(_ developerKey:String, _ hostKey:String, _ tenantKey:String) -> Void {
      
      // Do any additional setup after loading the view.
      
      /// ** A payment transaction flow
      /// 1. Create PaymentEngine and connect to payment device.
      /// 2. Setup callbacks to see transaction progress
      /// 3. Create Invoice (optional on EVO, required on FreedomPay)
      /// 4. Create Transaction with the Invoice created
      /// 5. Start Transaction
      
      /// ** IMPORTANT
      /// If you dont use the payment device outside of QuantumPay for barcode scanning, this call is needed here to set tenantKey prior to using the PaymentEngine.
      /// This project setup as a mix of Objective C and Swift. And there is a separate flow to only do scanning without the use of Quantum pay
      /// so this method is called in ViewController
      // InfinitePeripherals.initialize(developerKey: PaymentConfig.developerKey, tenantKey: PaymentConfig.tenantKey)
      /// ********************************
      
      /// **To check payment related settings, please take a look at PaymentConfig.swift**
      
      /// 0: Optional - Setup Tab M, Barcode Scanners and Printer devices delegate
      /// Add self as the delegate for IPCDTDevices and receives device functions callbacks for barcode scanning
      
      DispatchQueue.main.async {
        // Initialize QuantumPay
        InfinitePeripherals.initialize(developerKey: developerKey, tenant: Tenant(hostKey: hostKey, tenantKey: tenantKey))
        
          // Initialize payment device
        self.paymentDevice = QPC250()
      }
    }

    @objc
    func addText(_ text: String) {
        print(text)
        DispatchQueue.main.async {
           // self.outputTextView.text = "\(text)\n" + self.outputTextView.text
        }
    }
    
    @objc(printReceipt)
    func printReceipt() {
        var error: NSError?
        
        // Extra check to only print if one of the devices connected supports printing.
        let supported = self.paymentDevice.device.getSupportedFeature(FEATURES.FEAT_PRINTING, error: &error) > 0 ? true: false
        if supported {
            // Print here
            if let transaction = self.transaction{
                self.printToDevice(self.printLine(center:transaction.invoice!.companyName!))
                self.printToDevice(" ")
                self.printToDevice("_______________________________")
                self.printToDevice(" ")
                self.printToDevice(self.printLine(center: "SALE"))
                self.printToDevice(" ")
                self.printToDevice(self.printLine(left: "Merchant", right: PaymentConfig.service))
                self.printToDevice(self.printLine(left: transaction.properties!.scheme.stringValue().capitalized, right: transaction.properties!.maskedPAN!))
                self.printToDevice(" ")
                self.printToDevice(self.printLine(center: self.transactionResult!.status.stringValue().uppercased()))
                self.printToDevice(self.printLine(left: "Date", right: "\(transaction.transactionDateTime)"))
                self.printToDevice(self.printLine(left: "Order #", right: "\(transaction.transactionReference)"))
                self.printToDevice(" ")
                self.printToDevice(self.printLine(left: "Total", right: "\(transaction.transactionAmount) \(transaction.currency.code)"))
                self.printToDevice(" ")
                self.printToDevice(self.printLine(center: "I agree to pay the above total amount according to card issuer agreement."))
                self.printToDevice(" ")
                self.printToDevice(" ")
                self.printToDevice(" ")
                self.printToDevice(" ")
                self.printToDevice("_______________________________")
                self.printToDevice(" ")
                self.printToDevice(self.printLine(center: "Customer Signature"))
                self.printToDevice(" ")
                self.printToDevice(" ")
                self.printToDevice(self.printLine(center: "Thank You"))
                self.printToDevice(" ")
                self.printToDevice(" ")
                self.printToDevice(" ")
                self.printToDevice(" ")
                
                // Disconnect
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    try? self.paymentDevice.device.btleDisconnect(self.connectedPrinter)
                }
            }
        }
    }
    
    // Helpers
    func printToDevice(_ message: String) {
        try? self.paymentDevice.device.prnPrintText("\(message)")
    }
    
    func printLine(center: String) -> String {
        return "{=C}\(center)"
    }
    
    func printLine(left: String, right: String) -> String {
        // Total chars has to be 32
        if left.count + right.count > 32 {
            return ""
        }
        
        let spaces = String(repeating: " ", count: 32 - left.count - right.count)
        let printLine = "{=L}\(left)\(spaces)\(right)"
        return printLine
    }
    
    func json(from object:Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
    //Connect payment device QPC250 for barcode scanning
    @objc(connectScannerDevice)
    func connectScannerDevice(){
      
      self.paymentDevice.device.addDelegate(self)
      self.paymentDevice.connect { peripheral, connectionState in
          print("device connected")
      }
      
    }
    
 
    
    //Connect to payment engine
    @objc(onClickConnect)
    func onClickConnect(){
      self.pEngine!.connect()
    }
    
    // start engine
    @objc(onClickStartEngine)
      func onClickStartEngine(){
      do {
          try PaymentEngine.builder()
          /// The server where the payment is sent to for processing
              .server(server: ServerEnvironment.test)
          /// Specify the username and password that will be used for authentication while registering peripheral devices with the Quantum Pay server. The provided credentials must have Device Administrator permissions. Optional.
              .registrationCredentials(username: PaymentConfig.username, password: PaymentConfig.password)
          /// Add a supported peripheral for taking payment, and specify the available capabilities
          /// If you want to auto connect the payment device, set the autoConnect to true,
          /// otherwise set to false and manually call paymentEngine.connect() where approriate in your workflow.
              .addPeripheral(peripheral: self.paymentDevice, capabilities: self.paymentDevice.availableCapabilities!, autoConnect: false)
          /// Specify the unique POS ID for identifying transactions from a particular phone or tablet. Any string value
          /// can be used, but it should be unique for the instance of the application installation. A persistent GUID is
          /// recommended if the application does not already have persistent unique identifiers for app installs.
          /// Required.
              .posID(posID: PaymentConfig.posId)
          /// Specify the Mobile.EmvApplicationSelectionStrategy to use when a presented payment card supports multiple EMV applications and the user or customer must select one of them to be able to complete the transaction. Optional.
              .emvApplicationSelectionStrategy(strategy: .first)
          /// Specify the time interval that the Peripheral will wait for a card to be presented when a transaction is
          /// started. Optional. The default value for is 1 minute when not specified.
              .transactionTimeout(timeoutInSeconds: 30)
          /// Specify the StoreAndForwardMode for handling card transactions. Optional.
              .storeAndForward(mode: .whenOffline, autoUploadInterval: 60)
          /// Builds the PaymentEngine instance with all of the specified options and the specified handler will receive the instance when completed.
              .build(handler: { (engine) in
                  // Continue set up engine in here
                  self.addText("Engine created - posID: \(PaymentConfig.posId)")

                  // Send event through emmiter, later to catch this event in react native
                  self.sendEvent(withName: PaymentConfig.engineCreated, body: PaymentConfig.posId)


                  /// Save the engine for operation
                  self.pEngine = engine


                  /// **2. Setup callbacks**
                  /// The connection state handler that will return status of the peripheral (Conneted, connecting, or disconnected)
                  self.pEngine!.setConnectionStateHandler(handler: { (peripheral, connectionState) in
                      self.addText("Connection state: \(connectionState)")

                      //send event through emmiter, later to catch this event in React Native code
                      self.sendEvent(withName: PaymentConfig.engineConnectedState, body: connectionState)

                  })

                  /// The transaction result notify when transaction is completed. Once the transaction is completed and approved, the receipt URL will be avaiable.
                  self.pEngine!.setTransactionResultHandler(handler: { (transactionResult) in
                      self.addText("Transaction result: \(transactionResult.status)")
                      self.addText("Receipt: \(transactionResult.receipt?.customerReceiptUrl ?? "")")

                      self.sendEvent(withName: PaymentConfig.transactionResult, body: transactionResult.status)
                      self.sendEvent(withName: PaymentConfig.transactionReciept, body: transactionResult.receipt?.customerReceiptUrl ?? "")
                      // This object contains the result of the transaction
                      self.transactionResult = transactionResult
                  })

                  /// The state of transaction throughout the process
                  self.pEngine!.setTransactionStateHandler(handler: { (peripheral, transaction, transactionState) in
                      self.addText("Transaction state: \(transactionState)")

                      self.sendEvent(withName: PaymentConfig.transactionState, body: transactionState)
                      // The transaction object saved for receipt printing purposes.
                      self.transaction = transaction
                  })

                  /// Represents the current state of the peripheral, as reported by the peripheral device itself.
                  self.pEngine?.setPeripheralStateHandler(handler: { (peripheral, state) in
                      self.addText("Peripheral state: \(state)")
                      self.sendEvent(withName: PaymentConfig.PeripheralState, body: state)
                  })

                  /// Represents a User Interface message that should be displayed within the application, as reported by the peripheral device.
                  self.pEngine?.setPeripheralMessageHandler(handler: { (peripheral, message) in
                      self.addText("Peripheral message: \(message)")
                      self.sendEvent(withName: PaymentConfig.PeripheralMessage, body: message)
                  })
              })
      }
      catch {
          print("Payment engine error: \(error.localizedDescription)")
      }
    }
    
    @objc(onClickPrintReciept)
    func onClickPrintReciept(){
      
        // If we are connected to a classic bluetooth printer, just print the receipt
      if let _ = try? self.paymentDevice.device.prnGetPrinterInfo() {
          // Have a printer
          self.printReceipt()
          return
      }
  
      // **** for BLE printer ****
      // If we are still connected, just print receipt
      if self.connectedPrinter != nil {
          self.printReceipt()
          return
      }
      
      // Only search and connect to printer if the transaction result is approved
      if let result = self.transactionResult, result.status == .approved {
          self.addText("Looking for printer")
          
          // This is a blocking function. Probably a good idea to run this in background.
          if let devices = try? self.paymentDevice.device.btleDiscoverSupportedDevices(BLUETOOTH_FILTER.ALL.rawValue, stopOnFound: false) {
              for device in devices {
                  if device.name!.contains(self.printerWPP250) {
                      try? self.paymentDevice.device.btleConnect(toDevice: device)
                      break
                  }
              }
          }
      }
    }

    
    // What ever value came from alert it will take this amount and create transaction
    @objc
    func startNewTransaction(_ amount: String,_ companyName:String,_ referenceNumber:String,_ productCode:String,_ unitPrice:String,_ invoiceDescription:String,_ productDescription:String,_ quantity:String,_ invoiceNumber:String) {
        
      if self.pEngine == nil {
          print("engine is empty")
          return
      }
        
      do {
            /// **3: Create the invoice for the transaction**
            let invoiceNum = invoiceNumber
            let transactionRef = "\(arc4random() % 99999)"
          
            guard let amountValue =  Decimal(string: amount) else { return }
            guard let productUnitPrice = Decimal(string: unitPrice) else {return}
            guard let productQuantity = Int(quantity) else {return}
          
            let invoice = try self.pEngine!.buildInvoice(reference: invoiceNum)
            /// Specify the full Company Name that appears on the invoice. Required.
                .companyName(companyName: companyName)
            /// Specify a Purchase Order reference code for this invoice. Optional.
                .purchaseOrderReference(reference: referenceNumber)
            /// Add a new InvoiceItem to the invoice with fluent access for specifying the invoice item details. Required.
                .addItem(productCode: productCode, description: invoiceDescription, unitPrice: productUnitPrice)
                .addItem { (itemBuilder) -> InvoiceItemBuilder in
                    return itemBuilder
                    /// Specify the product or service code or SKU for the invoice item. Required.
                        .productCode(productCode)
                    /// Describe the product or service on the invoice item. Required.
                        .productDescription(productDescription)
                    /// Specify the SaleCode for the product or service on the invoice item.
                    /// Optional. The default value is "Sale" when not provided.
                        .saleCode(SaleCode.S)
                    /// Specify the unit price of the invoice item in the currency of the Transaction. Required.
                        .unitPrice(amountValue)
                    /// Specify the quantity sold of the invoice item. Optional. The default value is 1 when not provided.
                        .quantity(productQuantity)
                    /// Specify the UnitOfMeasure for the quantity of the invoice item.
                    /// Optional. The default value is UnitOfMeasure.Each when not provided.
                        .unitOfMeasureCode(.Each)
                    /// Calculates the totals on the invoice item by summarizing the invoice item totals. Optionally control whether
                    /// the net and gross totals should be calculated.
                    /// The net total will be a summary of the net totals of invoice items.
                        .calculateTotals()
                }
            /// Calculates the totals on the invoice by summarizing the invoice item totals. Optionally control whether
            /// the net, discount, tax and gross totals should be calculated.
            /// The net total will be a summary of the net totals of invoice items.
            /// The discount total will be a summary of the discount totals of invoice items.
            /// The tax total will be a summary of the tax totals of invoice items.
            /// The gross total will add together the net total and the tax total, subtracting the discount total and adding the tip amount.
                .calculateTotals()
            /// Builds the Invoice instance with the provided values.
                .build()
            
            /// **4: We create the transaction which contains the invoice**
            let txn = try self.pEngine!
                .buildTransaction(invoice: invoice)
            /// Specify that the transaction will be processed as a Sale. i.e. "Auth" and "Capture" will be performed. The "Amount" must be provided.
                .sale()
            /// Specify the total amount to be paid by the customer (or refunded to the customer) for the transaction. The
            /// amount should be in major units of the specified currency
                .amount(amountValue, currency: .USD)
            /// Specify the Reference code for the transaction. This should be a value that represents a unique order or
            /// invoice within the application. Optional. The default value is automatically generated when not specified.
                .reference(transactionRef)
            /// Specify the Date() that the transaction will be recorded against. This can be any
            /// valid value with any time zone, but the value in UTC time zone will be used. Optional. The default value
            /// is the current date/time in UTC when not specified.
                .dateTime(Date())
            /// Specify the Service that will process the transaction. The Service is usually a merchant account.
            /// Optional, but must be provided if the tenant has more than one service set up on Quantum Pay Cloud.
                .service(PaymentConfig.service)
            /// Specify the "Format" to be used for handling the encrypted transaction data. Do not override
            /// unless advised to do so by the Quantum Pay Customer Support.
            
            /// Attach a dictionary to the transaction. The keys of the dictionary will be presented on the receipt and
            /// can also be used to locate the transaction on the Quantum Pay Portal.
            /// Only one meta-data object can be associated with the transaction. Optional.
                .metaData(["orderNumber" : invoiceNum, "delivered" : "true"])
            /// Build the Transaction object
                .build()
            
            self.transaction = txn
            
            // Show store forward mode
            self.addText("Store & Forward: \(self.pEngine!.storeAndForwardMode)")
            
            /// **5. Start to process the specified transaction with provided values**
            try self.pEngine!.startTransaction(transaction: txn) { (result, tResponse) in
                self.addText("Transaction uploaded: \(result.isUploaded) - PAN: \(result.properties?.maskedPAN ?? "nil") - Ref: \(result.transactionReference)")
               
              // Convert result object to JSON, so that in react native code we can parse the object
              
              
              self.sendEvent(withName: PaymentConfig.transactionUploaded, body: result.transactionReference)
              
                guard let response = tResponse
                else {
                    return
                }
                
                if let errors = response.errors, errors.count > 0 {
                    for err in errors {
                        self.addText("Transaction Error: \(err.message ?? "")")
                      self.sendEvent(withName: PaymentConfig.errorTransaction, body: err.message)
                    }
                }
            }
        }
        catch {
          
          sendEvent(withName: PaymentConfig.errorEVM, body: error.localizedDescription)
            self.addText("EMV error: \(error.localizedDescription)")
          
        }
    }
   
    
    // Stop transaction
    @objc(onClickStopTransaction)
    func onClickStopTransaction(){
      
      do {
          try self.pEngine!.stopActiveTransaction()
        
        sendEvent(withName: PaymentConfig.transactionStop, body: PaymentConfig.transactionStop)

      }
      catch {
          self.addText("Stop transaction: \(error.localizedDescription)")
          sendEvent(withName: PaymentConfig.transactionStopError, body: error.localizedDescription)
      }
    }
    
    // we need to override this method and
      // return an array of event names that we can listen to
      override func supportedEvents() -> [String]! {
        return [PaymentConfig.onScanBarCode, PaymentConfig.onUpdateFirmWare, PaymentConfig.onDisconnectedWithBlueTooth, PaymentConfig.onConnectedWithBlueTooth, PaymentConfig.transactionState, PaymentConfig.transactionResult, PaymentConfig.transactionReciept, PaymentConfig.transactionUploaded, PaymentConfig.engineCreated, PaymentConfig.engineConnectedState, PaymentConfig.PeripheralState, PaymentConfig.PeripheralMessage, PaymentConfig.errorEVM, PaymentConfig.errorTransaction, PaymentConfig.transactionStop, PaymentConfig.transactionStopError, PaymentConfig.transactionList , PaymentConfig.transactionNotfound, PaymentConfig.transactionEmpty, PaymentConfig.transactionUploadingError, PaymentConfig.RFIDConnectionState,PaymentConfig.magneticCardData,PaymentConfig.magneticCardEncryptedData]
      }
    
    @objc(onClickCheckDatabaseTransactions)
    func onClickCheckDatabaseTransactions(){
      self.pEngine?.getStoredTransactions(onLoadedStoredTransactions: { results in
          if let results = results {
            
             // let resultString = "Stored transaction: \(results.count)"
              sendEvent(withName: PaymentConfig.transactionList, body:json(from:results))
      
              for result in results {
                  self.addText("Stored transaction: \(result.ID) - Ref: \(result.transactionReference)")
              }
          }
          else {
              sendEvent(withName: PaymentConfig.transactionNotfound, body:PaymentConfig.transactionNotfound)
              self.addText("No trannsaction found in DB!")
          }
      })
    }
    
    @objc(onClickUploadStoredTransaction)
    func onClickUploadStoredTransaction(){
      
      do {
          try self.pEngine?.uploadAllStoredTransactions(callback: { (transactionResults, errors) in
              self.addText("actionUploadStoredTransaction: \(transactionResults?.count ?? 0)")
              if let transactionResults = transactionResults, transactionResults.count > 0    {
                  for transaction in transactionResults {
                      self.addText("Uploaded: \(transaction.isUploaded) - Ref: \(transaction.transactionReference) - ID: \(transaction.ID)")
                    
                      self.sendEvent(withName: PaymentConfig.transactionUploaded, body:"Uploaded: \(transaction.isUploaded) - Ref: \(transaction.transactionReference) - ID: \(transaction.ID)")
                  }
              }
              else {
                  self.addText("No transactions to upload!")
                  self.sendEvent(withName: PaymentConfig.transactionEmpty, body:"No transactions to upload!")
              }
          })
      }
      catch {
          self.addText("Error uploading all transactions: \(error.localizedDescription)")
          self.sendEvent(withName: PaymentConfig.transactionUploadingError, body:"Error uploading all transactions: \(error.localizedDescription)")
      }
      
    }
    
    @objc(getAllStoredTransactions)
    func getAllStoredTransactions(){
      
      self.pEngine?.getStoredTransactions(onLoadedStoredTransactions: { transactionResults in
        
      })
      
    }
    
    @objc(onClickUpdateFirmware)
    func onClickUpdateFirmware(){
      
      if self.paymentDevice.device.connstate == CONN_STATES.CONNECTED.rawValue {
          // Get data
          guard let fwPath = Bundle.main.url(forResource: "PINPAD_AP_ARM_2.4.42.81.S1.02.00.00", withExtension: "bin") else {
              return
          }
          
          do {
              // Get firmware date
              let fwData = try Data(contentsOf: fwPath)
              
              // get device info
              // Make sure to check for device model, name, before doing update to ensure the firmware is pushed to the correct device
              let deviceInfo = try self.paymentDevice.device.getConnectedDeviceInfo(SUPPORTED_DEVICE_TYPES.DEVICE_TYPE_ALL)
              self.addText("Current firmware is: \(deviceInfo.firmwareRevision ?? "")")
              
              // get version of firmware data
              let fwFileInfo = try self.paymentDevice.device.getFirmwareFileInformation(fwData)
              let fwFileVersion = fwFileInfo["firmwareRevision"] as! String
              
              if deviceInfo.firmwareRevision != fwFileVersion {
                  self.addText("Updating firmware")
                  
                  // Before flashing, better to keep device from going to sleep
                  UIApplication.shared.isIdleTimerDisabled = true
                  
                  // Actual flashing
                  // Once it loaded 100% onto the device, the device will do the flash by itself
                  try self.paymentDevice.device.updateFirmwareData(fwData, validate: true)
              }
          }
          catch {
              self.addText("Update firmware error: \(error.localizedDescription)")
          }
      }

    }
    
    /// Delegate callbacks from IPCDTDevices
    func bluetoothLEDeviceConnected(_ device: CBPeripheral!) {
        if device.name!.contains(self.printerWPP250) {
            // Save
            self.connectedPrinter = device
            self.addText("Connected: \(device.name!)")
         
          // send event through emmiter, we can catch this event in react native code through add listner
          sendEvent(withName: PaymentConfig.onConnectedWithBlueTooth, body: device.identifier)
          
            // Print receipt after connected
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.printReceipt()
            }
        }
        
    }
    
    func bluetoothLEDeviceDisconnected(_ device: CBPeripheral!) {
        if device.name!.contains(self.printerWPP250) {
            self.addText("Disconnected: \(device.name!)")
          
          // send event through emmiter, we can catch this event in react native code through add listner
          sendEvent(withName: PaymentConfig.onDisconnectedWithBlueTooth, body: device.identifier)
          
            // Remove saved
            self.connectedPrinter = nil
        }
    }
    
    /// Barcode callback from scanners
    func barcodeData(_ barcode: String!, type: Int32) {
        // Handle barcodes
      sendEvent(withName: PaymentConfig.onScanBarCode, body: barcode ?? "")
      
        self.addText("Barcode: \(barcode ?? "")")
    }
    
    /// Firmware update progress callback
    func firmwareUpdateProgress(_ phase: Int32, percent: Int32) {
      
      sendEvent(withName: PaymentConfig.onUpdateFirmWare, body: percent)
        self.addText("FW Update Progress: \(percent)")
    }
  
}

