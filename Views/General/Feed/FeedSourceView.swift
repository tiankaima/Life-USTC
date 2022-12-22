//
//  FeedSourceView.swift
//  Life@USTC (iOS)
//
//  Created by TiankaiMa on 2022/12/22.
//

import SwiftUI

struct FeedSourceView: View {
    let feedSource: any FeedSource
    @State var posts: [FeedPost] = []
    @State var status: AsyncViewStatus = .inProgress
    
    var body: some View {
        NavigationStack {
            PostListPage(name: LocalizedStringKey(feedSource.name), posts: $posts, status: $status)
                .navigationTitle(feedSource.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            status = .inProgress
                            feedSource.forceUpdatePost(posts: $posts, status: $status)
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                }
        }
        .onAppear {
            feedSource.fetchRecentPost(posts: $posts, status: $status)
        }
    }
}

struct AllSourceView: View {
    @State var posts: [FeedPost] = []
    @State var status: AsyncViewStatus = .inProgress
    
    var body: some View {
        NavigationStack {
            PostListPage(name: "All", posts: $posts, status: $status)
                .navigationTitle("All")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            status = .inProgress
                            showUserFeedPost(number: nil, posts: $posts, status: $status)
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                }
        }
        .onAppear {
            showUserFeedPost(number: nil, posts: $posts, status: $status)
        }
    }
}