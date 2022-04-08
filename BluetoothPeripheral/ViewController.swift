//
//  ViewController.swift
//  BluetoothPeripheral
//
//  Created by Quang Tran on 30/03/2022.
//

import DeclarativeUI
import RxCocoa
import RxSwift
import MedicalBandSDK
import CoreBluetooth


class ViewController: UIViewController {
    weak var tableView: UITableView!
//    var connectingCentral: CBCentral?
    var peripheralManager: CBPeripheralManager!
    let peripheralID = BehaviorRelay<String>(value: "")
    
    let charateristics = CharateristicType.allCases
        .map { type -> CBCharacteristic in
            let characteristic = CBMutableCharacteristic(type: type.uuid, properties: type.properties, value: nil, permissions: [.readable])
            
            return characteristic
        }
    
    let data = BehaviorRelay<[CharateristicType: Data]>(value: [:])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViews()
        setupTableView()
        bluetoothSetup()
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TableViewCell
        let item = CharateristicType(rawValue: indexPath.row)
        cell.label.text = item?.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CharateristicType.allCases.count
    }
}

extension ViewController: UITableViewDelegate {
    
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
//        self.connectingCentral = central
        guard let type = CharateristicType.allCases.first(where: {$0.uuid == characteristic.uuid}),
              let characteristic = characteristic as? CBMutableCharacteristic
        else { return }
        let data = self.data.value[type] ?? Data()
        print("central.maximumUpdateValueLength \(central.maximumUpdateValueLength)----------")
        if peripheral.updateValue(data, for: characteristic, onSubscribedCentrals: [central]) {
            // It did, so mark it as sent
            print("Sent: \(type.name) value")
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print(#function)
    }
}

extension ViewController {
    
    func addServices() {
        let service = CBMutableService(type: CBUUID(string: "08590F7E-DB05-467E-8757-72F6FAEB13D4"), primary: true)
        service.characteristics = charateristics
        
        peripheralManager.add(service)
    }
    
    func setupPeripheral() {
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: "08590F7E-DB05-467E-8757-72F6FAEB13D4")],
            "kCBAdvDataLocalName": "Test"
        ])
    }
    
    func bluetoothSetup() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
    }
    func setupTableView() {
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    func createViews() {
        view.body {
            tableView <~ UITableView().with
                .delegate(self)
                .dataSource(self)
        }
    }
}

class TableViewCell: UITableViewCell {
    weak var label: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        createViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TableViewCell {
    func createViews() {
        contentView.vertical {
            label <~ UILabel().with
                .height(70)
        }
    }
}


extension CharateristicType {
    var name: String {
        return "\(self)"
    }
}
