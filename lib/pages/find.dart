import 'dart:math';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../models/util.dart';
import '../models/albums.dart';
import '../theme/theme.dart';
import '../widgets/nodata.dart';
import '../widgets/searchbar.dart';
import '../models/find_controller.dart';
import '../models/setting_controller.dart';
import '../src/rust/api/youtube.dart' as youtube;

class FindPage extends StatefulWidget {
  const FindPage({super.key});

  @override
  State<FindPage> createState() => _FindPageState();
}

class _FindPageState extends State<FindPage> {
  final findController = Get.find<FindController>();
  final settingController = Get.find<SettingController>();

  final FocusNode focusNodeSearch = FocusNode();
  final TextEditingController controllerSearch = TextEditingController();
  final log = Logger();

  Future<void> searchYoutube(String text) async {
    final proxyUrl = settingController.proxy.url(ProxyType.youtube);
    final ids = await youtube.fetchIds(
        keyword: text, maxIdCount: 10, proxyUrl: proxyUrl);

    var tmpList = <Info>[];

    for (String id in ids) {
      try {
        final vinfo = await youtube.videoInfoById(id: id, proxyUrl: proxyUrl);
        final info = Info(
          raw: vinfo,
          extention: "mp4",
          proxyType: ProxyType.youtube,
          albumArtImagePath: Albums.youtubeAsset,
        );

        // song duration too short or too long would be ignored
        if (vinfo.lengthSeconds < 90 || vinfo.lengthSeconds > 600) {
          tmpList.add(info);
        } else {
          findController.infoList.add(info);
        }
      } catch (e) {
        Get.snackbar("提 示".tr, "获取音频信息失败".tr,
            snackPosition: SnackPosition.BOTTOM);
      }
    }

    if (findController.infoList.length < 5) {
      findController.infoList.addAll(tmpList);
    }
  }

  // TODO
  Future<void> searchBilibili(String text) async {
    throw Exception("Not implement");
  }

