// Main controller for the server

import Vapor
import Vision
import PDFKit

struct OcrResponse: Content {
    var ocrText: String;
}

struct OcrRequest: Content {
    var file: Data;
    var secret: String;
}

struct Settings: Content {
    static let pdfTempFolder = URL(fileURLWithPath: "/Users/yuyangliu/Desktop/journalindex/pdftotexttemp")
    static let pdfToTextLocation = "/opt/homebrew/bin/pdftotext"
    static let secret = "288Nk8sNbqnfhjI4JQAcAQCcRwZnj5r1"
}

func randomString(_ length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{ _ in letters.randomElement()! })
}

func runPdfToText(pdf: Data) -> String {
    let pdfDest = Settings.pdfTempFolder.appendingPathComponent(randomString(10)).appendingPathExtension("pdf")
    var out: String = "";
    do {
        try pdf.write(to: pdfDest)
        out = try safeShell(Settings.pdfToTextLocation + " " + pdfDest.absoluteString + " -")
    } catch {
        print(error)
    }
    
    do {
        try FileManager.default.removeItem(at: pdfDest)
    } catch {
        print(error)
    }
    
    return out
}

func runVisionOnImage(image: Data? = nil, cg: CGImage? = nil) async -> String {
    let requestHandler: VNImageRequestHandler
    
    if image != nil {
        requestHandler = VNImageRequestHandler(data: image!)
    } else if cg != nil {
        requestHandler = VNImageRequestHandler(cgImage: cg!)
    } else {
        return ""
    }
    
    let results = await withCheckedContinuation { continuation in
        
        let request = VNRecognizeTextRequest(completionHandler: {(req, error) in
            guard let observations = req.results as? [VNRecognizedTextObservation] else {
                continuation.resume(returning: "")
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            continuation.resume(returning: recognizedStrings.joined(separator: " "))
        })
        do {
            try requestHandler.perform([request])
        } catch {
            continuation.resume(returning: "")
        }
        
    }
    
    return results
}

struct OCRController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.group("ocrPDF") { ocrPDFPath in
            ocrPDFPath.post(use: ocrPDF)
        }
        
        routes.group("ocrImage") { ocrImagePath in
            ocrImagePath.post(use: ocrImage)
        }
    }
    
    func ocrPDF(req: Request) async throws -> OcrResponse {
        let reqData = try req.content.decode(OcrRequest.self)
        
        if (reqData.secret != Settings.secret) {
            return OcrResponse(ocrText: "Invalid secret")
        }
        
        let doc = PDFDocument(data: reqData.file)
        
        if (doc != nil) {
            var text = runPdfToText(pdf: reqData.file)
            
            let images = await extractImages(from: doc!)
            
            for image in images {
                switch image {
                case .jpg(let data):
                    text.append(await runVisionOnImage(image: data))
                case .raw(let data):
                    text.append(await runVisionOnImage(cg: data))
                }
            }
            
            return OcrResponse(ocrText: text)
        } else {
            return OcrResponse(ocrText: "")
        }
    }
    
    func ocrImage(req: Request) async throws -> OcrResponse {
        let reqData = try req.content.decode(OcrRequest.self)
        
        if (reqData.secret != Settings.secret) {
            return OcrResponse(ocrText: "Invalid secret")
        }
        
        return await OcrResponse(ocrText: runVisionOnImage(image: reqData.file))
    }
}
