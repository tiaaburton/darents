//
//  ActivityView.swift
//  DarentsApp
//
//  Created by Tia Burton on 7/3/25.
//

import SwiftUI

// MARK: - Data Models

// Represents the different types of activities a user can log.
// CaseIterable allows us to loop over all cases, useful for creating forms.
enum ActivityType: String, CaseIterable, Identifiable {
    case walk = "Walk"
    case potty = "Potty"
    case medical = "Medical"
    case playdate = "Play Date"
    case daycare = "Daycare"

    var id: String { self.rawValue }

    // Assigns a specific SF Symbol to each activity type for visual representation.
    var icon: String {
        switch self {
        case .walk: return "figure.walk"
        case .potty: return "leaf.fill"
        case .medical: return "cross.case.fill"
        case .playdate: return "person.2.fill"
        case .daycare: return "house.fill"
        }
    }

    // Assigns a unique color to each activity type, making the UI more scannable.
    var color: Color {
        switch self {
        case .walk: return .blue
        case .potty: return .green
        case .medical: return .red
        case .playdate: return .orange
        case .daycare: return .purple
        }
    }
}

// Represents a single logged activity.
// Identifiable is necessary for using this struct in SwiftUI lists.
struct ActivityLog: Identifiable, Hashable {
    var id = UUID()
    var type: ActivityType
    var timestamp: Date
    var notes: String = ""
    var petId: UUID // To associate the log with a specific pet
}

// MARK: - View Model
class ActivityViewModel: ObservableObject {
    // The pet for whom we are logging activities.
    @Published var pet: PetProfile?
    
    // An array of sample activities. In a real app, this would be loaded from a database.
    @Published var activityLog: [ActivityLog] = []

    // Initialize with a binding to the pet
    init(pet: PetProfile? = nil) {
            self.pet = pet
            if let currentPet = pet {
                loadSampleActivities(for: currentPet.id)
            }
        }
    // Function to add a new activity to the log.
    func logActivity(type: ActivityType, notes: String = "") {
        guard let currentPetId = pet?.id else {
            print("Cannot log activity: No pet selected.")
            return
        }
        let newLog = ActivityLog(type: type, timestamp: Date(), notes: notes, petId: currentPetId)
        // Insert at the beginning to show the most recent activity first.
        activityLog.insert(newLog, at: 0)
    }
    
    // Creates some sample data for previewing the UI.
    // Filter activities by petId if a pet is provided
    private func loadSampleActivities(for petId: UUID) {
        self.activityLog = [
            ActivityLog(type: .walk, timestamp: Date().addingTimeInterval(-3600), notes: "Walked around the park for 30 minutes.", petId: petId),
            ActivityLog(type: .potty, timestamp: Date().addingTimeInterval(-7200), petId: petId),
            ActivityLog(type: .playdate, timestamp: Date().addingTimeInterval(-10800), notes: "Met with Sparky at the dog park.", petId: petId),
            ActivityLog(type: .medical, timestamp: Date().addingTimeInterval(-86400 * 2), notes: "Annual check-up. All good!", petId: petId)
        ]
    }
    
    // Function to update activities when the selected pet changes
    func updateActivitiesForPet() {
        activityLog.removeAll() // Clear existing logs
        if let currentPet = pet {
            loadSampleActivities(for: currentPet.id)
        }
    }
}

// MARK: - Main Activity View
struct ActivityView: View {
    // Access the shared OnboardingViewModel from the environment
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    
    // State to hold the currently selected pet for activity tracking
    @State private var selectedPet: PetProfile?
    
    // StateObject for the ActivityViewModel, initialized with a binding to selectedPet
    @StateObject private var viewModel: ActivityViewModel
    
    @State private var isShowingAddSheet = false

