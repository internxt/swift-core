//
//  DriveUtils.swift
//
//
//  Created by Patricio Tovar on 23/5/24.
//

import Foundation

public struct DriveUtils {
    
    static func convertFileMetaToUnified(fileMeta: GetFileMetaByIdResponse) -> GetDriveItemMetaByIdResponse {
        return GetDriveItemMetaByIdResponse(
            id: fileMeta.id,
            parentId: nil,
            name: fileMeta.name,
            bucket: fileMeta.bucket,
            userId: fileMeta.userId,
            encryptVersion: nil,
            deleted: fileMeta.deleted,
            createdAt: fileMeta.createdAt,
            updatedAt: fileMeta.updatedAt,
            deletedAt: fileMeta.deletedAt,
            removedAt: fileMeta.removedAt,
            uuid: fileMeta.uuid,
            plainName: fileMeta.plainName,
            removed: fileMeta.removed,
            folderId: fileMeta.folderId,
            type: fileMeta.type,
            size: fileMeta.size,
            fileId: fileMeta.fileId,
            modificationTime: fileMeta.modificationTime,
            status: fileMeta.status
        )
    }
    
    static func convertFolderMetaToUnified(folderMeta: GetFolderMetaByIdResponse) -> GetDriveItemMetaByIdResponse {
        return GetDriveItemMetaByIdResponse(
            id: folderMeta.id,
            parentId: folderMeta.parentId,
            name: folderMeta.name,
            bucket: folderMeta.bucket,
            userId: folderMeta.userId,
            encryptVersion: folderMeta.encryptVersion,
            deleted: folderMeta.deleted,
            createdAt: folderMeta.createdAt,
            updatedAt: folderMeta.updatedAt,
            deletedAt: folderMeta.deletedAt,
            removedAt: folderMeta.removedAt,
            uuid: folderMeta.uuid,
            plainName: folderMeta.plainName,
            removed: folderMeta.removed,
            folderId: nil,
            type: nil,
            size: nil,
            fileId: nil,
            modificationTime: nil,
            status: nil
        )
    }
}
