import Foundation

public enum ErrorDownloadHandler {
	
	enum NetworkError: Error {
		case statusCodeError
	}

	enum LoadError: Error {
		case urlError
		case cacheId
		case error
	}
}
