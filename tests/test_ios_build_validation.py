import unittest
import plistlib
import os
import re

class TestIOSBuildValidation(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        cls.info_plist_path = os.path.join(cls.root_dir, "MeloraApp", "Info.plist")
        cls.melora_app_path = os.path.join(cls.root_dir, "MeloraApp", "MeloraApp.swift")
        cls.project_yml_path = os.path.join(cls.root_dir, "project.yml")
        cls.project_pbxproj_path = os.path.join(cls.root_dir, "Melora.xcodeproj", "project.pbxproj")
        cls.scheme_path = os.path.join(cls.root_dir, "Melora.xcodeproj", "xcshareddata", "xcschemes", "MeloraApp.xcscheme")
        cls.ci_workflow_path = os.path.join(cls.root_dir, ".github", "workflows", "ios-ci.yml")
        cls.swiftlint_path = os.path.join(cls.root_dir, ".swiftlint.yml")

    def test_info_plist_configuration(self):
        """Validate Info.plist keys, bundle ID, background audio, and URL scheme."""
        self.assertTrue(os.path.exists(self.info_plist_path), "Info.plist must exist")
        with open(self.info_plist_path, "rb") as f:
            plist = plistlib.load(f)

        # Bundle Identifier
        self.assertEqual(plist.get("CFBundleIdentifier"), "com.melora.music")
        self.assertEqual(plist.get("CFBundleName"), "Melora")
        self.assertEqual(plist.get("CFBundlePackageType"), "APPL")
        self.assertEqual(plist.get("CFBundleShortVersionString"), "1.0.0")

        # Background Audio capability
        bg_modes = plist.get("UIBackgroundModes", [])
        self.assertIn("audio", bg_modes, "UIBackgroundModes must declare 'audio' for background playback")

        # Document sharing & local file ingestion
        self.assertTrue(plist.get("UIFileSharingEnabled"), "UIFileSharingEnabled must be true")
        self.assertTrue(plist.get("LSSupportsOpeningDocumentsInPlace"), "LSSupportsOpeningDocumentsInPlace must be true")

        # URL Scheme for Spotify OAuth callback
        url_types = plist.get("CFBundleURLTypes", [])
        self.assertTrue(len(url_types) > 0, "CFBundleURLTypes must be present")
        schemes = []
        for ut in url_types:
            schemes.extend(ut.get("CFBundleURLSchemes", []))
        self.assertIn("melora", schemes, "URL scheme 'melora' must be registered for OAuth callbacks")

    def test_swift_packages_deployment_target_and_tools_version(self):
        """Verify all Swift packages declare Swift 6.0 and iOS 18+ deployment target."""
        packages = ["MeloraCore", "MeloraData", "MeloraAudio", "MeloraUI"]
        for pkg in packages:
            manifest_path = os.path.join(self.root_dir, pkg, "Package.swift")
            self.assertTrue(os.path.exists(manifest_path), f"Package.swift for {pkg} must exist")
            with open(manifest_path, "r", encoding="utf-8") as f:
                content = f.read()

            self.assertIn("swift-tools-version: 6.0", content, f"{pkg} must specify swift-tools-version: 6.0")
            self.assertIn(".iOS(.v18)", content, f"{pkg} must specify .iOS(.v18)")

    def test_melora_app_entry_point(self):
        """Verify MeloraApp.swift provides @main entry point with full coordinator wiring."""
        self.assertTrue(os.path.exists(self.melora_app_path), "MeloraApp.swift must exist")
        with open(self.melora_app_path, "r", encoding="utf-8") as f:
            code = f.read()

        self.assertIn("@main", code, "Entry point must declare @main")
        self.assertIn("struct MeloraApp: App", code, "Must declare struct MeloraApp conforming to App")
        self.assertIn("SQLiteDatabase", code, "Must initialize SQLiteDatabase")
        self.assertIn("AudioPlaybackCoordinator", code, "Must initialize AudioPlaybackCoordinator")
        self.assertIn("SpotifyService", code, "Must initialize SpotifyService")
        self.assertIn("PlayerViewModel", code, "Must initialize PlayerViewModel")
        self.assertIn(".onOpenURL", code, "Must register onOpenURL for OAuth deep links")

    def test_xcode_project_and_project_yml(self):
        """Verify Xcode project files, deployment target, Swift 6, and local package dependencies."""
        self.assertTrue(os.path.exists(self.project_yml_path), "project.yml must exist")
        self.assertTrue(os.path.exists(self.project_pbxproj_path), "project.pbxproj must exist")
        self.assertTrue(os.path.exists(self.scheme_path), "MeloraApp.xcscheme must exist")

        with open(self.project_pbxproj_path, "r", encoding="utf-8") as f:
            pbxproj = f.read()

        self.assertIn("IPHONEOS_DEPLOYMENT_TARGET = 18.0;", pbxproj)
        self.assertIn("SWIFT_VERSION = 6.0;", pbxproj)
        self.assertIn("PRODUCT_BUNDLE_IDENTIFIER = com.melora.music;", pbxproj)
        self.assertIn("MeloraCore", pbxproj)
        self.assertIn("MeloraData", pbxproj)
        self.assertIn("MeloraAudio", pbxproj)
        self.assertIn("MeloraUI", pbxproj)

    def test_ci_workflow_and_swiftlint(self):
        """Verify GitHub Actions CI workflow and SwiftLint configuration exist and are configured."""
        self.assertTrue(os.path.exists(self.ci_workflow_path), "ios-ci.yml must exist")
        self.assertTrue(os.path.exists(self.swiftlint_path), ".swiftlint.yml must exist")

        with open(self.ci_workflow_path, "r", encoding="utf-8") as f:
            ci = f.read()

        self.assertIn("macos-15", ci, "Workflow must use macos-15 runner")
        self.assertIn("Xcode_16", ci, "Workflow must select Xcode 16")
        self.assertIn("swift test", ci, "Workflow must execute swift test")
        self.assertIn("xcodebuild", ci, "Workflow must run xcodebuild for simulator")
        self.assertIn("actions/upload-artifact@v4", ci, "Workflow must upload build logs and artifacts")

    def test_codemagic_configuration(self):
        """Verify codemagic.yaml exists, specifies M2 runner, Xcode 16, and unsigned release build."""
        codemagic_path = os.path.join(self.root_dir, "codemagic.yaml")
        self.assertTrue(os.path.exists(codemagic_path), "codemagic.yaml must exist in repository root")

        with open(codemagic_path, "r", encoding="utf-8") as f:
            cm = f.read()

        self.assertIn("workflows:", cm)
        self.assertIn("mac_mini_m2", cm, "Codemagic must use supported M2 runner")
        self.assertIn("xcode: 16.0", cm, "Must specify Xcode 16.0")
        self.assertIn("Melora.xcodeproj", cm, "Must target Melora.xcodeproj")
        self.assertIn("MeloraApp", cm, "Must target MeloraApp scheme")
        self.assertIn("CODE_SIGNING_ALLOWED=NO", cm, "Code signing must be disabled for initial test")
        self.assertIn("MeloraCore", cm)
        self.assertIn("MeloraData", cm)
        self.assertIn("MeloraAudio", cm)
        self.assertIn("MeloraUI", cm)
        self.assertIn("artifacts:", cm)
        self.assertIn("Melora-iOS-unsigned.app.zip", cm, "Artifact must be clearly designated as unsigned app")

if __name__ == "__main__":
    unittest.main()
