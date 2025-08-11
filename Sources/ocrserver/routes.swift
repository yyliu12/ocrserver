import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        return HTTPStatus.ok
    }

    try app.register(collection: OCRController())
}
