import 'package:bot_toast/bot_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../consts/base64.dart';
import '../consts/image_services.dart';
import '../generated/l10n.dart';
import '../main.dart';
import '../util/store_util.dart';

class Uploader {
  static int nip95MaxLength = 80000;

  static const nostrBuildURL = "https://nostr.build/";

  static Future<String?> pick(BuildContext context) async {
    if (PlatformUtil.isPC() || PlatformUtil.isWeb()) {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        if (settingsProvider.imageService == ImageServices.NIP_95 &&
            result.files.single.size > nip95MaxLength) {
          if (!context.mounted) return null;
          BotToast.showText(text: S.of(context).File_is_too_big_for_NIP_95);
        }

        if (PlatformUtil.isWeb() && result.files.single.bytes != null) {
          return BASE64.toBase64(result.files.single.bytes!);
        }

        return result.files.single.path;
      }

      return null;
    }

    var assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(maxAssets: 1),
    );

    if (assets != null && assets.isNotEmpty) {
      var file = await assets[0].file;

      if (settingsProvider.imgCompress >= 30 &&
          settingsProvider.imgCompress < 100) {
        var fileExtension = StoreUtil.getFileExtension(file!.path);
        fileExtension ??= ".jpg";
        var tempDir = await getTemporaryDirectory();
        var tempFilePath =
            "${tempDir.path}/${StringUtil.rndNameStr(12)}$fileExtension";
        FlutterImageCompress.validator.ignoreCheckExtName = true;
        var result = await FlutterImageCompress.compressAndGetFile(
          file.path,
          tempFilePath,
          quality: settingsProvider.imgCompress,
        );

        if (result != null) {
          if (settingsProvider.imageService == ImageServices.NIP_95 &&
              (await result.length()) > nip95MaxLength) {
            if (!context.mounted) return null;
            BotToast.showText(text: S.of(context).File_is_too_big_for_NIP_95);
          }
          return result.path;
        }
      }

      if (settingsProvider.imageService == ImageServices.NIP_95) {
        var fileSize = StoreUtil.getFileSize(file!.path);
        if (fileSize != null && fileSize > nip95MaxLength) {
          if (!context.mounted) return null;
          BotToast.showText(text: S.of(context).File_is_too_big_for_NIP_95);
        }
      }

      return file!.path;
    }

    return null;
  }

  static Future<List<String>> pickFiles(BuildContext context) async {
    List<String> resultFiles = [];

    if (PlatformUtil.isPC() || PlatformUtil.isWeb()) {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(allowMultiple: true);

      if (result != null) {
        for (var file in result.files) {
          var size = file.size;
          if (settingsProvider.imageService == ImageServices.NIP_95 &&
              size > nip95MaxLength) {
            if (!context.mounted) return [];
            BotToast.showText(text: S.of(context).File_is_too_big_for_NIP_95);
            return [];
          }

          if (PlatformUtil.isWeb() && file.bytes != null) {
            resultFiles.add(BASE64.toBase64(result.files.single.bytes!));
          } else if (StringUtil.isNotBlank(file.path)) {
            resultFiles.add(file.path!);
          }
        }
      }

      return resultFiles;
    }

    var assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(maxAssets: 20),
      useRootNavigator: false,
    );

    if (assets != null && assets.isNotEmpty) {
      for (var asset in assets) {
        var file = await asset.file;

        if (settingsProvider.imgCompress >= 30 &&
            settingsProvider.imgCompress < 100) {
          var fileExtension = StoreUtil.getFileExtension(file!.path);
          fileExtension ??= ".jpg";
          var tempDir = await getTemporaryDirectory();
          var tempFilePath =
              "${tempDir.path}/${StringUtil.rndNameStr(12)}$fileExtension";
          FlutterImageCompress.validator.ignoreCheckExtName = true;
          var result = await FlutterImageCompress.compressAndGetFile(
            file.path,
            tempFilePath,
            quality: settingsProvider.imgCompress,
          );

          if (result != null) {
            if (settingsProvider.imageService == ImageServices.NIP_95 &&
                (await result.length()) > nip95MaxLength) {
              if (!context.mounted) return [];
              BotToast.showText(text: S.of(context).File_is_too_big_for_NIP_95);
              return [];
            }

            resultFiles.add(result.path);
            continue;
          }
        }

        if (settingsProvider.imageService == ImageServices.NIP_95) {
          var fileSize = StoreUtil.getFileSize(file!.path);
          if (fileSize != null && fileSize > nip95MaxLength) {
            if (!context.mounted) return [];
            BotToast.showText(text: S.of(context).File_is_too_big_for_NIP_95);
            return [];
          }
        }

        resultFiles.add(file!.path);
      }
    }

    return resultFiles;
  }

  static Future<String?> upload(String localPath,
      {String? imageService, String? fileName}) async {
    if (nostr == null) return null;
    const blossomURL = "https://nosto.re/";
    final String? serviceURL = settingsProvider.imageServiceAddr;
    return switch (imageService) {
      ImageServices.POMF2_LAIN_LA => await Pomf2LainLa.upload(
          localPath,
          fileName: fileName,
        ),
      ImageServices.NOSTO_RE => await BlossomUploader.upload(
          nostr!,
          blossomURL,
          localPath,
          fileName: fileName,
        ),
      ImageServices.NIP_95 => await NIP95Uploader.upload(
          nostr!,
          localPath,
          fileName: fileName,
        ),
      ImageServices.NIP_96 when StringUtil.isNotBlank(serviceURL) =>
        await NIP96Uploader.upload(
          nostr!,
          serviceURL!,
          localPath,
          fileName: fileName,
        ),
      ImageServices.BLOSSOM when StringUtil.isNotBlank(serviceURL) =>
        await BlossomUploader.upload(
          nostr!,
          serviceURL!,
          localPath,
          fileName: fileName,
        ),
      ImageServices.VOID_CAT => await VoidCatUploader.upload(
          localPath,
        ),
      ImageServices.NOSTR_BUILD => await NIP96Uploader.upload(
          nostr!,
          nostrBuildURL,
          localPath,
          fileName: fileName,
        ),
      _ when PlatformUtil.isWeb() => await BlossomUploader.upload(
          nostr!,
          blossomURL,
          localPath,
          fileName: fileName,
        ),
      _ => await NIP96Uploader.upload(
          nostr!,
          nostrBuildURL,
          localPath,
          fileName: fileName,
        ),
    };
  }
}
