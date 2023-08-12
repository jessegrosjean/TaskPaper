//
//  OutlineEditorAppDelegate.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/4/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

//import AppReceiptValidator
import BirchOutline

#if DIRECT
    import Paddle
    import Sparkle
#endif

let BLastRunVersion = "BLastRunVersion"
let userDefaults = UserDefaults.standard

open class OutlineEditorAppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var newTab: NSMenuItem!
    @IBOutlet var styleSheetsMenu: NSMenu!
    @IBOutlet var pleaseRateMenuItem: NSMenuItem!
    @IBOutlet var recoverLicenseMenuItem: NSMenuItem!
    @IBOutlet var checkForUpdateMenuItem: NSMenuItem!

    var isAppStoreLicensed: Bool = false

    #if DIRECT
        var sparkleFeedURL: URL?
        var paddle: Paddle? {
            didSet {
                paddle?.delegate = self
            }
        }

        var paddleProduct: PADProduct?
        // var paddleProductID = ""
        // var paddleProductInfo = [String: String]()
    #endif

    open func applicationWillFinishLaunching(_: Notification) {
        BirchOutline.sharedContext = BirchScriptContext(scriptPath: Bundle(for: BirchEditor.self).path(forResource: "bircheditor", ofType: "js"))
        PreferencesWindowController.setupPreferencesStore()
    }

    public func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        true
    }
        
    open func applicationDidFinishLaunching(_: Notification) {
        appVersionSetup()
        ScriptCommands.initScriptCommands()
        ConfigurationOutlinesController.initConfigurationOutlines()

        styleSheetsSetup()
        checkForUpdatesSetup()
        licenseSetup()

        if #available(OSX 10.12, *) {
        } else {
            newTab.menu?.removeItem(newTab)
        }
    }

    func appVersionSetup() {
        let bundle = Bundle.main
        let bundleInfo = bundle.infoDictionary!
        let currentVersion = bundleInfo["CFBundleVersion"] as! String
        let lastRunVersion = userDefaults.string(forKey: BLastRunVersion)

        if currentVersion != lastRunVersion {
            LSRegisterURL(bundle.bundleURL as CFURL, true)
            userDefaults.set(currentVersion, forKey: BLastRunVersion)
        }
    }

    func checkForUpdatesSetup() {
        checkForUpdateMenuItem.isHidden = true
        #if DIRECT
            let sparkleUpdater = SUUpdater.shared()
            sparkleUpdater?.feedURL = sparkleFeedURL
            sparkleUpdater?.automaticallyChecksForUpdates = true
            checkForUpdateMenuItem.isHidden = false
            checkForUpdateMenuItem.action = #selector(SUUpdater.checkForUpdates)
            checkForUpdateMenuItem.target = sparkleUpdater
        #endif
    }
}

extension OutlineEditorAppDelegate {
    @IBAction func rateApplication(_: Any?) {
        NSWorkspace.shared.open(URL(string: "macappstore://userpub.itunes.apple.com/WebObjects/MZUserPublishing.woa/wa/addUserReview?id=1090940630")!)
    }

    @IBAction func showLicense(_: Any?) {
        let appName = ProcessInfo.processInfo.processName
        var informativeText: String?
        var paddleLicensed = false

        #if SETAPP
            informativeText = NSLocalizedString("\(appName) is licensed through setapp.com", tableName: "LicenseAlerts", comment: "setapp informative text")
        #endif

        #if DIRECT
            if let activated = paddleProduct?.activated, let licenseEmail = paddleProduct?.activationEmail, let licenseCode = paddleProduct?.licenseCode, activated == true {
                paddleLicensed = true
                informativeText = NSLocalizedString("\(appName) is licensed through Paddle.com to \(licenseEmail) with license code \(licenseCode)", tableName: "LicenseAlerts", comment: "paddle informative text")
            } else if !isAppStoreLicensed {
                paddle?.showLicenseActivationDialog(for: paddleProduct!, email: nil, licenseCode: nil)
                return
            }
        #endif

        if informativeText == nil {
            informativeText = NSLocalizedString("\(appName) is licensed through the Mac App Store.", tableName: "LicenseAlerts", comment: "appstore informative text")
        }

        let alert = NSAlert()
        alert.messageText = NSLocalizedString("\(appName) License", tableName: "LicenseAlerts", comment: "message text")
        alert.informativeText = informativeText ?? ""
        alert.addButton(withTitle: NSLocalizedString("OK", tableName: "LicenseAlerts", comment: "button"))

        #if DIRECT
            if paddleLicensed {
                alert.addButton(withTitle: NSLocalizedString("Deactivate", tableName: "LicenseAlerts", comment: "button"))
            }

            if alert.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn {
                deactivatePaddleLicense(nil)
            }
        #else
            alert.runModal()
        #endif
    }

