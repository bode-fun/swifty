import ArgumentParser
import Foundation

@main
struct Swifty: ParsableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "swifty",
      abstract: "A swifty visual studio code extension manager",
      subcommands: [
        Install.self,
        Dump.self,
      ],
      defaultSubcommand: Dump.self
    )
  }
}

extension Swifty {
  struct Install: ParsableCommand {
    static var configuration: CommandConfiguration {
      CommandConfiguration(
        commandName: "install",
        abstract: "Install VSCode extensions from a json file"
      )
    }

    @Argument(help: "The path to the toml file")
    var path: String = "extensions.json"

    func run() throws {
      print("Installing extensions from \(path)")
    }
  }
}

extension Swifty {
  struct Dump: ParsableCommand {
    static var configuration: CommandConfiguration {
      CommandConfiguration(
        commandName: "dump",
        abstract: "Dump the installed extensions to a json file"
      )
    }

    func run()  {
      let codeProcess = Process()
      codeProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
      codeProcess.arguments = ["code", "--list-extensions"]

      let pipe = Pipe()
      codeProcess.standardOutput = pipe

      try codeProcess.run()

      codeProcess.waitUntilExit()

      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: data, encoding: .utf8)

      let separator = "\n"

      // TODO: Test if this works because idk
      #if os(Windows)
        separator = "\r\n"
      #endif

      let installedExtensions = output?.split(separator: "\n").map { String($0) } ?? []
      let installedVscExtensions = installedExtensions.map { VscExtension(name: $0) }
      
      let jsonEncoder = JSONEncoder()

      #if DEBUG
        jsonEncoder.outputFormatting = .prettyPrinted
      #endif

      let jsonData = try jsonEncoder.encode(InstalledExtensions(extensions: installedVscExtensions))

      let file = FileManager.default
      let currentDir = file.currentDirectoryPath
      let path = "\(currentDir)/extensions.json"
      file.createFile(atPath: path, contents: jsonData)
    }
  }
}

struct InstalledExtensions: Codable {
  let extensions: [VscExtension]
}

struct VscExtension : Codable {
  let name: String
}