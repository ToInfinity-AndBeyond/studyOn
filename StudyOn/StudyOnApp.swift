import SwiftUI
import Firebase
import FirebaseAuth
import CoreLocation

@main
struct StudyOnApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var userViewModel = UserViewModel()
    @StateObject var studyLocationViewModel = StudyLocationViewModel()
    @State private var isUserLoggedIn: Bool = false

    @StateObject private var fontSizeManager = FontSizeManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if isUserLoggedIn {
                    LocationsView()  
                        .environmentObject(studyLocationViewModel)
                        .environmentObject(userViewModel)
                        .environmentObject(NotificationHandlerModel.shared)
                        .environmentObject(fontSizeManager)
                        .onAppear {
                            userViewModel.fetchCurrentUser()
                        }
                } else {
                    AuthView(isUserLoggedIn: $isUserLoggedIn)
                        .environmentObject(studyLocationViewModel)
                        .environmentObject(userViewModel)
                        .environmentObject(fontSizeManager)
                }
            }
        }
    }
}
struct AuthView: View {
    @Binding var isUserLoggedIn: Bool
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var studyLocationViewModel: StudyLocationViewModel
    var body: some View {
        NavigationStack {
            if userViewModel.isUserLoggedIn {
                LocationsView().environmentObject(studyLocationViewModel).environmentObject(userViewModel).environmentObject(NotificationHandlerModel.shared)
            } else {
                LoginView(isUserLoggedIn: $isUserLoggedIn).environmentObject(studyLocationViewModel).environmentObject(userViewModel)
            }
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        // addSampleData()
        print("Configured Firebase!")
        LocationServiceManager.shared.startMonitoring()
        
        UNUserNotificationCenter.current().delegate = self
        print("Set UNUserNotificationCenter delegate")
        
        requestNotificationPermissions()
        print("Configure Notification Service!")

        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .sound, .badge])
    }
        
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission denied: \(error.localizedDescription)")
            } else {
                print("Notification permission was not granted.")
            }
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        LocationServiceManager.shared.startMonitoringSignificantLocationChanges()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        LocationServiceManager.shared.startUpdatingLocation()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Navigating according to the information")
        
        DispatchQueue.main.async {
            NotificationHandlerModel.shared.doNavigate = true
        }
        print(NotificationHandlerModel.shared.studyLocation?.name ?? "Not applied")
        
        completionHandler()
    }
}

