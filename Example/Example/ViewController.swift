//
//  ViewController.swift
//  Example
//
//  Created by Heberti Almeida on 08/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import FolioReaderKit

enum Epub: Int {
	case bookOne = 0
	case bookTwo

	var name: String {
		switch self {
		case .bookOne: return "The Silver Chair" // standard eBook
		case .bookTwo: return "The Adventures Of Sherlock Holmes - Adventure I" // audio-eBook
		}
	}

	var shouldHideNavigationOnTap: Bool {
		switch self {
		case .bookOne: return false
		case .bookTwo: return true
		}
	}

	var scrollDirection: FolioReaderScrollDirection {
		switch self {
		case .bookOne: return .vertical
		case .bookTwo: return .horizontal
		}
	}

	var bookPath: String? {
		return Bundle.main.path(forResource: self.name, ofType: "epub")
	}

	func retain(folioReaderContainer: FolioReaderContainer) {
		let appDelegate = (UIApplication.shared.delegate as? AppDelegate)

		switch self {
		case .bookOne: appDelegate?.standardEpub = folioReaderContainer
		case .bookTwo: appDelegate?.audioEpub = folioReaderContainer
		}
	}
}

class ViewController		: UIViewController {

    @IBOutlet var bookOne	: UIButton?
    @IBOutlet var bookTwo	: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()

		self.bookOne?.tag = Epub.bookOne.rawValue
		self.bookTwo?.tag = Epub.bookTwo.rawValue

        self.setCover(self.bookOne, index: 0)
        self.setCover(self.bookTwo, index: 1)
    }

	private func readerConfiguration(forEpub epub: Epub) -> FolioReaderConfig {

		let config = FolioReaderConfig()
		config.shouldHideNavigationOnTap = epub.shouldHideNavigationOnTap
		config.scrollDirection = epub.scrollDirection

		// See more at FolioReaderConfig.swift
		//        config.canChangeScrollDirection = false
		//        config.enableTTS = false
		//        config.allowSharing = false
		//        config.tintColor = UIColor.blueColor()
		//        config.toolBarTintColor = UIColor.redColor()
		//        config.toolBarBackgroundColor = UIColor.purpleColor()
		//        config.menuTextColor = UIColor.brownColor()
		//        config.menuBackgroundColor = UIColor.lightGrayColor()
		//        config.hidePageIndicator = true
		//        config.realmConfiguration = Realm.Configuration(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("highlights.realm"))

		// Custom sharing quote background
		config.quoteCustomBackgrounds = []
		if let image = UIImage(named: "demo-bg") {
			let customImageQuote = QuoteImage(withImage: image, alpha: 0.6, backgroundColor: UIColor.black)
			config.quoteCustomBackgrounds.append(customImageQuote)
		}

		let textColor = UIColor(red:0.86, green:0.73, blue:0.70, alpha:1.0)
		let customColor = UIColor(red:0.30, green:0.26, blue:0.20, alpha:1.0)
		let customQuote = QuoteImage(withColor: customColor, alpha: 1.0, textColor: textColor)
		config.quoteCustomBackgrounds.append(customQuote)

		return config
	}

    fileprivate func open(epub: Epub) {

		guard let bookPath = epub.bookPath else {
			return
		}

		let readerConfiguration = self.readerConfiguration(forEpub: epub)
        let folioReaderContainer = FolioReader.presentReader(parentViewController: self, withEpubPath: bookPath, andConfig: readerConfiguration, shouldRemoveEpub: false)

		epub.retain(folioReaderContainer: folioReaderContainer)
    }

    private func setCover(_ button: UIButton?, index: Int) {
		guard
			let epub = Epub(rawValue: index),
			let bookPath = epub.bookPath,
			let image = FolioReader.getCoverImage(bookPath) else {
				return
		}

		button?.setBackgroundImage(image, for: .normal)
    }
}

// MARK: - IBAction

extension ViewController {

	@IBAction func didOpen(_ sender: AnyObject) {
		guard let epub = Epub(rawValue: sender.tag) else {
			return
		}

		self.open(epub: epub)
	}
}
