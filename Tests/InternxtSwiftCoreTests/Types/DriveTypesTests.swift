//
//  DriveTypesTests.swift
//  InternxtSwiftCore
//

import Foundation
import XCTest
@testable import InternxtSwiftCore

final class DriveTypesTests: XCTestCase {

    private let folderJson = """
    {
        "type": "folder",
        "uuid": "4f1c6a52-2f5e-4a8c-9f6e-0b1d2c3e4f50",
        "parentUuid": "9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d",
        "plainName": "Documents",
        "bucket": "bucket-id",
        "userId": 1,
        "encryptVersion": "03-aes",
        "size": 0,
        "status": "EXISTS",
        "createdAt": "2026-10-20T10:00:00.000Z",
        "updatedAt": "2026-10-20T10:00:00.000Z"
    }
    """

    private let fileJson = """
    {
        "uuid": "1b2c3d4e-5f60-4718-8293-a4b5c6d7e8f9",
        "fileId": "network-file-id",
        "folderUuid": "4f1c6a52-2f5e-4a8c-9f6e-0b1d2c3e4f50",
        "plainName": "",
        "type": "dockerfile",
        "size": "1024",
        "bucket": "bucket-id",
        "userId": 1,
        "encryptVersion": "03-aes",
        "status": "EXISTS",
        "modificationTime": "2026-10-20T10:00:00.000Z",
        "createdAt": "2026-10-20T10:00:00.000Z",
        "updatedAt": "2026-10-20T10:00:00.000Z"
    }
    """

    private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        return try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    func testFolderModelsDecodeWithoutDeprecatedFields() throws {
        XCTAssertEqual(try decode(GetFolderFoldersResult.self, from: folderJson).plainName, "Documents")
        XCTAssertEqual(try decode(GetFolderMetaByIdResponse.self, from: folderJson).plainName, "Documents")
        XCTAssertEqual(try decode(CreateFolderResponseNew.self, from: folderJson).plainName, "Documents")
        XCTAssertEqual(try decode(UpdateFolderResponse.self, from: folderJson).plainName, "Documents")
        XCTAssertEqual(try decode(FolderResponse.self, from: folderJson).plainName, "Documents")
    }

    func testFolderModelsKeepNumericIdsAndRemovedWhenTheyArrive() throws {
        let legacyFolderJson = folderJson.replacingOccurrences(
            of: "\"type\": \"folder\",",
            with: "\"type\": \"folder\", \"id\": 42, \"parentId\": 7, \"removed\": false,"
        )

        let listedFolder = try decode(GetFolderFoldersResult.self, from: legacyFolderJson)
        let folderMeta = try decode(GetFolderMetaByIdResponse.self, from: legacyFolderJson)
        let createdFolder = try decode(CreateFolderResponseNew.self, from: legacyFolderJson)
        let folder = try decode(FolderResponse.self, from: legacyFolderJson)

        XCTAssertEqual(listedFolder.id, 42)
        XCTAssertEqual(listedFolder.parentId, 7)
        XCTAssertEqual(listedFolder.removed, false)
        XCTAssertEqual(folderMeta.id, 42)
        XCTAssertEqual(folderMeta.parentId, 7)
        XCTAssertEqual(folderMeta.removed, false)
        XCTAssertEqual(createdFolder.id, 42)
        XCTAssertEqual(createdFolder.parentId, 7)
        XCTAssertEqual(createdFolder.removed, false)
        XCTAssertEqual(folder.id, 42)
        XCTAssertEqual(folder.parentId, 7)
        XCTAssertEqual(folder.removed, false)

        let unifiedMeta = DriveUtils.convertFolderMetaToUnified(folderMeta: folderMeta)

        XCTAssertEqual(unifiedMeta.parentId, 7)
        XCTAssertEqual(unifiedMeta.removed, false)
    }

    func testRootFolderMetaDecodesWithoutPlainName() throws {
        let rootFolderJson = """
        {
            "type": "folder",
            "uuid": "4f1c6a52-2f5e-4a8c-9f6e-0b1d2c3e4f50",
            "parentUuid": null,
            "plainName": null,
            "bucket": "bucket-id",
            "userId": 1,
            "encryptVersion": "03-aes",
            "status": "EXISTS",
            "createdAt": "2022-11-03T15:21:29.000Z",
            "updatedAt": "2022-11-03T15:21:29.000Z"
        }
        """

        let rootMeta = try decode(GetFolderMetaByIdResponse.self, from: rootFolderJson)

        XCTAssertNil(rootMeta.plainName)
        XCTAssertEqual(rootMeta.bucket, "bucket-id")
    }

    func testFolderListingAndExistenceDecodeWithoutPlainName() throws {
        let folderWithoutPlainNameJson = folderJson.replacingOccurrences(
            of: "\"plainName\": \"Documents\"",
            with: "\"plainName\": null"
        )

        XCTAssertNil(try decode(GetFolderFoldersResult.self, from: folderWithoutPlainNameJson).plainName)
        XCTAssertNil(try decode(FolderResponse.self, from: folderWithoutPlainNameJson).plainName)
    }

    func testFileModelsDecodeWithoutDeprecatedFields() throws {
        XCTAssertEqual(try decode(GetFolderFilesResultV2.self, from: fileJson).plainName, "")
        XCTAssertEqual(try decode(GetFileMetaByIdResponseV2.self, from: fileJson).plainName, "")
        XCTAssertEqual(try decode(CreateFileResponseNew.self, from: fileJson).plain_name, "")
    }

    func testCreateFilePayloadSendsFolderUuidAndNoDeprecatedFields() throws {
        let payload = CreateFileDataNew(
            fileId: "network-file-id",
            type: "pdf",
            bucket: "bucket-id",
            size: 1024,
            plainName: "report",
            folderUuid: "4f1c6a52-2f5e-4a8c-9f6e-0b1d2c3e4f50"
        )

        let body = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(payload)) as? [String: Any]
        )

        XCTAssertEqual(body["folderUuid"] as? String, "4f1c6a52-2f5e-4a8c-9f6e-0b1d2c3e4f50")
        XCTAssertEqual(body["plainName"] as? String, "report")
        XCTAssertNil(body["folder_id"])
        XCTAssertNil(body["name"])
    }
}
