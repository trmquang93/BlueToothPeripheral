//
//  ViewController.swift
//  BluetoothPeripheral
//
//  Created by Quang Tran on 30/03/2022.
//

import DeclarativeUI
import RxCocoa
import RxSwift
import CoreBluetooth

extension UIViewController {
    struct CBData {
        var service: Service
        var characteristic: CBMutableCharacteristic
        var value: Float?
    }
}

class ViewController: UIViewController {
    weak var tableView: UITableView!
    var connectingCentral: CBCentral?
    var peripheralManager: CBPeripheralManager!
    let peripheralID = BehaviorRelay<String>(value: "")
    let data = BehaviorRelay<[CBData]>(value: [])
    
    init() {
        super.init(nibName: nil, bundle: nil)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViews()
        setupTableView()
        initData()
    }
    
    func initData() {
        let data = Service.allCases
            .filter({$0 != .identifier})
            .map({CBData(service: $0, characteristic: CBMutableCharacteristic(type: CBUUID(string: $0.serviceType), properties: [.read, .notify], value: nil, permissions: [.readable, .writeable]))})
        
        self.data.accept(data)
        
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
    }
}

extension ViewController {
    func setupPeripheral() {
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: "08590F7E-DB05-467E-8757-72F6FAEB13D4")],
            "kCBAdvDataLocalName": "Test"
        ])
    }
    
    func addServices() {
        let service = CBMutableService(type: CBUUID(string: "08590F7E-DB05-467E-8757-72F6FAEB13D4"), primary: true)
        service.characteristics = self.data.value.map({$0.characteristic})
        
        peripheralManager.add(service)
    }
}

extension ViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            print("state unknown")
        case .resetting:
            print("state resetting")
        case .unsupported:
            print("state unsupported")
        case .unauthorized:
            print("state unauthorized")
        case .poweredOff:
            print("state poweredOff")
        case .poweredOn:
            print("state poweredOn")
            setupPeripheral()
        @unknown default:
            print("state default")
        }
        
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        addServices()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("did add service \(service)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        self.connectingCentral = central
        
        for data in self.data.value {
            if data.characteristic == characteristic {
                if peripheral.updateValue(Data(from: data.value), for: data.characteristic, onSubscribedCentrals: nil) {
                    // It did, so mark it as sent
                    print("Sent: \(data.service.name) value")
                }
            }
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print(#function)
    }
}


extension ViewController {
    func sendData() {
        
    }
}
extension ViewController {
    func createViews() {
        view.body {
            tableView <~ UITableView()
        }
    }
    
    func setupTableView() {
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Service.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TableViewCell
        let service = Service(rawValue: indexPath.row)
        cell.titleLabel.text = service?.name
        cell.textField.placeholder = service?.name
        cell.textField.isEnabled = service != .identifier
        
        cell.textField.rx.text
            .orEmpty
            .compactMap({Float($0)})
            .subscribe(onNext: { [weak self] text in
                guard let self = self else { return }
                if let data = self.data.value.first(where: {$0.service == service}) {
                    self.peripheralManager.updateValue(Data(from: text), for: data.characteristic, onSubscribedCentrals: nil)
                }
            }).disposed(by: cell.disposeBag)
        
        return cell
    }
}


enum Service: Int, CaseIterable {
    case identifier
    case battery
    case charging
    case thermometer
    case pulseoximeter
    case co2
    case control
    case calibration
    case heartrate
    
    var name: String {
        return "\(self)"
    }
    
    var serviceType: String {
        switch self {
        case .identifier:
            return ""
        case .battery:
            return "180F"
        case .charging:
            return "2e782c66-9935-11ec-b909-0242ac120002"
        case .thermometer:
            return "1809"
        case .pulseoximeter:
            return "1822"
        case .co2:
            return "a06c49ab-e205-a5b9-0f45-789d8c63a5d3"
        case .control:
            return "39a76c84-94a1-11ec-b909-0242ac120002"
        case .calibration:
            return "f5c13aec-9610-11ec-b909-0242ac120002"
        case .heartrate:
            return "180D"
        }
    }
}


class TableViewCell: UITableViewCell {
    weak var titleLabel: UILabel!
    weak var textField: UITextField!
    
    var disposeBag = DisposeBag()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.body {
            Stack(axis: .vertical) {
                titleLabel <~ UILabel().with
                    .height(30)
                
                textField <~ UITextField().with
                    .borderStyle(.roundedRect)
                    .borderWidth(1)
                    .borderColor(UIColor.gray.cgColor)
                    .height(30)
            }.with
                .alignment(.fill)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
    }
}


extension Data {
    
    init<T>(from value: T) {
        self = Swift.withUnsafeBytes(of: value) { Data($0) }
    }
    
    func to<T>(type: T.Type) -> T? where T: ExpressibleByIntegerLiteral {
        var value: T = 0
        guard count >= MemoryLayout.size(ofValue: value) else { return nil }
        _ = Swift.withUnsafeMutableBytes(of: &value, { copyBytes(to: $0)} )
        return value
    }
}
