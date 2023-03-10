//
//  FeaturesView.swift
//  Life@USTC (iOS)
//
//  Created by TiankaiMa on 2022/12/17.
//

import Reeeed
import SwiftUI

struct FeatureLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 10) {
            configuration.icon
                .font(.title)
                .symbolRenderingMode(.hierarchical)
            configuration.title
                .lineLimit(2)
                .font(.caption)
        }
        .frame(width: 110, height: 110)
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        }
    }
}

struct FeaturesView: View {
    private enum Style: String, CaseIterable {
        case list
        case grid

        var imageName: String {
            switch self {
            case .list:
                return "list.bullet.below.rectangle"
            case .grid:
                return "square.grid.2x2"
            }
        }
    }

    @State var searchText = ""
    @AppStorage("featureViewStyle") private var style: Style = .grid

    let gridItemLayout = [GridItem(.adaptive(minimum: 110)),
                          GridItem(.adaptive(minimum: 110)),
                          GridItem(.adaptive(minimum: 110))]

    var ustcFeatures: [String: [FeatureWithView]] {
        var results: [String: [FeatureWithView]] = [:]

        var tmp: [FeatureWithView] = []
        tmp.append(.init(image: "doc.richtext", title: "Feed".localized, subTitle: "", destinationView: AllSourceView()))
        for feedSource in FeedSource.allToShow {
            tmp.append(.init(feedSource))
        }
        results["Feed"] = tmp

        tmp = [.init(image: "doc.text.magnifyingglass", title: "Classroom Status".localized, subTitle: "", destinationView: ClassroomView())]
        results["Public"] = tmp

        tmp = [.init(image: "book", title: "Curriculum".localized, subTitle: "", destinationView: CurriculumView()),
               .init(image: "calendar.badge.clock", title: "Exam".localized, subTitle: "", destinationView: ExamView()),
               .init(image: "graduationcap", title: "Score".localized, subTitle: "", destinationView: ScoreView())]
        results["UG AAS"] = tmp

        tmp = []
        for ustcWebFeature in FeaturesView.ustcWebFeatures {
            tmp.append(.init(ustcWebFeature))
        }
        results["Web"] = tmp

        return results
    }

    var ustcWebFeaturesSearched: [String: [FeatureWithView]] {
        if searchText.isEmpty {
            return ustcFeatures
        } else {
            var result: [String: [FeatureWithView]] = [:]
            for (key, value) in ustcFeatures {
                let tmp = value.filter {
                    $0.title.lowercased().contains(searchText.lowercased()) ||
                        $0.subTitle.lowercased().contains(searchText.lowercased()) ||
                        $0.title.localized.contains(searchText) ||
                        $0.subTitle.localized.contains(searchText)
                }
                if !tmp.isEmpty {
                    result[key] = tmp
                }
            }
            return result
        }
    }

    var gridView: some View {
        ScrollView(showsIndicators: false) {
            ForEach(ustcWebFeaturesSearched.sorted(by: { $0.value.count < $1.value.count }), id: \.key) { key, features in
                Text(key.localized)
                    .font(.title2)
                    .fontWeight(.medium)
                    .hStackLeading()
                LazyVGrid(columns: gridItemLayout) {
                    ForEach(features, id: \.self) { feature in
                        NavigationLinkAddon {
                            feature.destinationView
                        } label: {
                            Label(feature.title.localized, systemImage: feature.image)
                                .labelStyle(FeatureLabelStyle())
                        }
                    }
                }
            }
            .padding()
        }
    }

