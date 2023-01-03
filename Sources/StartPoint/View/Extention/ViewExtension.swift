//
//  View.swift
//  V2er
//
//  Created by Seth on 2020/6/25.
//  Copyright © 2020 lessmore.io. All rights reserved.
//

import SwiftUI
import Combine


public extension UIEdgeInsets {
  var edgeInset: EdgeInsets {
    return EdgeInsets(top: self.top, leading: self.left, bottom: self.bottom, trailing: self.right)
  }
}

public extension View {
  public func debug(_ force: Bool = false, _ color: Color = .green) -> some View {
    //        print(Mirror(reflecting: self).subjectType)
    return self.modifier(DebugModifier(force, color))
  }
}


struct DebugModifier: ViewModifier {
  private var force: Bool
  private var color: Color
  public init(_ force: Bool = true, _ color: Color) {
    self.force = force
    self.color = color
  }
  
  func body(content: Content) -> some View {
#if DEBUG
    if !isSimulator() && !force {
      content
    } else {
      content
        .border(color, width: 1)
    }
#else
    content
#endif
  }
}

public extension View {
  func navigatable() -> some View {
    self.modifier(NavigationViewModifier())
  }
}

struct NavigationViewModifier: ViewModifier {
  func body(content: Content) -> some View {
    NavigationView {
      content
    }
    .ignoresSafeArea(.container)
    .navigationBarHidden(true)
  }
}

struct RoundedEdgeModifier: ViewModifier {
  var width: CGFloat = 2
  var color: Color = .black
  var cornerRadius: CGFloat = 16.0
  
  init(radius: CGFloat, width: CGFloat, color: Color) {
    self.cornerRadius = radius
    self.width = width
    self.color = color
  }
  
  func body(content: Content) -> some View {
    if cornerRadius == -1 {
      content
        .clipShape(Circle())
        .padding(width)
        .overlay(Circle().stroke(color, lineWidth: width))
    } else {
      content
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(color, lineWidth: width)
            .padding(0)
        }
    }
  }
}


extension UINavigationController: UIGestureRecognizerDelegate {
  override open func viewDidLoad() {
    super.viewDidLoad()
    interactivePopGestureRecognizer?.delegate = self
  }
  
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return viewControllers.count > 1
  }
}


struct KeyboardResponsiveModifier: ViewModifier {
  @State private var offset: CGFloat = 0
  
  func body(content: Content) -> some View {
    content
      .padding(.bottom, offset)
      .onAppear {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notif in
          let value = notif.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
          let height = value.height
          let bottomInset = UIDevice.safeArea.bottom
          withAnimation {
            self.offset = height - (bottomInset)
          }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { notif in
          withAnimation {
            self.offset = 0
          }
        }
      }
  }
}

extension View {
  func keyboardAware() -> ModifiedContent<Self, KeyboardResponsiveModifier> {
    return modifier(KeyboardResponsiveModifier())
  }
}



struct SizePreferenceKey: PreferenceKey {
  static var defaultValue: CGSize = .zero
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

struct ClipCornerShape: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners
  
  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
    return Path(path.cgPath)
  }
}

public extension View {
  func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
    background{
      GeometryReader { geometryProxy in
        Color.clear
          .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
      }
    }
    .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
  }
  
  func greedyWidth(_ alignment: Alignment = .center) -> some View {
    frame(maxWidth: .infinity, alignment: alignment)
  }
  
  func greedyHeight(_ alignment: Alignment = .center) -> some View {
    frame(maxHeight: .infinity, alignment: alignment)
  }
  
  func greedyFrame(_ alignment: Alignment = .center) -> some View {
    frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
  }
  
  public func visualBlur(alpha: CGFloat = 1.0, bg: Color = .clear) -> some View {
    return self.background(VEBlur(bg: bg).opacity(alpha))
  }
  
  func forceClickable() -> some View {
    return self.background(Color.almostClear)
  }
  
  public func cornerBorder(radius: CGFloat = -1,
                           borderWidth: CGFloat = 0.8,
                           color: Color = Color.border) -> some View {
    self.modifier(RoundedEdgeModifier(radius: radius,
                                      width: borderWidth, color: color))
  }
  
  func clipCorner(_ radius: CGFloat, corners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]) -> some View {
    clipShape( ClipCornerShape(radius: radius, corners: corners) )
  }
  
  func hide(_ hide: Bool = true) -> some View {
    self.opacity(hide ? 0.0 : 1.0)
    //        return self.modifier(HideModifier(hide: hide, keepLayout: keepLayout))
  }
  func remove(_ remove: Bool = true) -> some View{
    self.modifier(HideModifier(remove: remove))
  }
  
  func divider(_ opacity: CGFloat = 1.0) -> some View {
    self.modifier(DividerModifier(opacity: opacity))
  }
}

