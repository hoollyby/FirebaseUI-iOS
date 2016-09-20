//
//  Copyright (c) 2016 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import FirebaseFacebookAuthUI
import FirebaseTwitterAuthUI

let kFirebaseTermsOfService = NSURL(string: "https://firebase.google.com/terms/")!

// Your Google app's client ID, which can be found in the GoogleService-Info.plist file
// and is stored in the `clientID` property of your FIRApp options.
// Firebase Google auth is built on top of Google sign-in, so you'll have to add a URL
// scheme to your project as outlined at the bottom of this reference:
// https://developers.google.com/identity/sign-in/ios/start-integrating
let kGoogleAppClientID = (FIRApp.defaultApp()?.options.clientID)!

// Your Facebook App ID, which can be found on developers.facebook.com.
let kFacebookAppID     = "your fb app ID here"

/// A view controller displaying a basic sign-in flow using FIRAuthUI.
class AuthViewController: UITableViewController {
  // Before running this sample, make sure you've correctly configured
  // the appropriate authentication methods in Firebase console. For more
  // info, see the Auth README at ../../FirebaseAuthUI/README.md
  // and https://firebase.google.com/docs/auth/

  private var authStateDidChangeHandle: FIRAuthStateDidChangeListenerHandle?

  private(set) var auth: FIRAuth? = FIRAuth.auth()
  private(set) var authUI: FIRAuthUI? = FIRAuthUI.defaultAuthUI()

  @IBOutlet weak var cellSignedIn: UITableViewCell!
  @IBOutlet weak var cellName: UITableViewCell!
  @IBOutlet weak var cellEmail: UITableViewCell!
  @IBOutlet weak var cellUid: UITableViewCell!
  @IBOutlet weak var cellAccessToken: UITableViewCell!
  @IBOutlet weak var cellIdToken: UITableViewCell!

  @IBOutlet weak var btnAuthorization: UIBarButtonItem!


  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 240;

    // If you haven't set up your authentications correctly these buttons
    // will still appear in the UI, but they'll crash the app when tapped.
    let providers: [FIRAuthProviderUI] = [
      FIRGoogleAuthUI(clientID: kGoogleAppClientID),
      FIRFacebookAuthUI(appID: kFacebookAppID),
      FIRTwitterAuthUI(),
    ]
    self.authUI?.providers = providers

    self.authUI?.TOSURL = kFirebaseTermsOfService

    self.authStateDidChangeHandle =
      self.auth?.addAuthStateDidChangeListener(self.updateUI(auth:user:))
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    if let handle = self.authStateDidChangeHandle {
      self.auth?.removeAuthStateDidChangeListener(handle)
    }
  }

  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return UITableViewAutomaticDimension
  }

  @IBAction func onAuthorize(sender: AnyObject) {
    if (self.auth?.currentUser) != nil {
      do {
        try self.auth?.signOut()
      } catch let error {
        // Again, fatalError is not a graceful way to handle errors.
        // This error is most likely a network error, so retrying here
        // makes sense.
        fatalError("Could not sign out: \(error)")
      }

      for provider in self.authUI!.providers {
        provider.signOutWithAuth(self.auth!)
      }

    } else {
      let controller = self.authUI!.authViewController()
      self.presentViewController(controller, animated: true, completion: nil)
    }
  }

  // Boilerplate
  func updateUI(auth auth: FIRAuth, user: FIRUser?) {
    if let user = self.auth?.currentUser {
      self.cellSignedIn.textLabel?.text = "Signed in"
      self.cellName.textLabel?.text = user.displayName ?? "(null)"
      self.cellEmail.textLabel?.text = user.email ?? "(null)"
      self.cellUid.textLabel?.text = user.uid

      self.btnAuthorization.title = "Sign Out";
    } else {
      self.cellSignedIn.textLabel?.text = "Not signed in"
      self.cellName.textLabel?.text = "null"
      self.cellEmail.textLabel?.text = "null"
      self.cellUid.textLabel?.text = "null"

      self.btnAuthorization.title = "Sign In";
    }

    self.cellAccessToken.textLabel?.text = getAllAccessTokens()
    self.cellIdToken.textLabel?.text = getAllIdTokens()

    self.tableView.reloadData()
  }

  func getAllAccessTokens() -> String {
    var result = ""
    for provider in self.authUI!.providers {
      result += (provider.shortName + ": " + provider.accessToken + "\n")
    }

    return result
  }

  func getAllIdTokens() -> String {
    var result = ""
    for provider in self.authUI!.providers {
      result += (provider.shortName + ": " + (provider.idToken ?? "null")  + "\n")
    }

    return result
  }
}
