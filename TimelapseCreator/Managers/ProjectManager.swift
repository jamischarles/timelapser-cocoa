//
//  ProjectManager.swift
//  TimelapseCreator
//
//  Created by AI Assistant on 1/6/25.
//  Copyright © 2025 Timelapse Creator. All rights reserved.
//

import SwiftUI
import Foundation

@MainActor
class ProjectManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentProject: Project?
    @Published var projects: [Project] = []
    
    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    // MARK: - Initialization
    init() {
        loadProjects()
        validateCurrentProject()
    }
    
    // MARK: - Project Management
    func createNewProject() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        
        let projectName = "Project_\(timestamp)"
        let projectsURL = documentsURL.appendingPathComponent("TimelapseCaptureProjects")
        let projectURL = projectsURL.appendingPathComponent(projectName)
        
        print("📁 Creating project directory: \(projectURL.path)")
        
        do {
            // Ensure the directory is created first
            try fileManager.createDirectory(at: projectURL, withIntermediateDirectories: true, attributes: nil)
            
            // Verify the directory was actually created
            guard fileManager.fileExists(atPath: projectURL.path) else {
                print("❌ Directory creation failed - path doesn't exist after creation")
                return
            }
            
            // Only create the project object after successful directory creation
            let project = Project(name: projectName, url: projectURL, createdAt: Date())
            projects.append(project)
            currentProject = project
            
            print("✅ Successfully created project: \(projectName) at \(projectURL.path)")
            
        } catch {
            print("❌ Failed to create project directory: \(error.localizedDescription)")
        }
    }
    
    func refreshProjects() {
        loadProjects()
        validateCurrentProject()
    }
    
    private func validateCurrentProject() {
        // Check if current project directory actually exists
        if let current = currentProject {
            if !fileManager.fileExists(atPath: current.url.path) {
                print("⚠️ Current project directory doesn't exist: \(current.url.path)")
                print("🔧 Clearing phantom project: \(current.name)")
                currentProject = nil
                
                // Set current project to the most recent one that exists
                if let mostRecent = projects.first {
                    currentProject = mostRecent
                    print("✅ Set current project to most recent: \(mostRecent.name)")
                }
            } else {
                print("✅ Current project validated: \(current.name)")
            }
        }
    }
    
    func deleteProject(_ project: Project) {
        print("🔍 Attempting to delete project: \(project.name) at \(project.url.path)")
        print("🔍 Current projects count: \(projects.count)")
        
        do {
            // Check if directory exists before deletion
            if fileManager.fileExists(atPath: project.url.path) {
                print("🔍 Directory exists, attempting deletion...")
                try fileManager.removeItem(at: project.url)
                print("✅ Successfully deleted directory")
            } else {
                print("⚠️ Directory doesn't exist at path: \(project.url.path)")
            }
            
            // Find and remove from projects array
            if let index = projects.firstIndex(of: project) {
                print("🔍 Found project at index \(index), removing from array...")
                projects.remove(at: index)
                print("✅ Removed from projects array. New count: \(projects.count)")
            } else {
                print("❌ Could not find project in projects array")
                // Debug: print all project names and IDs
                print("🔍 Current projects:")
                for (i, p) in projects.enumerated() {
                    print("  [\(i)] \(p.name) - ID: \(p.id)")
                }
                print("🔍 Target project: \(project.name) - ID: \(project.id)")
            }
            
            // Clear current project if it was deleted
            if currentProject?.id == project.id {
                currentProject = nil
                print("🔍 Cleared current project")
            }
            
            print("🗑️ Deleted project: \(project.name)")
        } catch {
            print("❌ Failed to delete project \(project.name): \(error.localizedDescription)")
        }
    }
    
    func deleteProjects(_ projectsToDelete: [Project]) {
        for project in projectsToDelete {
            deleteProject(project)
        }
    }
    
    func purgeAllProjects() {
        let projectsURL = documentsURL.appendingPathComponent("TimelapseCaptureProjects")
        
        do {
            try fileManager.removeItem(at: projectsURL)
            projects.removeAll()
            currentProject = nil
            print("🧹 Purged all projects")
        } catch {
            print("❌ Failed to purge projects: \(error.localizedDescription)")
        }
    }
    
    private func loadProjects() {
        let projectsURL = documentsURL.appendingPathComponent("TimelapseCaptureProjects")
        
        guard fileManager.fileExists(atPath: projectsURL.path) else {
            projects = []
            return
        }
        
        do {
            let projectDirectories = try fileManager.contentsOfDirectory(at: projectsURL, includingPropertiesForKeys: [URLResourceKey.creationDateKey], options: .skipsHiddenFiles)
            
            projects = projectDirectories.compactMap { url -> Project? in
                guard url.hasDirectoryPath else { return nil }
                
                let name = url.lastPathComponent
                let createdAt = (try? url.resourceValues(forKeys: [URLResourceKey.creationDateKey]))?.creationDate ?? Date()
                
                return Project(name: name, url: url, createdAt: createdAt)
            }.sorted { $0.createdAt > $1.createdAt }
            
        } catch {
            print("⚠️ Could not load projects: \(error.localizedDescription)")
            projects = []
        }
    }
}

// MARK: - Project Model
struct Project: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let createdAt: Date
    
    static func == (lhs: Project, rhs: Project) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var screenshotCount: Int {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            return contents.filter { 
                let ext = $0.pathExtension.lowercased()
                return ext == "png" || ext == "jpg" || ext == "jpeg"
            }.count
        } catch {
            return 0
        }
    }
} 