//
//  ViewController.swift
//  MultipeerConnectiveDemo
//
//  Created by Yudai.Hirose on 2021/03/19.
//

import UIKit
import MultipeerConnectivity

func join(_ args: Any...) -> String {
    args.map(String.init(describing:)).joined(separator: ",")
}

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var messages: [String] = []
    var serviceType: String { "bannzai-p2p" }
    
    let peerID = MCPeerID(displayName: UUID().uuidString)
    lazy var session: MCSession = {
        let session = MCSession(peer: peerID)
        return session
    }()
    lazy var advertiser: MCNearbyServiceAdvertiser = {
        let advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: ["name": "bannzai"], serviceType: serviceType)
        return advertiser
    }()
    lazy var browser: MCNearbyServiceBrowser = .init(peer: peerID, serviceType: serviceType)

    override func viewDidLoad() {
        super.viewDidLoad()

        messages.append(peerID.displayName)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TableViewCell.classForCoder(), forCellReuseIdentifier: "TableViewCell")

        session.delegate = self
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = .init(title: "Browser", style: .plain, target: self, action: #selector(browserButtonPressed))
        tableView.reloadData()
    }
    
    @objc func browserButtonPressed() {
        browser.delegate = self
        browser.startBrowsingForPeers()
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath)
        cell.textLabel?.text = messages[indexPath.row]
        return cell
    }
}

extension ViewController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            print(#function, peerID, state.rawValue)
            self.messages.append(join(#function, peerID, state.rawValue))
            self.tableView.reloadData()
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            print(#function, data, peerID)
            self.messages.append(join(#function, data, peerID))
            self.tableView.reloadData()
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            print(#function, stream, streamName, peerID)
            self.messages.append(join(#function, stream, streamName, peerID))
            self.tableView.reloadData()
        }
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        DispatchQueue.main.async {
            print(#function, resourceName, peerID, progress)
            self.messages.append(join(#function, resourceName, peerID, progress))
            self.tableView.reloadData()
        }
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        DispatchQueue.main.async {
            print(#function, resourceName, peerID, String(describing: localURL), String(describing: error))
            self.messages.append(join(#function, resourceName, peerID, String(describing: localURL), String(describing: error)))
            self.tableView.reloadData()
        }
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            print(#function, String(describing: certificate), peerID)
            self.messages.append(join(#function, String(describing: certificate), peerID))
            self.tableView.reloadData()
            certificateHandler(true)
        }
    }
}

extension ViewController: MCAdvertiserAssistantDelegate {
    func advertiserAssistantDidDismissInvitation(_ advertiserAssistant: MCAdvertiserAssistant) {
        DispatchQueue.main.async {
            print(#function)
            self.messages.append((#function))
            self.tableView.reloadData()
        }
    }
    func advertiserAssistantWillPresentInvitation(_ advertiserAssistant: MCAdvertiserAssistant) {
        DispatchQueue.main.async {
            print(#function)
            self.messages.append((#function))
            self.tableView.reloadData()
        }
    }
}

extension ViewController: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
        DispatchQueue.main.async {
            print(#function, peerID, String(describing: context))
            self.messages.append(join(#function, peerID, String(describing: context)))
            self.tableView.reloadData()
        }
    }
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            print(#function, error)
            self.messages.append(join(#function, error))
            self.tableView.reloadData()
        }
    }
}

extension ViewController: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            print(#function)
            self.messages.append((#function))
            self.tableView.reloadData()
        }
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            print(#function)
            self.messages.append((#function))
            self.tableView.reloadData()
        }
    }
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: "this is data".data(using: .utf8), timeout: 4)
        DispatchQueue.main.async {
            print(#function, peerID, String(describing: info))
            self.messages.append(join(#function, peerID, String(describing: info)))
            self.tableView.reloadData()
        }
    }
}

final class TableViewCell: UITableViewCell {
    
}