    // Custom initializer to set up the StateObject with a binding
    init() {
        // Initialize with a dummy binding for now, will be updated in .onAppear
        // The _viewModel syntax is used to initialize the StateObject with its wrappedValue
        _viewModel = StateObject(wrappedValue: ActivityViewModel())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Display a message if no pets are added or selected
            if onboardingViewModel.petProfiles.isEmpty {
                VStack {
                    Image(systemName: "pawprint.slash.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No pets added yet.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Go to the 'Pet Profile' tab to add your first pet!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if selectedPet == nil {
                VStack {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Select a pet to view activities.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Main content area when a pet is selected
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Header
                        // Pass the unwrapped selectedPet to HeaderView
                        if let pet = selectedPet {
                            HeaderView(pet: pet)
                        }

                        // MARK: - Quick Log Buttons
                        QuickLogView { activityType in
                            viewModel.logActivity(type: activityType)
                        }

                        // MARK: - Activity History
                        ActivityHistoryView(logs: viewModel.activityLog)
                        
                        // Add padding at the bottom to avoid the FAB
                        Color.clear.frame(height: 80)
                    }
                }
                
                // MARK: - Floating Action Button
                FloatingActionButton {
                    isShowingAddSheet = true
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Activity Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Add a picker to select the pet if there are multiple
            ToolbarItem(placement: .navigationBarTrailing) {
                if onboardingViewModel.petProfiles.count > 0 { // Changed condition to > 0 to always show picker if pets exist
                    Picker("Select Pet", selection: $selectedPet) {
                        Text("Select a Pet").tag(nil as PetProfile?) // Option to select no pet
                        ForEach(onboardingViewModel.petProfiles) { pet in
                            Text(pet.name.isEmpty ? "Unnamed Pet" : pet.name).tag(pet as PetProfile?) // Tag with optional PetProfile
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            // The sheet for adding a detailed activity log.
            AddActivitySheet(viewModel: viewModel)
        }
        .onAppear {
            // Set the selected pet to the first one available when the view appears
            if selectedPet == nil {
                selectedPet = onboardingViewModel.petProfiles.first
            }
            // Update the ActivityViewModel's pet binding
            // CORRECTED: Now assigning the Binding itself to the _pet property wrapper of the ViewModel
            viewModel.pet = selectedPet
            viewModel.updateActivitiesForPet() // Load activities for the initial selected pet
        }
        .onChange(of: selectedPet) { newSelectedPet in // Use newSelectedPet for clarity
            // When selectedPet changes, update the ActivityViewModel and reload activities
            // CORRECTED: Now assigning the Binding itself to the _pet property wrapper of the ViewModel
            viewModel.pet = selectedPet
            viewModel.updateActivitiesForPet()
        }
        .onChange(of: onboardingViewModel.petProfiles) { newProfiles in
            // If the list of pets changes (e.g., a new pet is added),
            // ensure selectedPet is still valid or update it.
            if let currentSelectedId = selectedPet?.id, !newProfiles.contains(where: { $0.id == currentSelectedId }) {
                selectedPet = newProfiles.first // If the selected pet was removed, default to the first
            } else if selectedPet == nil && !newProfiles.isEmpty {
                selectedPet = newProfiles.first // If no pet was selected and new profiles exist, select the first
            }
            // CORRECTED: Now assigning the Binding itself to the _pet property wrapper of the ViewModel
            viewModel.pet = selectedPet
            viewModel.updateActivitiesForPet()
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    let pet: PetProfile // This now receives a non-optional PetProfile
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Activity For")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(pet.name.isEmpty ? "Unnamed Pet" : pet.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            Spacer()
            // Display pet's profile image or a placeholder
            pet.profileImage?
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .shadow(radius: 4)
                .clipped() // Ensure content is clipped to the circle
        }
        .padding(.horizontal)
    }
}

// MARK: - Quick Log Buttons View
struct QuickLogView: View {
    var onLog: (ActivityType) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Quick Log")
                .font(.title2).fontWeight(.bold)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                QuickLogButton(type: .walk, action: { onLog(.walk) })
                QuickLogButton(type: .potty, action: { onLog(.potty) })
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Activity History View
struct ActivityHistoryView: View {
    let logs: [ActivityLog]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Activity")
                .font(.title2).fontWeight(.bold)
                .padding(.horizontal)

            if logs.isEmpty {
                VStack {
                    Image(systemName: "moon.stars.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No activities logged yet for this pet.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(logs) { log in
                        ActivityRowView(log: log)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}


// MARK: - Add Activity Sheet
struct AddActivitySheet: View {
    @ObservedObject var viewModel: ActivityViewModel // Still takes ActivityViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedActivity: ActivityType = .medical
    @State private var notes: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    Picker("Activity Type", selection: $selectedActivity) {
                        ForEach(ActivityType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    TextEditor(text: $notes)
                        .frame(height: 150)
                }
            }
            .navigationTitle("Add New Event")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    viewModel.logActivity(type: selectedActivity, notes: notes)
                    dismiss()
                }.bold()
            )
        }
    }
}

// MARK: - Custom UI Components

// A stylish button for the "Quick Log" section.
struct QuickLogButton: View {
    let type: ActivityType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: type.icon)
                    .font(.title)
                Text(type.rawValue)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [type.color.opacity(0.8), type.color]), startPoint: .top, endPoint: .bottom)
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: type.color.opacity(0.4), radius: 8, y: 4)
        }
    }
}

// A view for a single row in the activity history list.
struct ActivityRowView: View {
    let log: ActivityLog

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: log.type.icon)
                .font(.title)
                .foregroundColor(log.type.color)
                .frame(width: 40)

            VStack(alignment: .leading) {
                Text(log.type.rawValue)
                    .font(.headline)
                    .fontWeight(.bold)
                
                if !log.notes.isEmpty {
                    Text(log.notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text(log.timestamp, style: .time)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// A floating action button for adding new events.
struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title.weight(.semibold))
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(radius: 10, y: 5)
        }
        .padding()
    }
}



// MARK: - SwiftUI Preview
struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample pet.
        let samplePet = PetProfile(id: UUID(), name: "Theodore")
        var onboardingVM = OnboardingViewModel()
        // Initialize OnboardingViewModel directly within the environmentObject modifier.
        // This avoids intermediate variable declarations that can confuse the compiler
        // in this specific static context.
        NavigationView {
            ActivityView()
            .environmentObject(OnboardingViewModel())
        }
    }
}