struct HideModifier: ViewModifier {
  let remove: Bool
  
  @ViewBuilder
  func body(content: Content) -> some View {
    if !remove {
      content
    }
  }
}

struct DividerModifier: ViewModifier {
  let opacity: CGFloat
  
  func body(content: Content) -> some View {
    VStack(spacing: 0) {
      content
      Divider()
        .opacity(opacity)
    }
  }
}



public extension Divider {
  func light() -> some View {
    frame(height: 0.2)
  }
}

public enum Visibility: CaseIterable {
  case visible, // view is fully visible
       invisible, // view is hidden but takes up space
       gone // view is fully removed from the view hierarchy
}

public extension View {
  @ViewBuilder func visibility(_ visibility: Visibility) -> some View {
    if visibility != .gone {
      if visibility == .visible {
        self
      } else {
        hidden()
      }
    }
  }
  
  
  func hapticOnTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
    self.onTapGesture {
      let impact = UIImpactFeedbackGenerator(style: style)
      impact.impactOccurred()
    }
  }
}

//struct EmptyView: View {
//    var body: some View {
//        Color.clear.frame(width: 0, height: 0)
//    }
//}

public extension LocalizedStringKey {
  static let empty: LocalizedStringKey = ""
}

public extension View {
  func to<Destination: View>(if: Binding<Bool>? = nil, @ViewBuilder destination: () -> Destination) -> some View {
    self.modifier(NavigationLinkModifider(if: `if`, destination: destination()))
  }
}

struct NavigationLinkModifider<Destination: View>: ViewModifier {
  var `if`: Binding<Bool>?
  let destination: Destination
  
  func body(content: Content) -> some View {
    if `if` == nil {
      NavigationLink {
        destination
      } label: {
        content
      }
    } else {
      NavigationLink(destination: destination, isActive: `if`!) {
        EmptyView()
      }
    }
  }
}


public extension View {
  func withHostingWindow(_ callback: @escaping (UIWindow?) -> Void) -> some View {
    self.background(HostingWindowFinder(callback: callback))
  }
}

struct HostingWindowFinder: UIViewRepresentable {
  var callback: (UIWindow?) -> ()
  
  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    DispatchQueue.main.async { [weak view] in
      self.callback(view?.window)
    }
    return view
  }
  
  func updateUIView(_ uiView: UIView, context: Context) {
  }
}


public extension View {
  func foregroundLinearGradient(
    colors: [Color],
    startPoint: UnitPoint,
    endPoint: UnitPoint) -> some View
  {
    self.overlay {
      
      LinearGradient(
        colors: colors,
        startPoint: startPoint,
        endPoint: endPoint
      )
      .mask(
        self
        
      )
    }
  }
}

public extension View {
  func injectSample(_ store: GeneralState = .sample) -> some View {
    return self.environmentObject(store)
  }
}


extension Text {
  public func font(_ size: CGFloat = 17, weight: Font.Weight? = nil, design: Font.Design? = nil) -> Text {
    return self.font(.system(size: size, design: design ?? .default).weight(weight ?? .regular))
  }
}


// Our custom view modifier to track rotation and
// call our action
struct DeviceRotationViewModifier: ViewModifier {
  let action: (Bool) -> Void

  func body(content: Content) -> some View {
    content
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
        guard let scene = UIApplication.shared.currentScene else {
          log(tag: "onRotate", "guard let scene = UIApplication.shared.currentScene")
          return
        }
        var isPortrait = scene.interfaceOrientation.isPortrait
        let intMode: Int = Persist.read(key: Prefs.SCREEN_ORITATION_MODE)
        let screenMode: OritentionMode = OritentionMode.build(from: intMode)
        if screenMode != .auto {
          isPortrait = screenMode == .portrait
        }
        action(isPortrait)
      }
  }
}

// A View wrapper to make the modifier easier to use
public extension View {
  func onRotate(perform action: @escaping (Bool) -> Void) -> some View {
    self.modifier(DeviceRotationViewModifier(action: action))
  }
}

extension UIApplication {
  var currentScene: UIWindowScene? {
    connectedScenes
      .first { $0.activationState == .foregroundActive } as? UIWindowScene
  }
}
