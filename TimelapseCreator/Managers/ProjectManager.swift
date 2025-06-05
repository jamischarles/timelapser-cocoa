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
    
    private func loadProjects() {
        let projectsURL = downloadsURL.appendingPathComponent("TimelapseCaptureProjects")
        
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
            return contents.filter { $0.pathExtension == "png" }.count
        } catch {
            return 0
        }
    }
} 