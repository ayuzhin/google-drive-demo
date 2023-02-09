//
//  ViewController.swift
//  google-drive-demo
//
//  Created by Alexander Yuzhin on 09.02.2023.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import Pulse
import PulseUI
import SwiftUI


class ViewController: UIViewController {

    // MARK: - Properties
    
    private let clientId = "239133540307-qnvhhujrrj6m9ii73qhe1404ntft8mic.apps.googleusercontent.com"
    private let requestScopes = [kGTLRAuthScopeDrive, kGTLRAuthScopeDriveAppdata, kGTLRAuthScopeDriveFile]
    private var googleUser: GIDGoogleUser?
    private var googleError: Error?
    private let googleDriveService = GTLRDriveService()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        ///
        /// TODO:
        ///
        /// If you do not use the URLSession global proxy using URLSessionProxyDelegate
        /// via calling URLSessionProxyDelegate.enableAutomaticRegistration(), then in
        /// the Xcode console you can see the phrase `Fetch of items from Google Drive is done.`
        ///
        /// If you uncomment the line URLSessionProxyDelegate.enableAutomaticRegistration()
        /// in the viewDidAppear method of the ViewController, then the response from
        /// the google service will never be received, and in some case it may lead to a deadlock
        /// in GTMSessionFetcher and the application hangs.
        ///
        
//        URLSessionProxyDelegate.enableAutomaticRegistration()
//        testGoogle()
    }
    
    private func testGoogle() {
        signIn(clientID: clientId) { user, error in
            guard let user else {
                print(error ?? "SignIn Failure")
                return
            }
            
            self.fetchScopes(for: user) { user, error in
                guard let user else {
                    print(error ?? "FetchScopes Failure")
                    return
                }
                
                self.fetchDrive(for: user) { list, error in
                    print("Fetch of items from Google Drive is done.")
                    print(list ?? [])
                }
            }
        }
    }
    
    private func signIn(clientID: String, complation: @escaping (GIDGoogleUser?, NSError?) -> Void) {
        let signInConfig = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: self) { user, error in
            complation(user, error as NSError?)
        }
    }
    
    private func fetchScopes(for user: GIDGoogleUser, complation: @escaping (GIDGoogleUser?, NSError?) -> Void) {
        if let grantedScopes = user.grantedScopes, grantedScopes.contains(self.requestScopes) {
            complation(user, nil)
            return
        }
        
        GIDSignIn.sharedInstance.addScopes(self.requestScopes, presenting: self) { user, error in
            complation(user, error as NSError?)
        }
    }
    
    private func fetchDrive(for user: GIDGoogleUser, complation: @escaping (GTLRDrive_FileList?, NSError?) -> Void) {
        let query = GTLRDriveQuery_FilesList.query()
        googleDriveService.authorizer = user.authentication.fetcherAuthorizer()

        query.spaces = "drive"
        query.corpora = "user"
        query.q = "'root' in parents and trashed = false"
        query.fields = "files(id,name,mimeType,modifiedTime,createdTime,fileExtension,size,webContentLink)"
        
        googleDriveService.executeQuery(query) { _, result, error in
            complation(result as? GTLRDrive_FileList, error as NSError?)
        }
    }
    
    // MARK: - Outlets
    
    @IBAction func onFetch(_ sender: UIButton) {
        testGoogle()
    }
    
    
    @IBAction func onConsole(_ sender: UIButton) {
        let consoleVC = UINavigationController(rootViewController: UIHostingController(rootView: ConsoleView()))
        consoleVC.modalPresentationStyle = .formSheet
        self.present(consoleVC, animated: true)
    }
    
}

public extension Sequence where Element: Equatable {
    func contains(_ elements: [Element]) -> Bool {
        guard !elements.isEmpty else { return true }
        for element in elements {
            if !contains(element) {
                return false
            }
        }
        return true
    }
}
