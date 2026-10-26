//
//  DriveUtils.swift
//
//
//  Created by Patricio Tovar on 23/5/24.
//

import Foundation

public struct DriveUtils {
    
    static func convertFileMetaToUnified(fileMeta: GetFileMetaByIdResponseV2) -> GetDriveItemMetaByIdResponse {
        return GetDriveItemMetaByIdResponse(
            parentId: nil,
            name: fileMeta.plainName,
            bucket: fileMeta.bucket,
            userId: fileMeta.userId,
            encryptVersion: nil,
            deleted: nil,
            createdAt: fileMeta.createdAt,
            updatedAt: fileMeta.updatedAt,
            deletedAt: nil,
            removedAt: nil,
            uuid: fileMeta.uuid,
            plainName: fileMeta.plainName,
            removed: nil,
            folderId: nil,
            type: fileMeta.type,
            size: fileMeta.size,
            fileId: fileMeta.fileId,
            modificationTime: fileMeta.modificationTime,
            status: fileMeta.status
        )
    }
    
    static func convertFolderMetaToUnified(folderMeta: GetFolderMetaByIdResponse) -> GetDriveItemMetaByIdResponse {
        return GetDriveItemMetaByIdResponse(
            parentId: nil,
            name: folderMeta.plainName ?? "",
            bucket: folderMeta.bucket,
            userId: folderMeta.userId,
            encryptVersion: folderMeta.encryptVersion,
            deleted: nil,
            createdAt: folderMeta.createdAt,
            updatedAt: folderMeta.updatedAt,
            deletedAt: nil,
            removedAt: nil,
            uuid: folderMeta.uuid,
            plainName: folderMeta.plainName,
            removed: nil,
            folderId: nil,
            type: "folder",
            size: nil,
            fileId: nil,
            modificationTime: nil,
            status: nil
        )
    }
}
