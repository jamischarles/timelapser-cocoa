import class Foundation.Bundle

extension Foundation.Bundle {
    static let module: Bundle = {
        let mainPath = Bundle.main.bundleURL.appendingPathComponent("TimelapseCreator_TimelapseCreator.bundle").path
        let buildPath = "/Users/jamismcharles/dev_freelance/timelapser_cocoa/.build/x86_64-apple-macosx/debug/TimelapseCreator_TimelapseCreator.bundle"

        let preferredBundle = Bundle(path: mainPath)

        guard let bundle = preferredBundle ?? Bundle(path: buildPath) else {
            fatalError("could not load resource bundle: from \(mainPath) or \(buildPath)")
        }

        return bundle
    }()
}