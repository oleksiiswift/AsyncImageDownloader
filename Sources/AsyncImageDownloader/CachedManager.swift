import Foundation
import UIKit

enum Directory: String {
	case cache = "ChacheImageDirectory"
	case temp = "tmp"
}

class CacheManager {

	public func getCachedImage(with id: String, of format: FileFormat) -> UIImage? {
		
		let (cached, url) = self.isFileCached(with: id, of: format)
		
		if cached, let url {
			do {
				let data = try Data(contentsOf: url)
				return UIImage(data: data)
			} catch {
				debugPrint(error.localizedDescription)
			}
		}
		return nil
	}
	
	public func movePrecachedFile(from source: URL, with name: String, of format: FileFormat) -> URL? {
		
		let fileURL = self.generateCachedURL(id: name, format: format)
		
		do {
			if self.fileExists(atPath: fileURL) {
				return fileURL
			}
			try FileManager.default.moveItem(at: source, to: fileURL)
		} catch {
			debugPrint(error.localizedDescription)
		}
		return nil
	}
	
	private func generateCachedURL(id: String, format: FileFormat) -> URL {
		let cachedDirectory = self.getDirectoryURL(of: .cache)
		let url = URL(fileURLWithPath: cachedDirectory.path).appendingPathComponent(id).appendingPathExtension(format.rawValue)
		return url
	}
}

extension CacheManager {
	
	private func removeCacheFile(with id: String, of format: FileFormat) {
		
		let (cached, url) = self.isFileCached(with: id, of: format)
		
		if cached, let url {
			do {
				try FileManager.default.removeItem(at: url)
			} catch {
				debugPrint(error.localizedDescription)
			}
		}
	}
	
	public func isFileCached(with id: String, of format: FileFormat) -> (Bool, URL?) {
		let url = self.generateCachedURL(id: id, format: format)
		return fileExists(atPath: url) ? (true, url) : (false, nil)
	}
	
	public func clearDirectory(of type: Directory) {
		let url = self.getDirectoryURL(of: type)
		self.clearDirectory(at: url)
	}
}

extension CacheManager {
	
	private func fileExists(atPath: URL) -> Bool {
		return FileManager.default.fileExists(atPath: atPath.path)
	}
	
	private func clearDirectory(at url: URL?) {
		
		guard let url = url else { return }
		
		do {
			let cacheURLS = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
			try cacheURLS.forEach {
				try FileManager.default.removeItem(at: $0)
			}
		} catch  {
			debugPrint(error.localizedDescription)
		}
	}
	
	private func getDirectoryURL(of type: Directory) -> URL {
		
		var url: URL {
			switch type {
				case .temp:
					return FileManager.default.temporaryDirectory
				default:
					return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent(type.rawValue)
			}
		}
		
		var isDirectory: ObjCBool = true
		
		if !FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
			
			do {
				try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: false, attributes: nil)
				return url
			} catch {
				debugPrint(error)
			}
		}
		return url
	}
}

