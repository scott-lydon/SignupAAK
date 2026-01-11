//
//  OfflineBanner.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/9/26.
//

import Foundation
import SwiftUI

struct OfflineBannerView: View {
    
    var body: some View {
        Text("No Internet Connection")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .accessibilityLabel("No Internet Connection")
    }
}
