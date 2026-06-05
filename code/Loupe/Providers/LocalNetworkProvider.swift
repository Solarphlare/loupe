//
//  LocalNetworkProvider.swift
//  Loupe
//
//  Runs a short Bonjour browse across common service types. Reports the
//  count of discovered services per type without revealing their names.
//

import Foundation
import Network

@MainActor
struct LocalNetworkProvider: SignalProvider {
    let category: SignalCategory = .localNetwork
    let center: PermissionCenter

    private static let serviceTypes: [(String, String)] = [
        // Apple ecosystem
        ("_airplay._tcp", "AirPlay receivers"),
        ("_raop._tcp", "AirPlay audio (RAOP)"),
        ("_companion-link._tcp", "Companion link (Apple)"),
        ("_homekit._tcp", "HomeKit accessories"),
        ("_airdrop._tcp", "AirDrop"),
        ("_apple-mobdev2._tcp", "Apple Mobile Device"),
        ("_remotepairing._tcp", "Remote Pairing (Apple)"),

        // Streaming & media
        ("_googlecast._tcp", "Google Cast"),
        ("_spotify-connect._tcp", "Spotify Connect"),
        ("_sonos._tcp", "Sonos speakers"),
        ("_roku-rcp._tcp", "Roku devices"),
        ("_daap._tcp", "DAAP (iTunes sharing)"),
        ("_dpap._tcp", "DPAP (photo sharing)"),

        // Printers & scanners
        ("_printer._tcp", "Printers"),
        ("_ipp._tcp", "IPP printers"),
        ("_ipps._tcp", "IPP Secure printers"),
        ("_pdl-datastream._tcp", "PDL Data Stream printers"),
        ("_scanner._tcp", "Scanners"),
        ("_uscan._tcp", "USB scanners (eSCL)"),

        // Web & file sharing
        ("_http._tcp", "Web servers"),
        ("_https._tcp", "Secure web servers"),
        ("_smb._tcp", "SMB file sharing"),
        ("_afpovertcp._tcp", "AFP file sharing"),
        ("_nfs._tcp", "NFS file sharing"),
        ("_ftp._tcp", "FTP servers"),
        ("_sftp-ssh._tcp", "SFTP/SSH servers"),
        ("_webdav._tcp", "WebDAV servers"),
        ("_webdavs._tcp", "Secure WebDAV servers"),

        // Remote access & management
        ("_ssh._tcp", "SSH servers"),
        ("_rfb._tcp", "VNC (screen sharing)"),
        ("_rdp._tcp", "Remote Desktop (RDP)"),
        ("_net-assistant._udp", "Apple Remote Desktop"),

        // Smart home & IoT
        ("_hap._tcp", "HAP (HomeKit protocol)"),
        ("_matter._tcp", "Matter smart home"),
        ("_hue._tcp", "Philips Hue bridges"),
        ("_mqtt._tcp", "MQTT brokers"),
        ("_coap._udp", "CoAP (IoT)"),
        ("_wemo._tcp", "Wemo devices"),

        // Communication
        ("_presence._tcp", "Chat/presence (XMPP)"),
        ("_sip._tcp", "SIP (VoIP)"),
        ("_h323._tcp", "H.323 (video conferencing)"),

        // Development & diagnostics
        ("_device-info._tcp", "Device info"),
        ("_sleep-proxy._udp", "Sleep Proxy (Bonjour)"),
        ("_dns-sd._udp", "DNS Service Discovery"),
    ]

    func collect() async -> [FingerprintSignal] {
        var signals: [FingerprintSignal] = []
        await withTaskGroup(of: (String, String, [String]).self) { group in
            for (type, label) in Self.serviceTypes {
                group.addTask {
                    let names = await LocalNetworkProvider.scan(type: type, duration: 1.2)
                    return (type, label, names)
                }
            }
            for await (type, label, names) in group {
                if !names.isEmpty {
                    let value = names.joined(separator: ", ")
                    signals.append(
                        .make(
                            "svc.\(type)",
                            category: category,
                            name: label,
                            value: value,
                            rationale: ""))
                }
            }
        }
        signals.sort { $0.id < $1.id }
        return signals
    }

    nonisolated private static func scan(type: String, duration: TimeInterval) async -> [String] {
        let state = BonjourScanState()
        return await withCheckedContinuation { (continuation: CheckedContinuation<[String], Never>) in
            let params = NWParameters()
            params.includePeerToPeer = true
            let browser = NWBrowser(for: .bonjour(type: type, domain: nil), using: params)
            let queue = DispatchQueue(label: "Loupe.LocalNetworkProvider.\(type)")
            browser.browseResultsChangedHandler = { results, _ in
                let names: [String] = results.compactMap { result in
                    if case .service(let name, _, _, _) = result.endpoint {
                        return name
                    }
                    return nil
                }
                state.lock.lock()
                state.names = names
                state.lock.unlock()
            }
            browser.start(queue: queue)
            queue.asyncAfter(deadline: .now() + duration) {
                state.lock.lock()
                defer { state.lock.unlock() }
                if !state.resolved {
                    state.resolved = true
                    browser.cancel()
                    let sorted = state.names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
                    continuation.resume(returning: sorted)
                }
            }
        }
    }
}

/// NWBrowser callbacks and timeout run on the browse queue; the lock guards
/// the shared name list and single completion flag.
nonisolated private final class BonjourScanState: @unchecked Sendable {
    let lock = NSLock()
    var resolved = false
    var names: [String] = []
}