    @IBAction func showPreferences(_: Any?) {
        PreferencesWindowController.showPreferences()
    }
}

extension OutlineEditorAppDelegate {
    func styleSheetsSetup() {
        if StyleSheet.styleSheetsURLs.count == 0 {
            let fileManager = FileManager.default

            if let url = try? fileManager.URLForApplicationsStyleSheetsDirectory(inDomain: .userDomainMask, appropriateForURL: nil, create: true) {
                if let lightURL = Bundle.main.url(forResource: "Default", withExtension: "less") {
                    _ = try? fileManager.copyItem(at: lightURL, to: url.appendingPathComponent("Default.less"))
                }
            }
        }
    }

    @IBAction func updateStyleSheetAction(_ sender: Any?) {
        if let styleSheetURL = (sender as? NSMenuItem)?.representedObject as? URL, let windowController = NSApp.mainWindow?.windowController as? OutlineEditorWindowController {
            let styleSheet = BirchEditor.createStyleSheet(styleSheetURL as URL)
            windowController.styleSheet = styleSheet
            StyleSheet.makeDefault(styleSheet)
        }
    }

    @IBAction func openStyleSheetsFolder(_: Any?) {
        if let url = try? FileManager.default.URLForApplicationsStyleSheetsDirectory(inDomain: .userDomainMask, appropriateForURL: nil, create: true) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(OutlineEditorAppDelegate.updateStyleSheetAction(_:)) {
            if let windowController = NSApp.mainWindow?.windowController as? OutlineEditorWindowController {
                if windowController.styleSheet?.source == (menuItem.representedObject as? URL) {
                    menuItem.state = .on
                }
                return true
            } else {
                return false
            }
        }
        return true
    }
}

