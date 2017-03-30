//
//  FolioReaderContainer.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 15/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import FontBlaster

/// Reader container
open class FolioReaderContainer		: UIViewController {

    var centerNavigationController	: UINavigationController?
	var centerViewController		: FolioReaderCenter?
    var audioPlayer					: FolioReaderAudioPlayer?
    var shouldHideStatusBar 		= true
    var shouldRemoveEpub 			= true
	// TODO_SMF: remove optional for book and epubPath
	var epubPath					: String?
	var book						: FRBook?
	var readerConfig				: FolioReaderConfig
	var folioReader					: FolioReader

    fileprivate var errorOnLoad 	= false

    // MARK: - Init
    
    /**
     Init a Container
     
     - parameter config:     A instance of `FolioReaderConfig`
     - parameter path:       The ePub path on system
     - parameter removeEpub: Should delete the original file after unzip? Default to `true` so the ePub will be unziped only once.
     
     - returns: `self`, initialized using the `FolioReaderConfig`.
     */
	public init(withConfig config: FolioReaderConfig, folioReader: FolioReader, epubPath path: String, removeEpub: Bool = true) {
		self.readerConfig = config
		self.folioReader = folioReader
        self.epubPath = path
        self.shouldRemoveEpub = removeEpub

		super.init(nibName: nil, bundle: Bundle.frameworkBundle())
		
		self.initialization()
    }
    
    required public init?(coder aDecoder: NSCoder) {
		// TODO_SMF_QUESTION: is that ok? do 'we' really support NSCoding?
		fatalError("This class doesn't support NSCoding.")
    }
    
    /**
     Common Initialization
     */
    fileprivate func initialization() {
        self.book = FRBook()
        
        // Register custom fonts
        FontBlaster.blast(bundle: Bundle.frameworkBundle())

        // Register initial defaults
        FolioReader.defaults.register(defaults: [
            kCurrentFontFamily: FolioReaderFont.andada.rawValue,
            kNightMode: false,
            kCurrentFontSize: 2,
            kCurrentAudioRate: 1,
            kCurrentHighlightStyle: 0,
            kCurrentTOCMenu: 0,
            kCurrentMediaOverlayStyle: MediaOverlayStyle.default.rawValue,
            kCurrentScrollDirection: FolioReaderScrollDirection.defaultVertical.rawValue
		])
    }
    
    /**
     Set the `FolioReaderConfig` and epubPath.
     
     - parameter config:     A instance of `FolioReaderConfig`
     - parameter path:       The ePub path on system
     - parameter removeEpub: Should delete the original file after unzip? Default to `true` so the ePub will be unziped only once.
     */
    open func setupConfig(_ config: FolioReaderConfig, folioReader: FolioReader, epubPath path: String, removeEpub: Bool = true) {
        self.readerConfig = config
		self.folioReader = folioReader
        self.epubPath = path
        self.shouldRemoveEpub = removeEpub
    }
    
    // MARK: - View life cicle
    
    override open func viewDidLoad() {
        super.viewDidLoad()

		let canChangeScrollDirection = self.readerConfig.canChangeScrollDirection
        self.readerConfig.canChangeScrollDirection = self.readerConfig.isDirection(canChangeScrollDirection, canChangeScrollDirection, false)
        
        // If user can change scroll direction use the last saved
        if (self.readerConfig.canChangeScrollDirection == true) {
            var scrollDirection = (FolioReaderScrollDirection(rawValue: self.folioReader.currentScrollDirection) ?? .vertical)

            if (scrollDirection == .defaultVertical && self.readerConfig.scrollDirection != .defaultVertical) {
                scrollDirection = self.readerConfig.scrollDirection
            }

            self.readerConfig.scrollDirection = scrollDirection
        }

		let hideBars = (self.readerConfig.hideBars ?? false)
		self.readerConfig.shouldHideNavigationOnTap = ((hideBars == true) ? true : self.readerConfig.shouldHideNavigationOnTap)

		self.centerViewController = FolioReaderCenter(withContainer: self)

		if let rootViewController = self.centerViewController {
			self.centerNavigationController = UINavigationController(rootViewController: rootViewController)
		}

        self.centerNavigationController?.setNavigationBarHidden(self.readerConfig.shouldHideNavigationOnTap, animated: false)
		if let _centerNavigationController = self.centerNavigationController {
        	self.view.addSubview(_centerNavigationController.view)
        	self.addChildViewController(_centerNavigationController)
		}
        self.centerNavigationController?.didMove(toParentViewController: self)

		if (self.readerConfig.hideBars == true) {
			self.readerConfig.shouldHideNavigationOnTap = false
			self.navigationController?.navigationBar.isHidden = true
			self.centerViewController?.pageIndicatorHeight = 0
		}

        // Read async book
        guard let epubPath = self.epubPath, (epubPath.isEmpty == false) else {
            print("Epub path is nil.")
            self.errorOnLoad = true
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {

			guard let parsedBook = FREpubParser().readEpub(epubPath: epubPath, removeEpub: self.shouldRemoveEpub) else {
				self.errorOnLoad = true
				return
			}

			self.book = parsedBook
            self.folioReader.isReaderOpen = true
            
            // Reload data
            DispatchQueue.main.async(execute: {
                
                // Add audio player if needed
                if (self.book?.hasAudio() == true || self.readerConfig.enableTTS == true) {
                    self.addAudioPlayer()
                }
                
                self.centerViewController?.reloadData()
                
                self.folioReader.isReaderReady = true

				guard let loadedBook = self.book else {
					return
				}

				self.folioReader.delegate?.folioReader?(self.folioReader, didFinishedLoading: loadedBook)
            })
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (self.errorOnLoad == true) {
            self.dismiss()
        }
    }
    
    /**
     Initialize the media player
     */
    func addAudioPlayer() {
        self.audioPlayer = FolioReaderAudioPlayer()
        self.folioReader.readerAudioPlayer = audioPlayer
    }
    
    // MARK: - Status Bar
    
    override open var prefersStatusBarHidden: Bool {
        return (self.readerConfig.shouldHideNavigationOnTap == false ? false : self.shouldHideStatusBar)
    }
    
    override open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return self.folioReader.isNight(.lightContent, .default)
    }
}
