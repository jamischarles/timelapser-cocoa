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
    private let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    
    // MARK: - Initialization
    init() {
        loadProjects()
    }
    
    // MARK: - Project Management
    func createNewProject() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        
        let projectName = "Project_\(timestamp)"
        let projectsURL = downloadsURL.appendingPathComponent("TimelapseCaptureProjects")
        let projectURL = projectsURL.appendingPathComponent(projectName)
        
        do {
            try fileManager.createDirectory(at: projectURL, withIntermediateDirectories: true)
            let project = Project(name: projectName, url: projectURL, createdAt: Date())
            projects.append(project)
            currentProject = project
            print("📁 Created project: \(projectName)")
        } catch {
            print("❌ Failed to create project: \(error.localizedDescription)")
        }
    }
    
    func refreshProjects() {
        loadProjects()
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
        let projectsURL = downloadsURL.appendingPathComponent("TimelapseCaptureProjects")
        
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
        let projectsURL = downloadsURL.appendingPathComponent("TimelapseCaptureProjects")
        
        guard fileManager.fileExists(atPath: projectsURL.path) else {
            projects = []
            return
        }
        
        do {
            let projectDirectories = try fileManager.contentsOfDirectory(at: projectsURL, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
            
            projects = projectDirectories.compactMap { url in
                guard url.hasDirectoryPath else { return nil }
                
                let name = url.lastPathComponent
                let createdAt = (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date()
                
                return Project(name: name, url: url, createdAt: createdAt)
            }.sorted { $0.createdAt > $1.createdAt }
            
        } catch {
            print("⚠️ Could not load projects: \(error.localizedDescription)")
            projects = []
        }
    }
}

// MARK: - Project Model
struct Project: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let url: URL
    let createdAt: Date
    
    static func == (lhs: Project, rhs: Project) -> Bool {
        return lhs.id == rhs.id
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