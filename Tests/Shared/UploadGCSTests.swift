//
//  UploadGCSTests.swift
//  Vimeo
//
//  Created by Nguyen, Van on 11/8/18.
//  Copyright © 2018 Vimeo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import XCTest
import OHHTTPStubs
import VimeoNetworking

class UploadGCSTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        VimeoClient.configureSharedClient(withAppConfiguration: AppConfiguration(clientIdentifier: "{CLIENT_ID}",
                                                                                 clientSecret: "{CLIENT_SECRET}",
                                                                                 scopes: [.Public, .Private, .Purchased, .Create, .Edit, .Delete, .Interact, .Upload],
                                                                                 keychainService: "com.vimeo.keychain_service",
                                                                                 apiVersion: "3.3.10"), configureSessionManagerBlock: nil)
    }
    
    func test_uploadGCSResponse_getsParsedIntoUploadObject() {
        let request = Request<VIMUpload>(path: "/videos/" + Constants.CensoredId)
        
        stub(condition: isPath("/videos/" + Constants.CensoredId)) { _ in
            let stubPath = OHPathForFile("upload_gcs.json", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
        }
        
        let expectation = self.expectation(description: "Network call expectation")
        
        _ = VimeoClient.sharedClient.request(request) { response in
            switch response {
            case .success(let result):
                let upload = result.model
                
                XCTAssertEqual(upload.uploadApproach, VIMUpload.UploadApproach(rawValue: "gcs"), "The upload approach should have been `gcs`.")
                
                guard let gcs = upload.gcs?.first else {
                    XCTFail("Failure: The GCS array must not be empty.")
                    
                    return
                }
                
                XCTAssertEqual(gcs.startByte?.int64Value, 0, "The start byte should have been `0`.")
                XCTAssertEqual(gcs.endByte?.int64Value, 377296827, "The end byte should have been `377296827`.")
                XCTAssertEqual(gcs.uploadLink, "https://www.google.com", "The upload link should have been `https://www.google.com`.")
                XCTAssertNotNil(gcs.connections[.uploadAttempt], "The upload attempt connection should have existed.")
                
            case .failure(let error):
                XCTFail("\(error)")
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0) { error in
            if let unWrappedError = error {
                XCTFail("\(unWrappedError)")
            }
        }
    }
}
