import SwiftUI

struct GoogleSyncView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var syncEngine: SyncEngine
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Header with Google branding
                headerSection
                
                // Authentication section
                authSection
                
                // Sync controls (only visible when authenticated)
                if authManager.isSignedIn {
                    syncControlsSection
                }
                
                // Sync status and statistics
                if authManager.isSignedIn {
                    syncStatusSection
                }
                
                Spacer()
            }
            .padding(AppTheme.Spacing.xl)
            .navigationTitle("Google Tasks Sync")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.primary)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Google Tasks Sync")
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text("Synchronize your tasks and lists with Google Tasks")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Authentication Section
    private var authSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            if authManager.isSignedIn {
                // Signed in state
                VStack(spacing: AppTheme.Spacing.md) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.success)
                        Text("Connected to Google Tasks")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.success)
                    }
                    
                    Button("Sign Out") {
                        authManager.signOut()
                    }
                    .buttonStyle(ModernButtonStyle(color: AppTheme.Colors.error, isSecondary: true))
                }
                .cardStyle()
                .padding(AppTheme.Spacing.lg)
            } else {
                // Sign in prompt
                VStack(spacing: AppTheme.Spacing.lg) {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("Sign in to Google")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.primaryText)
                        
                        Text("Connect your Google account to sync tasks and lists across devices")
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    
                    if authManager.isAuthenticating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Signing in...")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                    } else {
                        Button {
                            authManager.signIn()
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                Text("Sign in with Google")
                            }
                            .font(AppTheme.Typography.headline)
                        }
                        .buttonStyle(ModernButtonStyle())
                    }
                    
                    if let error = authManager.authError {
                        Text(error)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.error)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .multilineTextAlignment(.center)
                    }
                }
                .cardStyle()
                .padding(AppTheme.Spacing.lg)
            }
        }
    }
    
    // MARK: - Sync Controls Section
    private var syncControlsSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Sync Settings")
                .font(AppTheme.Typography.title)
                .foregroundColor(AppTheme.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: AppTheme.Spacing.md) {
                // Sync toggle
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Automatic Sync")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.primaryText)
                        
                        Text("Automatically sync changes with Google Tasks")
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { syncEngine.isSyncEnabled },
                        set: { enabled in
                            if enabled {
                                syncEngine.enableSync()
                            } else {
                                syncEngine.disableSync()
                            }
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle())
                }
                
                Divider()
                
                // Manual sync button
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Manual Sync")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.primaryText)
                        
                        Text("Sync now to get the latest changes")
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await syncEngine.syncNow()
                        }
                    } label: {
                        HStack {
                            if case .syncing = syncEngine.syncStatus {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Syncing...")
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Sync Now")
                            }
                        }
                    }
                    .buttonStyle(ModernButtonStyle(isSecondary: true))
                    .disabled(case .syncing = syncEngine.syncStatus)
                }
            }
            .cardStyle()
            .padding(AppTheme.Spacing.lg)
        }
    }
    
    // MARK: - Sync Status Section
    private var syncStatusSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Sync Status")
                .font(AppTheme.Typography.title)
                .foregroundColor(AppTheme.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: AppTheme.Spacing.md) {
                // Current status
                HStack {
                    syncStatusIcon
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(syncStatusText)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(syncStatusColor)
                        
                        if let lastSync = syncEngine.lastSync {
                            Text("Last sync: \(lastSync, style: .relative)")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                    }
                    
                    Spacer()
                }
                
                // Sync statistics
                if syncEngine.lastSyncStats != SyncStats.empty {
                    Divider()
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppTheme.Spacing.md) {
                        SyncStatCard(
                            title: "Lists Downloaded",
                            value: "\(syncEngine.lastSyncStats.listsDownloaded)",
                            icon: "arrow.down.circle",
                            color: AppTheme.Colors.primary
                        )
                        
                        SyncStatCard(
                            title: "Lists Uploaded", 
                            value: "\(syncEngine.lastSyncStats.listsUploaded)",
                            icon: "arrow.up.circle",
                            color: AppTheme.Colors.primary
                        )
                        
                        SyncStatCard(
                            title: "Tasks Downloaded",
                            value: "\(syncEngine.lastSyncStats.tasksDownloaded)",
                            icon: "arrow.down.circle.fill",
                            color: AppTheme.Colors.success
                        )
                        
                        SyncStatCard(
                            title: "Tasks Uploaded",
                            value: "\(syncEngine.lastSyncStats.tasksUploaded)",
                            icon: "arrow.up.circle.fill",
                            color: AppTheme.Colors.success
                        )
                    }
                    
                    if syncEngine.lastSyncStats.conflicts > 0 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppTheme.Colors.warning)
                            
                            Text("\(syncEngine.lastSyncStats.conflicts) conflicts resolved (local changes preferred)")
                                .font(AppTheme.Typography.callout)
                                .foregroundColor(AppTheme.Colors.warning)
                        }
                        .padding(.top, AppTheme.Spacing.sm)
                    }
                }
            }
            .cardStyle()
            .padding(AppTheme.Spacing.lg)
        }
    }
    
    // MARK: - Helper Views and Properties
    
    private var syncStatusIcon: some View {
        Group {
            switch syncEngine.syncStatus {
            case .idle:
                Image(systemName: "pause.circle")
                    .foregroundColor(AppTheme.Colors.secondaryText)
            case .syncing:
                ProgressView()
                    .scaleEffect(0.8)
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.Colors.success)
            case .error:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(AppTheme.Colors.error)
            }
        }
        .font(.title2)
    }
    
    private var syncStatusText: String {
        switch syncEngine.syncStatus {
        case .idle:
            return "Ready to sync"
        case .syncing:
            return "Syncing..."
        case .success:
            return "Sync completed"
        case .error(let message):
            return "Sync failed: \(message)"
        }
    }
    
    private var syncStatusColor: Color {
        switch syncEngine.syncStatus {
        case .idle:
            return AppTheme.Colors.secondaryText
        case .syncing:
            return AppTheme.Colors.primary
        case .success:
            return AppTheme.Colors.success
        case .error:
            return AppTheme.Colors.error
        }
    }
}

// MARK: - Supporting Views

struct SyncStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(value)
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardStyle()
        .padding(AppTheme.Spacing.sm)
    }
}

#Preview {
    GoogleSyncView()
        .environmentObject(AuthManager.shared)
        .environmentObject(SyncEngine.shared)
}
