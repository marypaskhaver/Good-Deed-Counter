//
//  BarChartView.swift
//  Good Deed Counter
//
//  Created by Mary Paskhaver on 7/7/20.
//  Copyright © 2020 Nostaw. All rights reserved.
//

import UIKit

class BarChartView: UIView {
  
    // Where the graph will be located
    private let mainLayer: CALayer = CALayer()
    
    // Embed in scroll view in case size of graph exceeds screen bounds
    private let scrollView: UIScrollView = UIScrollView()

    // Adjust spacing and hardcoded vals
    // Vertical space between entries
    let space: CGFloat = 40.0
    
    let barHeight: CGFloat = 40.0
    let contentSpace: CGFloat = 30.0
    
    var entryTooBig: Bool = false
    var currentEntry: Int = 0
    // Generate graph when data is passed in
    var dataEntries: [BarEntry] = [] {
        
        didSet {
            mainLayer.sublayers?.forEach({ $0.removeFromSuperlayer() })
                  
            mainLayer.frame = CGRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height)

            var factor: Float = 3.0
            var index: Int = 0
            
            while index < dataEntries.count {
                currentEntry = index
                showEntry(index: index, entry: dataEntries[index], shrinkBarWidthByFactorOf: factor)
                
                while entryTooBig {
                    // Remove all entries from screen
                    mainLayer.sublayers?.forEach({ $0.removeFromSuperlayer() })

                    index = 0

                    factor += 0.2
                    showEntry(index: index, entry: dataEntries[index], shrinkBarWidthByFactorOf: factor)
                }
                
                index += 1
            }
            
            mainLayer.frame = CGRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        scrollView.layer.addSublayer(mainLayer)
        addSubview(scrollView)
    }
    
    override func layoutSubviews() {
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)

        scrollView.contentSize = CGSize(width: frame.size.width, height: (barHeight + space) * CGFloat(dataEntries.count) + contentSpace)
    }
    
    private func showEntry(index: Int, entry: BarEntry, shrinkBarWidthByFactorOf factor: Float) {
        let xPos: CGFloat = 30
        let yPos: CGFloat = space + CGFloat(index) * (barHeight + space)

        let titleBar = drawTitle(xPos: xPos, yPos: yPos + (barHeight / 4), title: entry.title)
        
        let progressBar = drawBar(xPos: xPos + titleBar.frame.width + contentSpace, yPos: yPos, width: calculateBarWidth(value: Float(entry.count), shrinkByFactorOf: factor), forEntry: entry)
        
        let text = drawTextValue(xPos: xPos + titleBar.frame.width + progressBar.frame.width + contentSpace, yPos: yPos + (barHeight / 4), textValue: "\(entry.count)")
        
        let entryWidth = xPos + (titleBar.frame.width + contentSpace) + (progressBar.frame.width + contentSpace) + (xPos + text.frame.width)
        
        entryTooBig = entryWidth > UIScreen.main.bounds.width ? true : false
    }
    
    // MARK: - Drawing CALayers
    private func drawTitle(xPos: CGFloat, yPos: CGFloat, title: String) -> CATextLayer {
        let textLayer = CATextLayer()
                        
        configureTextLayer(layer: textLayer)
        
        textLayer.string = title
        textLayer.frame = CGRect(x: xPos, y: yPos, width: textLayer.preferredFrameSize().width + 15, height: textLayer.preferredFrameSize().height)
    
        addAnimationToLayer(layer: textLayer)
        
        mainLayer.addSublayer(textLayer)

        return textLayer
    }
    
    private func drawBar(xPos: CGFloat, yPos: CGFloat, width: CGFloat, forEntry entry: BarEntry) -> CALayer {
        let barLayer = CALayer()
                
        barLayer.frame = CGRect(x: xPos, y: yPos, width: width, height: barHeight)
                        
        if let navBarColor = defaults.color(forKey: "navBarColor") {
            changeLayerToColorFromComponents(from: navBarColor, toLayer: barLayer)
        } else {
            changeLayerToColorFromComponents(from: CustomColors.defaultBlue, toLayer: barLayer)
        }
        
        addAnimationToLayer(layer: barLayer)

        mainLayer.addSublayer(barLayer)
    
        return barLayer
    }
    
    func changeLayerToColorFromComponents(from color: UIColor, toLayer layer: CALayer) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        layer.backgroundColor = UIColor(hue: h, saturation: s, brightness: b * 0.8, alpha: a).cgColor
    }
    
    private func drawTextValue(xPos: CGFloat, yPos: CGFloat, textValue: String) -> CATextLayer {
        let textLayer = CATextLayer()
                
        configureTextLayer(layer: textLayer)
        
        textLayer.string = textValue
        textLayer.frame = CGRect(x: xPos, y: yPos, width: textLayer.preferredFrameSize().width + 15, height: textLayer.preferredFrameSize().height)
        
        addAnimationToLayer(layer: textLayer)

        mainLayer.addSublayer(textLayer)
        
        return textLayer
    }
    
    private func calculateBarWidth(value: Float, shrinkByFactorOf factor: Float) -> CGFloat {
        let width = CGFloat(value / factor) * (mainLayer.frame.width - space)
        
        return abs(width)
    }
    
    // MARK: - Setting up CATextLayers
    func configureTextLayer(layer: CATextLayer) {
        layer.foregroundColor = (self.traitCollection.userInterfaceStyle == .dark) ? UIColor.white.cgColor : UIColor.black.cgColor
        setTextLayerAlignmentAndContentScale(forLayer: layer)
        setTextLayerFont(forLayer: layer)
    }
    
    func setTextLayerAlignmentAndContentScale(forLayer layer: CATextLayer) {
        layer.alignmentMode = CATextLayerAlignmentMode.center
        layer.contentsScale = UIScreen.main.scale
    }
    
    func setTextLayerFont(forLayer layer: CATextLayer) {
        layer.font = CTFontCreateWithName(UIFont.systemFont(ofSize: 22.0).fontName as CFString, 0, nil)
        layer.fontSize = 22
    }
    
    // MARK: - Animating CALayers
    func addAnimationToLayer(layer: CALayer) {
        layer.opacity = 0.0
        layer.add(Animations.getFadeInAnimationForCALayer(atIndex: currentEntry), forKey: "fadeIn")
    }
   
}
