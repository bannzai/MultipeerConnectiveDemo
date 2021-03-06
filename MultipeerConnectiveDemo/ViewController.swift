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
    var connectedPeerIDs: [MCPeerID] = []
    
    let peerID = MCPeerID(displayName: UUID().uuidString)
    lazy var session: MCSession = {
        let session = MCSession(peer: peerID)
        return session
    }()
    lazy var advertiser: MCNearbyServiceAdvertiser = {
        let advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        return advertiser
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        messages.append("me: \(peerID.displayName)")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TableViewCell.classForCoder(), forCellReuseIdentifier: "TableViewCell")

        session.delegate = self
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItems = [
            .init(title: "Browse", style: .plain, target: self, action: #selector(browseButtonPressed)),
            .init(title: "Send", style: .plain, target: self, action: #selector(sendButtonPressed)),
        ]
        tableView.reloadData()
    }
    
    @objc func sendButtonPressed() {
        if connectedPeerIDs.isEmpty {
            return
        }
        let image = UIImage(named: "bannzai")!
        do {
            try session.send(
                image.jpegData(compressionQuality: 0.5)!,
                toPeers: connectedPeerIDs,
                with: .reliable
            )
        } catch {
            print(error)
        }
    }
    
    @objc func browseButtonPressed() {
        let browserViewController: MCBrowserViewController = .init(serviceType: serviceType, session: session)
        browserViewController.delegate = self
        present(browserViewController, animated: true, completion: nil)
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
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
        switch state {
        case .notConnected:
            connectedPeerIDs.removeAll()
        case .connecting:
            break
        case .connected:
            connectedPeerIDs.append(peerID)
        @unknown default:
            fatalError("unexpected state \(state.rawValue)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            print(#function, data, peerID)
            self.messages.append(join(#function, data, peerID))
            self.tableView.reloadData()
        }
        
        DispatchQueue.main.async {
            let image = UIImage(data: data)
            let imageView = UIImageView(image: image)
            imageView.center = self.view.center
            self.view.addSubview(imageView)

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                imageView.removeFromSuperview()
            }
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

extension ViewController: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {

    }
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print(#function)
        invitationHandler(true, session)
        DispatchQueue.main.async {
            self.messages.append(#function)
        }
    }
}

extension ViewController: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        print(#function)
        messages.append((#function))
        tableView.reloadData()
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        print(#function)
        browserViewController.dismiss(animated: true, completion: nil)
        messages.append((#function))
        tableView.reloadData()
    }
    func browserViewController(_ browserViewController: MCBrowserViewController, shouldPresentNearbyPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
        DispatchQueue.main.async {
            print(#function, peerID, String(describing: info))
            self.messages.append(join(#function, peerID, String(describing: info)))
            self.tableView.reloadData()
        }
        return true
    }
}

final class TableViewCell: UITableViewCell {
    
}
