import Foundation
import Network

protocol NetworkMonitoring: Sendable {
    var isConnected: Bool { get }
}

final class NetworkMonitor: NetworkMonitoring, @unchecked Sendable {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.lifteats.network-monitor")
    private let lock = NSLock()
    private var _isConnected = false

    var isConnected: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isConnected
    }

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.setIsConnected(path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    private func setIsConnected(_ value: Bool) {
        lock.lock()
        _isConnected = value
        lock.unlock()
    }
}
