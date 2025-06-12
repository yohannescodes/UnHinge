import UIKit
import Firebase
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    let notificationManager = NotificationManager.shared
    
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Set up Firebase Messaging
        Messaging.messaging().delegate = self
        
        // Request notification permission
        Task {
            do {
                try await notificationManager.requestAuthorization()
            } catch {
                // Optional: Log an error or handle it if authorization fails
                print("Failed to request notification authorization: \(error)")
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            notificationManager.updateFCMToken(token) // Pass the token
        }
    }
}