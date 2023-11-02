//
//  TouchOverlay.swift
//  LineChart
//
//  Created by Will Dale on 29/12/2020.
//

import SwiftUI

#if !os(tvOS)
/**
 Finds the nearest data point and displays the relevent information.
 */
internal struct TouchOverlay<T>: ViewModifier where T: CTChartData {
    
    @ObservedObject private var chartData: T
    let minDistance: CGFloat
    private let specifier: String
    private let formatter: NumberFormatter?
    private let unit: TouchUnit
    
    internal init(
        chartData: T,
        specifier: String,
        formatter: NumberFormatter?,
        unit: TouchUnit,
        minDistance: CGFloat
    ) {
        self.chartData = chartData
        self.minDistance = minDistance
        self.specifier = specifier
        self.formatter = formatter
        self.unit = unit
    }
    
    internal func body(content: Content) -> some View {
        Group {
            if chartData.isGreaterThanTwo() {
                GeometryReader { geo in
                    ZStack {
                        Group {
                            if chartData is LineChartData {
                                content
                                    .gesture(
                                        DragGesture(minimumDistance: minDistance, coordinateSpace: .local)
                                            .onChanged { (value) in
                                                chartData.infoView.touchOverlayInfo = []
                                                chartData.setTouchInteraction(touchLocation: value.location,
                                                                              chartSize: geo.frame(in: .local))
                                                chartData.infoView.isTouchCurrent = true
                                            }
                                    )
                                if chartData.infoView.isTouchCurrent {
                                    chartData.getTouchInteraction(touchLocation: chartData.infoView.touchLocation,
                                                                  chartSize: geo.frame(in: .local))
                                }
                            }
                            else {
                                content
                                TappableView { location, taps in
                                    if taps == 1 {
                                        chartData.infoView.touchOverlayInfo = []
                                        chartData.setTouchInteraction(touchLocation: location,
                                                                      chartSize: geo.frame(in: .local))
                                    }
                                    
                                }
                                chartData.getTouchInteraction(touchLocation: chartData.infoView.touchLocation,
                                                              chartSize: geo.frame(in: .local))
                            }
                        }
                    }
                }
            } else { content }
        }
        .onAppear {
            self.chartData.infoView.touchSpecifier = specifier
            self.chartData.infoView.touchFormatter = formatter
            self.chartData.infoView.touchUnit = unit
        }
    }
}
#endif

extension View {
#if !os(tvOS)
    /**
     Adds touch interaction with the chart.
     
     Adds an overlay to detect touch and display the relivent information from the nearest data point.
     
     - Requires:
     If  ChartStyle --> infoBoxPlacement is set to .header
     then `.headerBox` is required.
     
     If  ChartStyle --> infoBoxPlacement is set to .infoBox
     then `.infoBox` is required.
     
     If  ChartStyle --> infoBoxPlacement is set to .floating
     then `.floatingInfoBox` is required.
     
     - Attention:
     Unavailable in tvOS
     
     - Parameters:
     - chartData: Chart data model.
     - specifier: Decimal precision for labels.
     - unit: Unit to put before or after the value.
     - minDistance: The distance that the touch event needs to travel to register.
     - Returns: A  new view containing the chart with a touch overlay.
     */
    public func touchOverlay<T: CTChartData>(
        chartData: T,
        specifier: String = "%.0f",
        formatter: NumberFormatter? = nil,
        unit: TouchUnit = .none,
        minDistance: CGFloat = 0
    ) -> some View {
        self.modifier(TouchOverlay(chartData: chartData,
                                   specifier: specifier,
                                   formatter: formatter,
                                   unit: unit,
                                   minDistance: minDistance))
    }
#elseif os(tvOS)
    /**
     Adds touch interaction with the chart.
     
     - Attention:
     Unavailable in tvOS
     */
    public func touchOverlay<T: CTChartData>(
        chartData: T,
        specifier: String = "%.0f",
        formatter: NumberFormatter? = nil,
        unit: TouchUnit = .none,
        minDistance: CGFloat = 0
    ) -> some View {
        self.modifier(EmptyModifier())
    }
#endif
}

struct TappableView:UIViewRepresentable {
    var tappedCallback: ((CGPoint, Int) -> Void)
    
    func makeUIView(context: UIViewRepresentableContext<TappableView>) -> UIView {
        let v = UIView(frame: .zero)
        let gesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped))
        gesture.numberOfTapsRequired = 1
        v.addGestureRecognizer(gesture)
        return v
    }
    
    class Coordinator: NSObject {
        var tappedCallback: ((CGPoint, Int) -> Void)
        init(tappedCallback: @escaping ((CGPoint, Int) -> Void)) {
            self.tappedCallback = tappedCallback
        }
        @objc func tapped(gesture:UITapGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            self.tappedCallback(point, 1)
        }
    }
    
    func makeCoordinator() -> TappableView.Coordinator {
        return Coordinator(tappedCallback:self.tappedCallback)
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<TappableView>) {
    }
    
}
