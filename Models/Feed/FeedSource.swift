//
//  FeedSource.swift
//  Life@USTC (iOS)
//
//  Created by TiankaiMa on 2022/12/22.
//

import FeedKit
import SwiftUI

private let importantLabels: Set<String> = ["!!important", "Important", "!!notice"]

class FeedSource {
    static var all: [FeedSource] = [FeedSource(url: ustcOAAFeedURL, name: "教务处", image: "person.crop.square.fill.and.at.rectangle"),
                                    FeedSource(url: ustcHomePageFeedURL, name: "校主页", image: "icloud.square.fill"),
                                    FeedSource(url: appFeedURL, name: "应用通知", image: "apps.iphone")]

    static var allToShow: [FeedSource] {
        let namesToRemove: [String] = .init(rawValue: UserDefaults().string(forKey: "feedSourceNameListToRemove") ?? "") ?? []

        var result = all
        for name in namesToRemove {
            result.removeAll(where: { $0.name == name })
        }
        return result
    }

    var url: URL
    var name: String
    var id: UUID
    var description: String?
    var image: String? // system image

    func fetchRecentPost() async throws -> [Feed] {
        let cache = FeedCache.feedSourceCache(using: id)
        if cache != nil, !cache!.feeds.isEmpty, cache!.lastUpdated.addingTimeInterval(7200) > Date() {
            return cache!.feeds
        }

        let data = try await forceUpdatePost()
        return data
    }

    func forceUpdatePost(loopCount: Int = 0) async throws -> [Feed] {
        do {
            print("!!! Refresh \(name) RSSFeedPost")
            let result = FeedParser(URL: url).parse()
            switch result {
            case let .success(fetch):
                if let feeds = fetch.rssFeed?.items?.map({ Feed(item: $0, source: self.name) }) {
                    FeedCache.update(using: id, with: feeds)
                    return feeds
                }
            case let .failure(error):
                throw error
            }
        } catch {}

        try await Task.sleep(for: .seconds(5))
        if loopCount < 10 {
            return try await forceUpdatePost(loopCount: loopCount + 1)
        } else {
            throw BaseError.runtimeError("Error when parsing posts")
        }
    }

    init(url: URL, name: String, id: UUID? = nil, description: String? = nil, image: String? = nil) {
        self.url = url
        self.name = name
        if let id {
            self.id = id
        } else {
            self.id = UUID(name: name, nameSpace: .oid)
        }
        self.description = description
        self.image = image
    }

    /// Return a given amount of Feed from cache, which should contain all posts
    static func recentFeeds(number: Int?) async throws -> [Feed] {
        var result: [Feed] = []
        var important: [Feed] = []
        for source in FeedSource.allToShow {
            let feeds = try await source.fetchRecentPost()
            for feed in feeds {
                if feed.keywords.isDisjoint(with: importantLabels) {
                    result.append(feed)
                } else {
                    important.append(feed)
                }
            }
        }

        result.sort(by: { $0.datePosted > $1.datePosted })
        important.sort(by: { $0.datePosted > $1.datePosted })
        result.insert(contentsOf: important, at: 0)

        if (number ?? 1) > result.count {
            for source in FeedSource.allToShow {
                _ = try await source.forceUpdatePost()
                return try await recentFeeds(number: number)
            }
        }

        if let number {
            return Array(result.prefix(number))
        } else {
            return result
        }
    }
}
