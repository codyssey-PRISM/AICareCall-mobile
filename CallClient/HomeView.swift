//
//  HomeView.swift
//  CallClient
//
//  Created by seungwooKim on 11/10/25.
//

import SwiftUI

struct HomeView: View {
    let onTestCall: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("AI Call Demo")
                    .font(.largeTitle.bold())

                Text("아래 버튼을 눌러 AI와 테스트 통화를 시작해보세요.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                Button {
                    onTestCall()
                } label: {
                    Text("AI 테스트 통화 시작")
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("홈")
        }
    }
}
