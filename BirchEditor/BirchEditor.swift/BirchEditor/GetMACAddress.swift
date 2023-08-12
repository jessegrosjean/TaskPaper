//
//  macaddress.swift
//  Birch
//
//  Created by Jesse Grosjean on 8/31/16.
//
//

import Foundation

// Returns an iterator containing the primary (built-in) Ethernet interface. The caller is responsible for
// releasing the iterator after the caller is done with it.
func FindEthernetInterfaces() -> io_iterator_t? {
    let matchingDict = IOServiceMatching("IOEthernetInterface") as NSMutableDictionary
    matchingDict["IOPropertyMatch"] = ["IOPrimaryInterface": true]

    var matchingServices: io_iterator_t = 0
    if IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &matchingServices) != KERN_SUCCESS {
        return nil
    }

    return matchingServices
}

// Given an iterator across a set of Ethernet interfaces, return the MAC address of the last one.
// If no interfaces are found the MAC address is set to an empty string.
// In this sample the iterator should contain just the primary interface.
func GetMACAddress(intfIterator: io_iterator_t) -> [UInt8]? {
    var macAddress: [UInt8]?

    var intfService = IOIteratorNext(intfIterator)
    while intfService != 0 {
        var controllerService: io_object_t = 0
        if IORegistryEntryGetParentEntry(intfService, "IOService", &controllerService) == KERN_SUCCESS {
            let dataUM = IORegistryEntryCreateCFProperty(controllerService, "IOMACAddress" as CFString, kCFAllocatorDefault, 0)
            if let data = dataUM?.takeRetainedValue() as? NSData {
                macAddress = [0, 0, 0, 0, 0, 0]
                data.getBytes(&macAddress!, length: macAddress!.count)
            }
            IOObjectRelease(controllerService)
        }

        IOObjectRelease(intfService)
        intfService = IOIteratorNext(intfIterator)
    }

    return macAddress
}

func GetMACAddress() -> String? {
    var macAddressAsString: String?
    if let intfIterator = FindEthernetInterfaces() {
        if let macAddress = GetMACAddress(intfIterator: intfIterator) {
            macAddressAsString = macAddress.map { String(format: "%02x", $0) }.joined(separator: ":")
        }
        IOObjectRelease(intfIterator)
    }
    return macAddressAsString
}