func addSampleData() {
    
    let db = Firestore.firestore()
    
    db.collection("studyLocations").getDocuments { snapshot, error in
        guard let documents = snapshot?.documents else {
            print("No documents")
            return
        }
        
        let existingDocuments = documents.reduce(into: [String: DocumentSnapshot]()) { result, document in
            if let name = document.data()["name"] as? String {
                result[name] = document
            }
        }
            
        let sampleEnvFactors = EnvFactor(
            dynamicData: [
                "crowdedness": 1.9,
                "noise": 1.9,
            ], 
            staticData: [
                "wifi speed": 4.0,
                "# tables": 15,
                "# sockets": 10,
                "# PCs": 10,
                "# meeting rooms": 2
            ],
            atmosphere: ["Calm", "Pet-friendly", "Wi-fi"]
        )

        let sampleEnvFactors2 = EnvFactor(
            dynamicData: [
                "crowdedness": 1.1,
                "noise": 1.1
            ],
            staticData: [
                "wifi speed": 5.0,
                "# tables": 7,
                "# sockets": 10.0,
                "Cheapest Menu (£)": 2.90,
                "# toilets": 2
            ],
            atmosphere: ["Lively", "Nice music", "Pet-friendly", "Wi-fi"]
        )

        let sampleEnvFactors3 = EnvFactor(
            dynamicData: [
                "crowdedness": 2.9,
                "noise": 2.9
            ],
            staticData: [
                "wifi speed": 5.0,
                "# tables": 4,
                "# sockets": 3.0
            ], 
            atmosphere: ["Antique", "Clean", "Buggy-friendly", "Comfortable"]
        )
            
            let sampleComments = [
                Comment(name: "Alice", content: "Great place to study!", date: Date()),
                Comment(name: "Bob", content: "Quite noisy during peak hours.", date: Date()),
                Comment(name: "Charlie", content: "Friendly staff and good resources.", date: Date())
            ]

            let sampleHours = [
                "Monday": OpeningHours(opening: "09:00", closing: "18:00"),
                "Tuesday": OpeningHours(opening: "09:00", closing: "18:00"),
                "Wednesday": OpeningHours(opening: "09:00", closing: "18:00"),
                "Thursday": OpeningHours(opening: "09:00", closing: "18:00"),
                "Friday": OpeningHours(opening: "09:00", closing: "18:00"),
                "Saturday": OpeningHours(opening: "10:00", closing: "16:00"),
                "Sunday": OpeningHours(opening: "Closed", closing: "Closed")
            ]
            
            let sampleLocations = [
                StudyLocation(
                    name: "Imperial College London - Abdus Salam Library", 
                    title: "Imperial College London, South Kensington Campus, London SW7 2AZ", 
                    latitude: 51.49805710, 
                    longitude: -0.17824890, 
                    rating: 5.0, 
                    comments: sampleComments, 
                    images: ["imperial1", "imperial2", "imperial3"], 
                    hours: sampleHours, 
                    envFactor: sampleEnvFactors,
                    num: 4,
                    category: "library"
                ),
                StudyLocation(
                    name: "The London Library", 
                    title: "14 St James's Square, St. James's, London SW1Y 4LG", 
                    latitude: 51.50733901, 
                    longitude: -0.13698200, 
                    rating: 4.4,
                    comments: [],
                    images: ["theLondonLibrary1", "theLondonLibrary2", "theLondonLibrary3"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors, 
                    num: 4, 
                    category: "library"
                ),
                StudyLocation(
                    name: "Chelsea Library", 
                    title: "Chelsea Old Town Hall, King's Rd, London SW3 5EZ", 
                    latitude: 51.48738370, 
                    longitude: -0.16837240, 
                    rating: 4.1,
                    comments: [],
                    images: ["chelseaLibrary1", "chelseaLibrary2", "chelseaLibrary3"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors, 
                    num: 4, 
                    category: "library"
                ),
                StudyLocation(
                    name: "Fulham Library", 
                    title: "598 Fulham Rd., London SW6 5NX", 
                    latitude: 51.478, 
                    longitude: -0.2028, 
                    rating: 4.0,
                    comments: [],
                    images: ["fulhamLibrary1", "fulhamLibrary2"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors, 
                    num: 4, 
                    category: "library"
                ),
                StudyLocation(
                    name: "Brompton Library", 
                    title: "210 Old Brompton Rd, London SW5 0BS", 
                    latitude: 51.490, 
                    longitude: -0.188, 
                    rating: 4.1, 
                    comments: [], 
                    images: ["bromptonLibrary1", "bromptonLibrary2", "bromptonLibrary3"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors, 
                    num: 4, 
                    category: "library"
                ),
                StudyLocation(
                    name: "Avonmore Library", 
                    title:"7 North End Crescent, London W14 8TG", 
                    latitude: 51.492, 
                    longitude: -0.206, 
                    rating: 3.2,
                    comments: [],
                    images: ["avonmoreLibrary1"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors,
                    num: 4, 
                    category: "library"
                ),
                StudyLocation(
                    name: "Charing Cross Hospital Campus Library", 
                    title:"St Dunstan's Rd, London W6 8RP", 
                    latitude: 51.490, 
                    longitude: -0.218, 
                    rating: 1.5, 
                    comments: [], 
                    images: ["charingCrossHospitalLibrary1", "charingCrossHospitalLibrary2"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors,
                    num: 4, 
                    category: "library"
                ),
                StudyLocation(
                    name: "Paddington Library",
                    title:"Porchester Rd, London W2 5DU",
                    latitude: 51.52053488805303,
                    longitude: -0.1896702148538263,
                    rating: 4.3,
                    comments: [],
                    images: ["paddingtonLibrary1", "paddingtonLibrary2", "paddingtonLibrary3"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors,
                    num: 4,
                    category: "library"
                ),
                StudyLocation(
                    name: "The Maughan Library",
                    title:"Chancery Ln, London WC2A 1LR",
                    latitude: 51.51631065371879,
                    longitude: -0.11052710247528852,
                    rating: 4.5,
                    comments: [],
                    images: ["theMaughanLibrary1", "theMaughanLibrary2", "theMaughanLibrary3"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors,
                    num: 4,
                    category: "library"
                ),
                StudyLocation(
                    name: "Ad St C.H.S Public Library",
                    title:"Eccleston Pl, London SW1W 9TR",
                    latitude: 51.49377852740783,
                    longitude: -0.14859706297335137,
                    rating: 4.3,
                    comments: [],
                    images: ["CHSPublicLibrary1"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors,
                    num: 4,
                    category: "library"
                ),
// 10 libraries
                StudyLocation(
                    name: "Chelsea and Westminster Hospital: Imperial College Medical Library",
                    title: "Westminster Hospital, 369 Fulham Rd., London SW10 9NH",
                    latitude: 51.4892354996666,
                    longitude: -0.18221005241029767,
                    rating: 5.0,
                    comments: sampleComments,
                    images: ["imperialMedicalLibrary1", "imperialMedicalLibrary2"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors,
                    num: 4,
                    category: "library"
                ),
                StudyLocation(
                    name: "Shepherds Bush Library",
                    title: "6 Wood Ln, London W12 7BF",
                    latitude: 51.508844721627334,
                    longitude: -0.22436473288393743,
                    rating: 4.1,
                    comments: [],
                    images: ["shepherdsBushLibrary1", "shepherdsBushLibrary2", "shepherdsBushLibrary3"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors,
                    num: 4,
                    category: "library"
                ),
                StudyLocation(
                    name: "Ealing Central Library",
                    title: "The Broadway, London W5 5JY",
                    latitude: 51.51521381320692,
                    longitude: -0.3013932341074241,
                    rating: 3.6,
                    comments: [],
                    images: ["ealingCentralLibrary1", "ealingCentralLibrary2", "ealingCentralLibrary3"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors,
                    num: 4,
                    category: "library"
                ),
                StudyLocation(
                    name: "Acton Library",
                    title: "Everyone Active, Acton Centre, High St, London W3 6NE",
                    latitude: 51.51348578290701,
                    longitude: -0.26600927717098577,
                    rating: 3.6,
                    comments: [],
                    images: ["actonLibrary"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors,
                    num: 4,
                    category: "library"
                ),
                StudyLocation(
                    name: "Chiswick Library",
                    title: "1 Duke's Ave, Chiswick, London W4 2AB",
                    latitude: 51.49505321510942,
                    longitude:  -0.26120156366712455,
                    rating: 4.4,
                    comments: [],
                    images: ["chiswickLibrary1", "chiswickLibrary1", "chiswickLibrary3"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors,
                    num: 4,
                    category: "library"
                ),
                StudyLocation(
                    name: "Queen's Park Library",
                    title:"666 Harrow Rd, London W10 4NE",
                    latitude: 51.52943386282591,
                    longitude: -0.21060212369357748,
                    rating: 4.5,
                    comments: [],
                    images: ["queensParkLibrary1"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors,
                    num: 4,
                    category: "library"
                ),
                StudyLocation(
                    name: "York Gardens Library",
                    title:"34 Lavender Rd, London SW11 2UG",
                    latitude: 51.4719619890233,
                    longitude: -0.17488842198501123,
                    rating: 4.4,
                    comments: [],
                    images: ["yorkGardensLibrary1", "yorkGardensLibrary2", "yorkGardensLibrary3"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors,
                    num: 4,
                    category: "library"
                ),
                StudyLocation(
                    name: "Maida Vale Library",
                    title:"Sutherland Ave, London W9 2QT",
                    latitude: 51.527647872266876,
                    longitude: -0.1901044861123222,
                    rating: 4.2,
                    comments: [],
                    images: ["maidaValeLibrary1", "maidaValeLibrary2"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors,
                    num: 4,
                    category: "library"
                ),
                StudyLocation(
                    name: "University of Roehampton Library",
                    title:"University Library University of Roehampton, Roehampton Ln, London SW15 5SZ",
                    latitude: 51.46399045642243,
                    longitude: -0.24406155589831255,
                    rating: 4.9,
                    comments: [],
                    images: ["roehamptonUniversityLibrary1", "roehamptonUniversityLibrary2", "roehamptonUniversityLibrary3"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors,
                    num: 4,
                    category: "library"
                ),
                StudyLocation(
                    name: "Brunel University Library",
                    title:"Brunel University, Kingston Ln, Uxbridge UB8 3PH",
                    latitude: 51.55176045459242,
                    longitude: -0.486967624624432,
                    rating: 4.7,
                    comments: [],
                    images: ["brunelUniversityLibrary1", "brunelUniversityLibrary2", "brunelUniversityLibrary3"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors,
                    num: 4,
                    category: "library"
                ),
// 10 cafe
                StudyLocation(
                    name: "Starbucks - South Kensington",
                    title: "19 Old Brompton Rd, London SW7 3HZ",
                    latitude: 51.499,
                    longitude: -0.174,
                    rating: 3.9,
                    comments: [],
                    images: ["starbucksSouthKensington1", "starbucksSouthKensington2"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors2,
                    num: 4,
                    category: "cafe"
                ),
                StudyLocation(
                    name: "Caffe Nero - Gloucester Rd",
                    title:"119/121 Gloucester Rd, London SW7 4TE",
                    latitude: 51.496,
                    longitude: -0.181,
                    rating: 4.2,
                    comments: [],
                    images: ["caffeNeroGloucester1", "caffeNeroGloucester2"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors3,
                    num: 4,
                    category: "cafe"
                ),
                StudyLocation(
                    name: "Pret A Manger - Gloucester Rd",
                    title:"99 Gloucester Rd, London SW7 4SS",
                    latitude: 51.498,
                    longitude: -0.181,
                    rating: 4.1,
                    comments: [],
                    images: ["pretGloucester1", "pretGloucester2"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors2,
                    num: 4,
                    category: "cafe"
                ),
                StudyLocation(
                    name: "Pret A Manger - Earl's Court",
                    title: "230-232 Earls Ct Rd, London SW5 9RD",
                    latitude: 51.492218467487795,
                    longitude: -0.19307533138957186,
                    rating: 4.0,
                    comments: [],
                    images: ["pretEarlsCourt1", "pretEarlsCourt2", "pretEarlsCourt3"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors2,
                    num: 4,
                    category: "cafe"
                ),
                StudyLocation(
                    name: "Caffè Nero - Notting Hill Gate",
                    title:"53 Notting Hill Gate, London W11 3JS",
                    latitude: 51.510601091233305,
                    longitude: -0.19701237748410017,
                    rating: 4.2,
                    comments: [],
                    images: ["caffeNeroNottingHillGate1", "caffeNeroNottingHillGate2", "caffeNeroNottingHillGate3"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors2,
                    num: 4,
                    category: "cafe"
                ),
                StudyLocation(
                    name: "Caffè Nero - Southern Interchange",
                    title:"Unit C302, Level 30 Southern Interchange, London W12 7SL",
                    latitude: 51.506143948346164,
                    longitude: -0.21846883202088724,
                    rating: 3.9,
                    comments: [],
                    images: ["caffeNeroSouthernInterchange1", "caffeNeroSouthernInterchange2"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors3,
                    num: 4,
                    category: "cafe"
                ),
                StudyLocation(
                    name: "Starbucks - Queensway",
                    title:"49 Queensway, London W2 4QH",
                    latitude: 51.51254407693218,
                    longitude: -0.18794721623228366,
                    rating: 3.9,
                    comments: [],
                    images: ["starbucksQueensway1", "starbucksQueensway2"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors2,
                    num: 4,
                    category: "cafe"
                ),
                StudyLocation(
                    name: "Paris Baguette Kensington High Street",
                    title:"99 Gloucester Rd, London SW7 4SS",
                    latitude: 51.50083795053226,
                    longitude: -0.193400355818978,
                    rating: 4.3,
                    comments: [],
                    images: ["parisBaguetteKensingtonHighSt1", "parisBaguetteKensingtonHighSt2"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors3,
                    num: 4,
                    category: "cafe"
                ),
                StudyLocation(
                    name: "Caffè Nero - South Kensington",
                    title: "66 Old Brompton Rd, South Kensington, London SW7 3LQ",
                    latitude: 51.49395505184591,
                    longitude: -0.1768953320208872,
                    rating: 4.2,
                    comments: [],
                    images: ["caffeNeroOldBromptonRd1", "caffeNeroOldBromptonRd2"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors3,
                    num: 4,
                    category: "cafe"
                ),
// 10 cafes
                StudyLocation(
                    name: "JOE & THE JUICE - South Kensington",
                    title:"111 Old Brompton Rd, South Kensington, London SW7 3LE",
                    latitude: 51.49220255128421,
                    longitude: -0.17796846174598258,
                    rating: 3.9,
                    comments: [],
                    images: ["joeAndTheJuiceGloucester1", "joeAndTheJuiceGloucester2"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors2,
                    num: 4,
                    category: "cafe"
                ),
                StudyLocation(
                    name: "Starbucks - Gloucester Rd",
                    title:"83 Gloucester Rd, South Kensington, London SW7 4SS",
                    latitude: 51.49472149218343,
                    longitude: -0.18236996080958634,
                    rating: 3.8,
                    comments: [],
                    images: ["starbucksGloucester1", "starbucksGloucester2"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors2,
                    num: 4,
                    category: "cafe"
                ),
                StudyLocation(
                    name: "Starbucks - Earl's Court",
                    title:"203 Earls Ct Rd, London SW5 9AN",
                    latitude: 51.49210681843782,
                    longitude: -0.19225129683855438,
                    rating: 4.1,
                    comments: [],
                    images: ["starbucksEarlsCourt1", "starbucksEarlsCourt2"],
                    hours: sampleHours,
                    envFactor: sampleEnvFactors2,
                    num: 4,
                    category: "cafe"
                )
            ]
            
            let group = DispatchGroup()
            
            for location in sampleLocations {
                group.enter()
                let locationData: [String: Any] = [
                    "name": location.name,
                    "title": location.title,
                    "latitude": location.latitude,
                    "longitude": location.longitude,
                    "rating": location.rating,
                    "images": location.images,
                    "comments": location.comments.map { ["name": $0.name, "content": $0.content, "date": Timestamp(date: Date())] },
                    "hours": location.hours.mapValues { ["open": $0.opening, "close": $0.closing] },
                    "envFactors": [
                        "dynamicData": location.envFactor.dynamicData,
                        "staticData": location.envFactor.staticData,
                        "atmosphere": location.envFactor.atmosphere
                    ],
                    "num": location.num,
                    "category": location.category
                ]
                if let existingDocument = existingDocuments[location.name] {
                                // if original document exists, add to an existing instance
                                db.collection("studyLocations").document(existingDocument.documentID).setData(locationData, merge: true) { error in
                                    if let error = error {
                                        print("Error updating document: \(error)")
                                    } else {
                                        print("Document updated")
                                    }
                                    group.leave()
                                }
                            } else {
                                // if original document does not exist, create new instance
                                db.collection("studyLocations").addDocument(data: locationData) { error in
                                    if let error = error {
                                        print("Error adding document: \(error)")
                                    } else {
                                        print("Document added")
                                    }
                                    group.leave()
                                }
                            }
            }
            
            group.notify(queue: .main) {
                print("All sample data added.")
            }
    }
}