    var mainView: some View {
        List {
            ForEach(ustcWebFeaturesSearched.sorted(by: { $0.value.count < $1.value.count }), id: \.key) { key, features in
                Section {
                    ForEach(features, id: \.self) { feature in
                        NavigationLinkAddon {
                            feature.destinationView
                        } label: {
                            Label(feature.title.localized, systemImage: feature.image)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                } header: {
                    Text(key.localized)
                }
            }
        }
        .scrollIndicators(.hidden)
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
    }

    var body: some View {
        Group {
            switch style {
            case .grid:
                gridView
            case .list:
                mainView
            }
        }
        .navigationTitle("Features")
        .toolbar {
            Button {
                withAnimation {
                    style = style.next()
                }
            } label: {
                Label("Switch", systemImage: style.next().imageName)
            }
        }
#if os(iOS)
        .searchable(text: $searchText, placement: .automatic)
#endif
    }
}

extension FeaturesView {
    struct FeatureWithView: Identifiable, Hashable {
        static func == (lhs: FeaturesView.FeatureWithView, rhs: FeaturesView.FeatureWithView) -> Bool {
            lhs.id == rhs.id
        }

        var id = UUID()
        var image: String
        var title: String
        var subTitle: String
        var destinationView: AnyView

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        init(image: String, title: String, subTitle: String, destinationView: any View) {
            self.image = image
            self.title = title
            self.subTitle = subTitle
            self.destinationView = .init(destinationView)
        }

        init(_ feedSource: FeedSource) {
            image = feedSource.image ?? "doc.richtext"
            title = feedSource.name
            subTitle = feedSource.description ?? ""
            destinationView = .init(FeedSourceView(feedSource: feedSource))
        }

        init(_ ustcWebFeature: USTCWebFeature) {
            image = ustcWebFeature.image
            title = ustcWebFeature.name
            subTitle = ustcWebFeature.description
            destinationView = .init(Browser(url: ustcWebFeature.url, title: ustcWebFeature.name))
        }
    }

    struct USTCWebFeature: Identifiable {
        var id = UUID()
        var name: String
        var image: String
        var description: String
        var url: URL

        init(id: UUID = UUID(), name: String, image: String, description: String, url: URL) {
            self.id = id
            self.name = name
            self.image = image
            self.description = description
            self.url = url
        }

        init(id: UUID = UUID(), name: String, image: String, description: String, url: String, markUp: Bool = false) {
            self.id = id
            self.name = name
            self.image = image
            self.description = description
            if markUp {
                self.url = URL(string: url)!.ustcCASLoginMarkup()
            } else {
                self.url = URL(string: url)!
            }
        }
    }

    static let ustcWebFeatures: [USTCWebFeature] =
        [.init(name: "????????????(??????)",
               image: "person.2",
               description: "?????????????????????",
               url: "https://jw.ustc.edu.cn/ucas-sso/login",
               markUp: true),
         .init(name: "????????????",
               image: "doc.text.magnifyingglass",
               description: "????????????????????????",
               url: "https://catalog.ustc.edu.cn/query/classroom"),
         .init(name: "???????????????",
               image: "globe.asia.australia",
               description: "??????/??????????????????????????????",
               url: "https://zczx.ustc.edu.cn/caslogin",
               markUp: true),
         .init(name: "????????????????????????",
               image: "chart.xyaxis.line",
               description: "??????/????????????????????????",
               url: "http://pems.ustc.edu.cn/index.php/web/login/loginCas.html",
               markUp: true),
         .init(name: "??????????????????",
               image: "clock.badge.checkmark",
               description: "?????????????????????/?????????????????????",
               url: "http://roombooking.cmet.ustc.edu.cn/api/cas/index",
               markUp: true),
         .init(name: "?????????",
               image: "creditcard",
               description: "???????????????????????????????????????",
               url: "https://ecard.ustc.edu.cn/caslogin",
               markUp: true),
         .init(name: "???????????????",
               image: "desktopcomputer",
               description: "???????????????????????????????????????",
               url: "https://xgyth.ustc.edu.cn/usp/index.aspx",
               markUp: true),
         .init(name: "???????????????",
               image: "books.vertical",
               description: "????????????????????????-??????????????????",
               url: "http://course.ustc.edu.cn/sso/ustc",
               markUp: true)]
}

struct FeaturesView_Previews: PreviewProvider {
    static var previews: some View {
        FeaturesView()
    }
}