  void search(String text) async {
    if (text.isEmpty) {
      Get.snackbar("提 示".tr, "请输入内容".tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    int searchErrorCount = 0;
    findController.retainDownloadingInfo();
    findController.isSearching = true;

    try {
      await searchYoutube(text);
    } catch (e) {
      Get.snackbar("搜索Youtube失败".tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
      searchErrorCount++;
    }

    try {
      await searchBilibili(text);
    } catch (e) {
      // Get.snackbar("搜索Bilibili失败".tr, e.toString(),
      //     snackPosition: SnackPosition.BOTTOM);
      searchErrorCount++;
    }

    if (searchErrorCount != 2) {
      Get.snackbar("提 示".tr, "搜索完成".tr, snackPosition: SnackPosition.BOTTOM);
    }

    findController.isSearching = false;
  }

  Future<void> downlaodYoutube(Info info) async {
    final progressStream = youtube.downloadVideoByIdWithCallback(
      id: info.raw.videoId,
      downloadPath: await findController.downloadPath(info),
      proxyUrl: info.proxyUrl(),
    );

    info.setProgressStreamWithListen(progressStream, info);
  }

  // TODO
  Future<void> downlaodBilibili(Info info) async {}

  Future<void> startDownload(Info info) async {
    if (info.downloadState == DownloadState.downloading) {
      Get.snackbar("提 示".tr, "已经在下载，请耐心等待".tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (info.downloadState == DownloadState.downloaded) {
      Get.snackbar("提 示".tr, "请勿重复下载".tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    info.downloadState = DownloadState.downloading;
    Get.snackbar("提 示".tr, "${'开始下载'.tr} ${info.raw.title}".tr,
        snackPosition: SnackPosition.BOTTOM);

    try {
      if (info.proxyType == ProxyType.youtube) {
        await downlaodYoutube(info);
      } else if (info.proxyType == ProxyType.bilibili) {
        await downlaodBilibili(info);
      }
    } catch (e) {
      info.downloadState = DownloadState.failed;
      Get.snackbar("下载失败".tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void showDetailDialog(BuildContext context, Info info) {
    final settingController = Get.find<SettingController>();
    final labelWidth = settingController.isLangZh ? 50.0 : 80.0;

    Get.dialog(
      Dialog(
        child: Container(
          width: double.infinity,
          height: min(350, MediaQuery.of(context).size.height * 0.8),
          padding: const EdgeInsets.all(CTheme.margin * 4),
          decoration: BoxDecoration(
            color: CTheme.background,
            borderRadius: BorderRadius.circular(CTheme.borderRadius * 2),
          ),
          child: ListView(
            children: [
              if (info.raw.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: CTheme.padding * 2, top: CTheme.padding * 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Text("标题".tr,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            late Uri url;
                            if (info.proxyType == ProxyType.youtube) {
                              url = Uri.parse(
                                  youtube.watchUrl(id: info.raw.videoId));
                            }

                            try {
                              await launchUrl(url);
                            } catch (e) {
                              Get.snackbar("提 示".tr, e.toString());
                            }
                          },
                          child: Text(
                            info.raw.title,
                            style: TextStyle(
                              color: CTheme.link,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (info.raw.author.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: CTheme.padding * 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Text("作者".tr,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Expanded(
                        child: Text(info.raw.author),
                      ),
                    ],
                  ),
                ),
              if (info.raw.lengthSeconds > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: CTheme.padding * 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Text("时长".tr,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Expanded(
                        child: Text(formattedTime(info.raw.lengthSeconds)),
                      ),
                    ],
                  ),
                ),
              if (info.raw.viewCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: CTheme.padding * 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Text("次数".tr,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Expanded(
                        child: Text(formattedNumber(info.raw.viewCount)),
                      ),
                    ],
                  ),
                ),
              if (info.raw.shortDescription.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(CTheme.padding * 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(info.raw.shortDescription),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTitle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            constraints:
                const BoxConstraints(maxHeight: CTheme.searchBarHeight),
            child: CSearchBar(
              height: CTheme.searchBarHeight,
              controller: controllerSearch,
              focusNode: focusNodeSearch,
              hintText: "请输入关键字".tr,
              autofocus: findController.infoList.isEmpty,
              onSubmitted: (value) => search(value),
            ),
          ),
        ),
        const SizedBox(width: CTheme.margin * 4),
        GestureDetector(
          onTap: () => search(controllerSearch.text),
          child: Text("搜索".tr, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }

  Widget buildDownload(BuildContext context, Info info) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            formattedTime(info.raw.lengthSeconds),
            overflow: TextOverflow.ellipsis,
          ),
          if (info.downloadState == DownloadState.downloading ||
              info.downloadState == DownloadState.downloaded)
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: CTheme.padding * 2),
              child: InkWell(
                hoverColor: Colors.transparent,
                onTap: () => startDownload(info),
                child: CircularPercentIndicator(
                  radius: 15,
                  lineWidth: 3,
                  percent: info.downloadRate / 100,
                  center: Text(
                    info.downloadRate.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                  ),
                  progressColor: info.downloadState == DownloadState.downloaded
                      ? Colors.green
                      : CTheme.secondaryBrand,
                  backgroundColor: CTheme.primary,
                ),
              ),
            ),
          if (info.downloadState == DownloadState.undownload ||
              info.downloadState == DownloadState.failed)
            IconButton(
              icon: Icon(downloadStateIcon(info.downloadState)),
              onPressed: () => startDownload(info),
            ),
        ],
      ),
    );
  }

  Widget buildListTile(BuildContext context, int index) {
    final info = findController.infoList[index];
    return ListTile(
      contentPadding: const EdgeInsets.only(left: CTheme.padding * 2),
      title: Text(
        info.raw.title,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        info.raw.author,
        overflow: TextOverflow.ellipsis,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(CTheme.borderRadius),
        child: Image.asset(info.albumArtImagePath),
      ),
      trailing: SizedBox(
        width: 100,
        child: buildDownload(context, info),
      ),
      onTap: () => showDetailDialog(context, info),
    );
  }

  Widget buildInfoList(BuildContext context) {
    return Obx(
      () => ListView.builder(
        itemCount: findController.infoList.length,
        itemBuilder: (count, index) {
          return buildListTile(context, index);
        },
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return findController.infoList.isNotEmpty
        ? buildInfoList(context)
        : (findController.isSearching
            ? SpinKitFadingCircle(
                color: CTheme.primary,
                size: size.width * 0.2,
              )
            : const NoData());
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: CTheme.background,
        appBar: AppBar(
          title: buildTitle(context),
          centerTitle: true,
          backgroundColor: CTheme.background,
        ),
        body: buildBody(context),
      ),
    );
  }
}
