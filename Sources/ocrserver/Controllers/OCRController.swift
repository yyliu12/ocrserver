// Main controller for the server

import Vapor

struct OcrResponse: Content {
    var ocrText: String;
}

struct OcrRequest: Content {
    var file: Data;
    var secret: String;
}

struct Settings: Content {
    // "poppler" = use pdftotext command line executable
    // "pdfkit" = use apple's PDFKit
    var textMethod: String = "poppler";
}

func runVisionOnImage(image: Data) -> Promise<String> {
    
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
        
    }
    
    func ocrImage(req: Request) async throws -> OcrResponse {
        
    }
}
