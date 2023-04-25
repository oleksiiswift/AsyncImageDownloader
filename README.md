# AsyncImageDownloader

A simple Testing Package to dowload images

How to use:

			Task {
				let image = try await AsyncImageDownloader().getImage(from: url, with: id, format: .jpeg)
			
				await MainActor.run {
					// use image, update ui
				}
			}