extension OutlineEditorAppDelegate: NSMenuDelegate {
    public func menuNeedsUpdate(_ menu: NSMenu) {
        if menu == styleSheetsMenu {
            menu.removeAllItems()

            let styleSheetURLs = StyleSheet.styleSheetsURLs
            if styleSheetURLs.count > 0 {
                for each in styleSheetURLs {
                    let path = each.path
                    let item = NSMenuItem(title: path.lastPathComponent, action: #selector(OutlineEditorAppDelegate.updateStyleSheetAction(_:)), keyEquivalent: "")
                    item.representedObject = each
                    menu.addItem(item)
                }
                menu.addItem(NSMenuItem.separator())
            }

            let title = NSLocalizedString("Open StyleSheet Folder", tableName: "StyleSheet", comment: "menu")
            menu.addItem(withTitle: title, action: #selector(OutlineEditorAppDelegate.openStyleSheetsFolder(_:)), keyEquivalent: "")
        }
    }
}

extension OutlineEditorAppDelegate {
    func licenseSetup() {
        #if WRITEROOM
            // Hack since don't have writeroom keys yet
            return
        #else
            #if SETAPP
                pleaseRateMenuItem.isHidden = true
                recoverLicenseMenuItem.isHidden = true
                return
            #else
                let fileManager = FileManager.default
                let applicationSupportDirectory = try! fileManager.URLForApplicationsSupportDirectory(inDomain: .userDomainMask, appropriateForURL: nil, create: true)
                let receiptsFolder = applicationSupportDirectory.appendingPathComponent("Receipts")
                let macAddress = GetMACAddress() ?? "receipt"

                _ = try? fileManager.createDirectory(atPath: receiptsFolder.path, withIntermediateDirectories: true, attributes: nil)
                let receiptDestinationURL = receiptsFolder.appendingPathComponent(macAddress)

                #if DIRECT
                    let appName = ProcessInfo.processInfo.processName
                    let appBundleID = Bundle.main.bundleIdentifier!

                    assert(appBundleID.hasSuffix(".direct"))

                    let appStoreBundleID = appBundleID.firstStringMatch("(.*)\\.direct$")!
                    let appStoreReceiptPath = "~/Library/Containers/\(appStoreBundleID)/Data/Library/Application Support/\(appName)/Receipts/\(macAddress)"
                    let appStoreReceiptURL = URL(fileURLWithPath: NSString(string: appStoreReceiptPath).expandingTildeInPath)

                    if fileManager.fileExists(atPath: appStoreReceiptURL.path) {
                        if fileManager.fileExists(atPath: receiptDestinationURL.path) {
                            _ = try? fileManager.removeItem(at: receiptDestinationURL)
                        }
                        _ = try? fileManager.copyItem(at: appStoreReceiptURL, to: receiptDestinationURL)
                    }

                    var appStoreValidated = false

                    if let _ = try? Data(contentsOf: receiptDestinationURL) {
                        //todo!!!
                        //let receiptValidator = AppReceiptValidator()
                        //let parameters = AppReceiptValidator.Parameters.default.with {
                        //    $0.receiptOrigin = .data(receiptData)
                        //    $0.propertyValidations = [
                        //        .string(\.bundleIdentifier, expected: appStoreBundleID),
                        //        .string(\.originalAppVersion, expected: "3.0"),
                        //    ]
                        //}
                        //let result = receiptValidator.validateReceipt(parameters: parameters)
                        //switch result {
                        //case .success:
                        //    appStoreValidated = true
                        //case .error:
                        //    appStoreValidated = false
                        //}
                        appStoreValidated = true
                    }

                    if appStoreValidated {
                        isAppStoreLicensed = true
                    } else {
                        pleaseRateMenuItem.isHidden = true
                    }

                    let paddle = self.paddle!
                    let paddleProduct = self.paddleProduct!

                    if !paddleProduct.activated && !isAppStoreLicensed {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            paddle.showProductAccessDialog(with: paddleProduct)
                        }
                    }

                #else

                    checkForUpdateMenuItem.isHidden = true
                    recoverLicenseMenuItem.isHidden = true

                    if let receiptSourceURL = Bundle.main.appStoreReceiptURL, fileManager.fileExists(atPath: receiptSourceURL.path) {
                        if fileManager.fileExists(atPath: receiptDestinationURL.path) {
                            _ = try? fileManager.removeItem(at: receiptDestinationURL)
                        }
                        _ = try? fileManager.copyItem(at: receiptSourceURL, to: receiptDestinationURL)
                    }

                    //todo!!!
                    //let receiptValidator = AppReceiptValidator()
                    //let result = receiptValidator.validateReceipt()
                    //switch result {
                    //case .success:
                    //    break
                    //case .error:
                    //    exit(173)
                    //}
                #endif
            #endif
        #endif
    }

    @IBAction func recoverPaddleLicense(_: Any?) {
        #if DIRECT
            paddle!.showLicenseRecovery(for: paddleProduct!, completion: nil)
        #endif
    }

    @IBAction func deactivatePaddleLicense(_: Any?) {
        #if DIRECT
            let appName = ProcessInfo.processInfo.processName
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Deactivate License?", tableName: "LicenseAlerts", comment: "message text")
            alert.informativeText = NSLocalizedString("Deactivating this \(appName) license will remove it from this computer and make it available for use on another computer.", tableName: "LicenseAlerts", comment: "infromative text")
            _ = alert.addButton(withTitle: NSLocalizedString("OK", tableName: "LicenseAlerts", comment: "button"))
            _ = alert.addButton(withTitle: NSLocalizedString("Cancel", tableName: "LicenseAlerts", comment: "button"))
            if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
                paddleProduct?.deactivate(completion: { success, error in
                    if !success, let error = error {
                        NSApp.presentError(error)
                    }
                })
            }
        #endif
    }

    @IBAction func emailJesse(_: Any?) {
        NSWorkspace.shared.open(URL(string: "mailto:jesse@hogbaysoftware.com")!)
    }
}

#if DIRECT
    extension OutlineEditorAppDelegate: PaddleDelegate {
        /* public func willShowPaddle(_ uiType: PADUIType, product: PADProduct) -> PADDisplayConfiguration? {
             return nil
         }

         public func didDismissPaddle(_ uiType: PADUIType, triggeredUIType: PADTriggeredUIType, product: PADProduct) {
         }

         public func willShowPaddle(_ alert: PADAlert) -> Bool {
             return true
         } */

        public func paddleDidError(_: Error) {
            // Swift.print(error)
        }
    }
#endif
