import SwiftUI
import CloudKit
import CryptoKit

actor ImageCache {
    static let shared = ImageCache()
    
    private var memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 50
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        return cache
    }()
    
    private let diskCacheURL: URL? = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ImageCache", isDirectory: true)
    }()
    
    private let maxDiskCacheSize: Int = 100 * 1024 * 1024 // 100 MB
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    init() {
        Self.createDiskCacheDirectoryIfNeeded(at: diskCacheURL)
        Task { await cleanupDiskCacheIfNeeded() }
    }
    
    private nonisolated static func createDiskCacheDirectoryIfNeeded(at url: URL?) {
        guard let url else { return }
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
    
    private func cacheKey(for url: URL) -> String {
        let data = Data(url.absoluteString.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func image(for url: URL) async -> UIImage? {
        let key = cacheKey(for: url)
        
        // Check memory cache first
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }
        
        // Check disk cache
        if let diskImage = await loadFromDisk(key: key) {
            let cost = diskImage.jpegData(compressionQuality: 1.0)?.count ?? 0
            memoryCache.setObject(diskImage, forKey: key as NSString, cost: cost)
            return diskImage
        }
        
        return nil
    }
    
    func setImage(_ image: UIImage, for url: URL) async {
        let key = cacheKey(for: url)
        let cost = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        
        // Save to memory cache
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
        
        // Save to disk cache
        await saveToDisk(image: image, key: key)
    }
    
    private func diskPath(for key: String) -> URL? {
        diskCacheURL?.appendingPathComponent(key).appendingPathExtension("jpg")
    }
    
    private func loadFromDisk(key: String) async -> UIImage? {
        guard let path = diskPath(for: key) else { return nil }
        
        return await Task.detached(priority: .utility) {
            guard FileManager.default.fileExists(atPath: path.path),
                  let data = try? Data(contentsOf: path),
                  let image = UIImage(data: data) else {
                return nil
            }
            
            // Update access date for LRU tracking
            try? FileManager.default.setAttributes(
                [.modificationDate: Date()],
                ofItemAtPath: path.path
            )
            
            return image
        }.value
    }
    
    private func saveToDisk(image: UIImage, key: String) async {
        guard let path = diskPath(for: key) else { return }
        
        await Task.detached(priority: .utility) {
            guard let data = image.jpegData(compressionQuality: 0.8) else { return }
            try? data.write(to: path, options: .atomic)
        }.value
    }
    
    func cleanupDiskCacheIfNeeded() async {
        guard let diskCacheURL else { return }
        
        await Task.detached(priority: .background) {
            let fileManager = FileManager.default
            guard let files = try? fileManager.contentsOfDirectory(
                at: diskCacheURL,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            ) else { return }
            
            let now = Date()
            var totalSize = 0
            var fileInfos: [(url: URL, date: Date, size: Int)] = []
            
            for fileURL in files {
                guard let attributes = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                      let date = attributes.contentModificationDate,
                      let size = attributes.fileSize else { continue }
                
                // Remove files older than maxCacheAge
                if now.timeIntervalSince(date) > self.maxCacheAge {
                    try? fileManager.removeItem(at: fileURL)
                    continue
                }
                
                totalSize += size
                fileInfos.append((fileURL, date, size))
            }
            
            // If still over size limit, remove oldest files (LRU)
            if totalSize > self.maxDiskCacheSize {
                let sorted = fileInfos.sorted { $0.date < $1.date }
                var currentSize = totalSize
                
                for file in sorted {
                    guard currentSize > self.maxDiskCacheSize else { break }
                    try? fileManager.removeItem(at: file.url)
                    currentSize -= file.size
                }
            }
        }.value
    }
    
    func clearCache() async {
        memoryCache.removeAllObjects()
        
        guard let diskCacheURL else { return }
        try? FileManager.default.removeItem(at: diskCacheURL)
        Self.createDiskCacheDirectoryIfNeeded(at: diskCacheURL)
    }
}

struct CachedAsyncImage: View {
    let asset: CKAsset?
    let contentMode: ContentMode
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    init(asset: CKAsset?, contentMode: ContentMode = .fill) {
        self.asset = asset
        self.contentMode = contentMode
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.subtleFill)
            } else {
                ZStack {
                    Color.sageGreen.opacity(0.1)
                    Image(systemName: "fork.knife")
                        .font(.largeTitle)
                        .foregroundColor(.sageGreen)
                }
                .accessibilityHidden(true)
            }
        }
        .task(id: asset?.fileURL) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let fileURL = asset?.fileURL else {
            isLoading = false
            return
        }
        
        // Check cache (memory + disk)
        if let cached = await ImageCache.shared.image(for: fileURL) {
            self.image = cached
            isLoading = false
            return
        }
        
        // Load from CKAsset file
        let loadedImage = await Task.detached(priority: .userInitiated) {
            guard let data = try? Data(contentsOf: fileURL),
                  let uiImage = UIImage(data: data) else {
                return nil as UIImage?
            }
            return uiImage
        }.value
        
        if let loadedImage {
            await ImageCache.shared.setImage(loadedImage, for: fileURL)
            self.image = loadedImage
        }
        isLoading = false
    }
}
