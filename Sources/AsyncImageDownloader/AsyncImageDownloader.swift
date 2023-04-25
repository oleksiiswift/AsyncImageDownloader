import Foundation
import UIKit

private enum CacheHandler {
	case progress(Task<URL?, Error>)
	case complete(URL)
	case failed(Error)
}

public enum FileFormat: String {
	case jpeg = "jpeg"
	case png = "png"
	case gif = "gif"
	case bmp = "bmp"
	case heic = "HEIC"
}

class AsyncImageDownloader {
	
	private var cache: [String: CacheHandler] = [:]
	private var cacheManager = CacheManager()
		
	private func cacheImage(_ tempURL: URL?, id key: String) {
		if let url = tempURL {
			self.cache[key] = .complete(url)
		}
	}
	
	private func getCachedImage(from url: URL?) async throws -> UIImage? {
		
		guard let url else { return nil }
		
		let data = try Data(contentsOf: url)
		return UIImage(data: data)
	}
}

extension AsyncImageDownloader {
	
	public func getImage(from url: URL?, with id: String, format: FileFormat) async throws -> UIImage {
		
		if let handler = cache[id] {
			switch handler {
					
				case .progress(let task):
					let url = try await task.value
					if let image = try await self.getCachedImage(from: url) {
						return image
					}
				case .complete(let url):
					if let image = try await getCachedImage(from: url) {
						return image
					}
				case .failed(let error):
					throw error
			}
		}
		
		let task: Task<URL?, Error> = Task.detached {
			guard let url else { throw ErrorDownloadHandler.LoadError.urlError }
			
			return try await self.downloadImage(from: url, id: id, format: format)
		}
		
		cache[id] = .progress(task)
		
		do {
			let result = try await task.value
			self.cacheImage(result, id: id)
			return try await self.getImage(from: result, with: id, format: format)
		} catch {
			self.cache[id] = .failed(error)
			throw error
		}
	}
}

extension AsyncImageDownloader {
	
	private func downloadImage(from url: URL, id: String, format: FileFormat) async throws -> URL? {
		
		let (cached, cachedUrl) = self.cacheManager.isFileCached(with: id, of: format)
		
		if cached, let cachedUrl {
			return cachedUrl
		}
		
		let (sorceURL, responce) = try await URLSession.shared.download(from: url)
		
		guard let httpResponce = responce as? HTTPURLResponse, (200..<400).contains(httpResponce.statusCode) else {
			throw ErrorDownloadHandler.NetworkError.statusCodeError
		}
		
		return self.cacheManager.movePrecachedFile(from: sorceURL, with: id, of: format)
	}
}

extension AsyncImageDownloader {
	
	public func batchDownloadImages(from urls: [String: URL?], format: FileFormat) async throws -> [String: URL?] {
		
		try await withThrowingTaskGroup(of: (String, URL?).self) { group in
			
			urls.forEach { key, value in
				group.addTask {
					if let url = value {
						let imageCachedURL = try await self.downloadImage(from: url, id: key, format: format)
						return (key, imageCachedURL)
					} else {
						return (key, nil)
					}
				}
			}
			
			var images = [String: URL?]()
			for try await (id, url) in group {
				images[id] = url
			}
			return images
		}
	}
}
