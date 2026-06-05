//
//  DeviceModelNames.swift
//  Loupe
//
//  Maps the model identifier to the marketing name a non-technical user
//  recognises. On iOS this comes from `hw.machine` (e.g., "iPhone16,1");
//  on macOS from `hw.model` (e.g., "MacBookPro18,2"). Unknown identifiers
//  fall back to the raw string so the summary card still renders
//  something truthful.
//

import Foundation

nonisolated enum DeviceModelNames {
    /// Returns the marketing name for a model identifier, or the
    /// identifier itself if no mapping is known.
    static func marketingName(for identifier: String) -> String? {
        if let direct = table[identifier] { return direct }
        return nil
    }

    private static let table: [String: String] = [
        // MARK: - iPhone

        "iPhone8,1": "iPhone 6s",
        "iPhone8,2": "iPhone 6s Plus",
        "iPhone8,4": "iPhone SE (1st generation)",
        "iPhone9,1": "iPhone 7",
        "iPhone9,2": "iPhone 7 Plus",
        "iPhone9,3": "iPhone 7",
        "iPhone9,4": "iPhone 7 Plus",
        "iPhone10,1": "iPhone 8",
        "iPhone10,2": "iPhone 8 Plus",
        "iPhone10,3": "iPhone X",
        "iPhone10,4": "iPhone 8",
        "iPhone10,5": "iPhone 8 Plus",
        "iPhone10,6": "iPhone X",
        "iPhone11,2": "iPhone XS",
        "iPhone11,4": "iPhone XS Max",
        "iPhone11,6": "iPhone XS Max",
        "iPhone11,8": "iPhone XR",
        "iPhone12,1": "iPhone 11",
        "iPhone12,3": "iPhone 11 Pro",
        "iPhone12,5": "iPhone 11 Pro Max",
        "iPhone12,8": "iPhone SE (2nd generation)",
        "iPhone13,1": "iPhone 12 mini",
        "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro",
        "iPhone13,4": "iPhone 12 Pro Max",
        "iPhone14,2": "iPhone 13 Pro",
        "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,4": "iPhone 13 mini",
        "iPhone14,5": "iPhone 13",
        "iPhone14,6": "iPhone SE (3rd generation)",
        "iPhone14,7": "iPhone 14",
        "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro",
        "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone15,4": "iPhone 15",
        "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone17,1": "iPhone 16 Pro",
        "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,3": "iPhone 16",
        "iPhone17,4": "iPhone 16 Plus",
        "iPhone17,5": "iPhone 16e",
        "iPhone18,1": "iPhone 17 Pro",
        "iPhone18,2": "iPhone 17 Pro Max",
        "iPhone18,3": "iPhone 17",
        "iPhone18,4": "iPhone Air",

        // MARK: - iPad

        "iPad6,11": "iPad (5th generation)",
        "iPad6,12": "iPad (5th generation)",
        "iPad7,5": "iPad (6th generation)",
        "iPad7,6": "iPad (6th generation)",
        "iPad7,11": "iPad (7th generation)",
        "iPad7,12": "iPad (7th generation)",
        "iPad11,6": "iPad (8th generation)",
        "iPad11,7": "iPad (8th generation)",
        "iPad12,1": "iPad (9th generation)",
        "iPad12,2": "iPad (9th generation)",
        "iPad13,18": "iPad (10th generation)",
        "iPad13,19": "iPad (10th generation)",
        "iPad15,7": "iPad (11th generation)",
        "iPad15,8": "iPad (11th generation)",
        "iPad11,3": "iPad Air (3rd generation)",
        "iPad11,4": "iPad Air (3rd generation)",
        "iPad13,1": "iPad Air (4th generation)",
        "iPad13,2": "iPad Air (4th generation)",
        "iPad13,16": "iPad Air (5th generation)",
        "iPad13,17": "iPad Air (5th generation)",
        "iPad14,8": "iPad Air 11-inch (M2)",
        "iPad14,9": "iPad Air 11-inch (M2)",
        "iPad14,10": "iPad Air 13-inch (M2)",
        "iPad14,11": "iPad Air 13-inch (M2)",
        "iPad15,3": "iPad Air 11-inch (M3)",
        "iPad15,4": "iPad Air 11-inch (M3)",
        "iPad15,5": "iPad Air 13-inch (M3)",
        "iPad15,6": "iPad Air 13-inch (M3)",
        "iPad11,1": "iPad mini (5th generation)",
        "iPad11,2": "iPad mini (5th generation)",
        "iPad14,1": "iPad mini (6th generation)",
        "iPad14,2": "iPad mini (6th generation)",
        "iPad16,1": "iPad mini (7th generation)",
        "iPad16,2": "iPad mini (7th generation)",
        "iPad8,1": "iPad Pro 11-inch",
        "iPad8,2": "iPad Pro 11-inch",
        "iPad8,3": "iPad Pro 11-inch",
        "iPad8,4": "iPad Pro 11-inch",
        "iPad8,5": "iPad Pro 12.9-inch (3rd generation)",
        "iPad8,6": "iPad Pro 12.9-inch (3rd generation)",
        "iPad8,7": "iPad Pro 12.9-inch (3rd generation)",
        "iPad8,8": "iPad Pro 12.9-inch (3rd generation)",
        "iPad8,9": "iPad Pro 11-inch (2nd generation)",
        "iPad8,10": "iPad Pro 11-inch (2nd generation)",
        "iPad8,11": "iPad Pro 12.9-inch (4th generation)",
        "iPad8,12": "iPad Pro 12.9-inch (4th generation)",
        "iPad13,4": "iPad Pro 11-inch (3rd generation)",
        "iPad13,5": "iPad Pro 11-inch (3rd generation)",
        "iPad13,6": "iPad Pro 11-inch (3rd generation)",
        "iPad13,7": "iPad Pro 11-inch (3rd generation)",
        "iPad13,8": "iPad Pro 12.9-inch (5th generation)",
        "iPad13,9": "iPad Pro 12.9-inch (5th generation)",
        "iPad13,10": "iPad Pro 12.9-inch (5th generation)",
        "iPad13,11": "iPad Pro 12.9-inch (5th generation)",
        "iPad14,3": "iPad Pro 11-inch (4th generation)",
        "iPad14,4": "iPad Pro 11-inch (4th generation)",
        "iPad14,5": "iPad Pro 12.9-inch (6th generation)",
        "iPad14,6": "iPad Pro 12.9-inch (6th generation)",
        "iPad16,3": "iPad Pro 11-inch (M4)",
        "iPad16,4": "iPad Pro 11-inch (M4)",
        "iPad16,5": "iPad Pro 13-inch (M4)",
        "iPad16,6": "iPad Pro 13-inch (M4)",
        "iPad17,1": "iPad Pro 11-inch (M5)",
        "iPad17,2": "iPad Pro 11-inch (M5)",
        "iPad17,3": "iPad Pro 13-inch (M5)",
        "iPad17,4": "iPad Pro 13-inch (M5)",

        // MARK: - iPod touch

        "iPod9,1": "iPod touch (7th generation)",

        // MARK: - MacBook Pro

        "MacBookPro15,1": "MacBook Pro (15-inch, 2018)",
        "MacBookPro15,2": "MacBook Pro (13-inch, 2018/2019)",
        "MacBookPro15,3": "MacBook Pro (15-inch, 2019)",
        "MacBookPro15,4": "MacBook Pro (13-inch, 2019)",
        "MacBookPro16,1": "MacBook Pro (16-inch, 2019)",
        "MacBookPro16,2": "MacBook Pro (13-inch, 2020, Four TB3)",
        "MacBookPro16,3": "MacBook Pro (13-inch, 2020, Two TB3)",
        "MacBookPro16,4": "MacBook Pro (16-inch, 2019)",
        "MacBookPro17,1": "MacBook Pro (13-inch, M1, 2020)",
        "MacBookPro18,1": "MacBook Pro (16-inch, 2021)",
        "MacBookPro18,2": "MacBook Pro (16-inch, 2021)",
        "MacBookPro18,3": "MacBook Pro (14-inch, 2021)",
        "MacBookPro18,4": "MacBook Pro (14-inch, 2021)",
        "Mac14,5": "MacBook Pro (14-inch, 2023)",
        "Mac14,6": "MacBook Pro (16-inch, 2023)",
        "Mac14,7": "MacBook Pro (13-inch, M2, 2022)",
        "Mac14,9": "MacBook Pro (14-inch, 2023)",
        "Mac14,10": "MacBook Pro (16-inch, 2023)",
        "Mac15,3": "MacBook Pro (14-inch, M3, Nov 2023)",
        "Mac15,6": "MacBook Pro (14-inch, M3 Pro, Nov 2023)",
        "Mac15,7": "MacBook Pro (16-inch, M3 Pro, Nov 2023)",
        "Mac15,8": "MacBook Pro (14-inch, M3 Pro, Nov 2023)",
        "Mac15,9": "MacBook Pro (16-inch, M3 Max, Nov 2023)",
        "Mac15,10": "MacBook Pro (14-inch, M3 Max, Nov 2023)",
        "Mac15,11": "MacBook Pro (16-inch, M3 Max, Nov 2023)",
        "Mac16,1": "MacBook Pro (14-inch, M4, 2024)",
        "Mac16,5": "MacBook Pro (16-inch, M4 Max, 2024)",
        "Mac16,6": "MacBook Pro (14-inch, M4 Pro, 2024)",
        "Mac16,7": "MacBook Pro (16-inch, M4 Pro, 2024)",
        "Mac16,8": "MacBook Pro (14-inch, M4 Max, 2024)",
        "Mac17,2": "MacBook Pro (14-inch, M5, 2025)",
        "Mac17,6": "MacBook Pro (16-inch, M5 Pro/Max, 2026)",
        "Mac17,7": "MacBook Pro (14-inch, M5 Pro/Max, 2026)",
        "Mac17,8": "MacBook Pro (16-inch, M5 Pro/Max, 2026)",
        "Mac17,9": "MacBook Pro (14-inch, M5 Pro/Max, 2026)",

        // MARK: - MacBook Air

        "MacBookAir8,1": "MacBook Air (Retina, 13-inch, 2018)",
        "MacBookAir8,2": "MacBook Air (Retina, 13-inch, 2019)",
        "MacBookAir9,1": "MacBook Air (Retina, 13-inch, 2020)",
        "MacBookAir10,1": "MacBook Air (M1, 2020)",
        "Mac14,2": "MacBook Air (M2, 2022)",
        "Mac14,15": "MacBook Air (15-inch, M2, 2023)",
        "Mac15,12": "MacBook Air (13-inch, M3, 2024)",
        "Mac15,13": "MacBook Air (15-inch, M3, 2024)",
        "Mac16,12": "MacBook Air (13-inch, M4, 2025)",
        "Mac16,13": "MacBook Air (15-inch, M4, 2025)",
        "Mac17,3": "MacBook Air (13-inch, M5, 2026)",
        "Mac17,4": "MacBook Air (15-inch, M5, 2026)",

        // MARK: - iMac

        "iMac21,1": "iMac (24-inch, M1, 2021)",
        "iMac21,2": "iMac (24-inch, M1, 2021)",
        "Mac15,4": "iMac (24-inch, 2023, Two ports)",
        "Mac15,5": "iMac (24-inch, 2023, Four ports)",
        "Mac16,2": "iMac (24-inch, 2024, Two ports)",
        "Mac16,3": "iMac (24-inch, 2024, Four ports)",

        // MARK: - Mac mini

        "Macmini8,1": "Mac mini (2018)",
        "Macmini9,1": "Mac mini (M1, 2020)",
        "Mac14,3": "Mac mini (M2, 2023)",
        "Mac14,12": "Mac mini (M2 Pro, 2023)",
        "Mac16,10": "Mac mini (M4, 2024)",
        "Mac16,11": "Mac mini (M4 Pro, 2024)",

        // MARK: - Mac Studio

        "Mac13,1": "Mac Studio (M1 Max, 2022)",
        "Mac13,2": "Mac Studio (M1 Ultra, 2022)",
        "Mac14,13": "Mac Studio (M2 Max, 2023)",
        "Mac14,14": "Mac Studio (M2 Ultra, 2023)",
        "Mac15,14": "Mac Studio (M3 Ultra, 2025)",
        "Mac16,9": "Mac Studio (M4 Max, 2025)",

        // MARK: - Mac Pro

        "MacPro7,1": "Mac Pro (2019)",
        "Mac14,8": "Mac Pro (M2 Ultra, 2023)",
    ]
}
