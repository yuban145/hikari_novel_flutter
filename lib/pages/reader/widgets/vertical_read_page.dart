import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../router/route_path.dart';
import '../../../common/constants.dart';

class VerticalReadPage extends StatefulWidget {
  final String text;
  final List<String> images;
  final int initialOffset;
  final EdgeInsets padding;
  final TextStyle style;
  final int paraSpacing;
  final int paraIndent;
  final Function(double position, double max) onScroll;

  const VerticalReadPage(
    this.text,
    this.images, {
    required this.initialOffset,
    required this.padding,
    required this.style,
    required this.paraSpacing,
    required this.paraIndent,
    required this.onScroll,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => VerticalReadPageState();
}

class VerticalReadPageState extends State<VerticalReadPage> {
  late ScrollController controller;
  List<ReaderItem> _items = [];

  bool _restored = false;

  String text = "";
  List<String> images = [];
  TextStyle textStyle = TextStyle();
  EdgeInsets padding = EdgeInsets.zero;
  late int paraIndent;
  late int paraSpacing;

  late String _lastLayoutSig;

  @override
  void initState() {
    super.initState();
    _lastLayoutSig = _layoutSignature();
    _initController();
    resetPage();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  double get currentPositionPixels => controller.position.pixels;

  void scrollPage(bool forward) {
    if (!controller.hasClients) return;
    final position = controller.position;
    final target = (position.pixels + position.viewportDimension * (forward ? 0.9 : -0.9)).clamp(position.minScrollExtent, position.maxScrollExtent);
    controller.animateTo(target, duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
  }

  double get maxPositionPixels => controller.position.maxScrollExtent;

  void _initController() {
    controller = ScrollController();
    controller.addListener(_onScroll);
  }

  //��������
  void _onScroll() {
    if (!controller.hasClients) return;
    if (maxPositionPixels <= 0) return;

    widget.onScroll(currentPositionPixels, maxPositionPixels);
  }

  //��ʼλ�ûָ�
  bool _restoreInitialPosition() {
    if (!controller.hasClients) return false;

    final position = controller.position;

    if (!position.hasContentDimensions) return false;

    double targetOffset = widget.initialOffset.toDouble();
    targetOffset = targetOffset.clamp(0, position.maxScrollExtent);

    controller.jumpTo(targetOffset);

    widget.onScroll(currentPositionPixels, maxPositionPixels);
    return true;
  }

  /// ������ת
  /// - [value] ��ΧΪ0-100��ֵ
  void jumpToProgress(double value) {
    if (!controller.hasClients) return;

    double targetOffset = maxPositionPixels * (value / 100.0);

    targetOffset = targetOffset.clamp(0, maxPositionPixels);

    controller.jumpTo(targetOffset);
  }

  void resetPage() {
    text = widget.text;
    textStyle = widget.style;
    images = List<String>.from(widget.images); //ת��Ϊ������List<String>
    padding = widget.padding;
    paraIndent = widget.paraIndent;
    paraSpacing = widget.paraSpacing;
    if (text.isEmpty && images.isEmpty) {
      setState(() {
        _items = [];
      });
      return;
    }

    _splitItems();
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant VerticalReadPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final contentChanged = widget.text != oldWidget.text || !listEquals(widget.images, oldWidget.images);
    final newSig = _layoutSignature();
    if (contentChanged) {
      _lastLayoutSig = newSig;
      _restored = false;
      resetPage();
      return;
    }

    //����Ƚ��Ű漸�β�����fontSize, textStyle���Ƿ��б仯
    //���ﲻ��ʹ��"widget.xxx != oldWidget.xxx"�������ڱȽ϶��󣬶����ǱȽ����еĲ�����������ǳģʽ�л�����ҳ���ؽ������ؽ�TextStyle����ʵ������������
    if (newSig != _lastLayoutSig) {
      _lastLayoutSig = newSig;
      resetPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_restored) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _restored) return;
        _restored = _restoreInitialPosition();
      });
    }

    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((_, index) {
              final item = _items[index];

              switch (item.type) {
                case ReaderItemType.text:
                  return _buildText(item.content);
                case ReaderItemType.image:
                  return _buildImage(item.content, item.index!);
              }
            }, childCount: _items.length),
          ),
        ),
      ],
    );
  }

  Widget _buildText(String content) {
    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(bottom: paraSpacing.toDouble()),
        child: RichText(
          text: TextSpan(
            style: textStyle,
            children: [
              WidgetSpan(
                child: SizedBox(width: textStyle.fontSize! * paraIndent), //�����ֿ�������
              ),
              TextSpan(text: content),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String url, int index) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: GestureDetector(
          onDoubleTap: () => Get.toNamed(RoutePath.photo, arguments: {"gallery_mode": true, "list": widget.images, "index": index}),
          onLongPress: () => Get.toNamed(RoutePath.photo, arguments: {"gallery_mode": true, "list": widget.images, "index": index}),
          child: CachedNetworkImage(
            width: double.infinity,
            imageUrl: url,
            httpHeaders: kUserAgent,
            fit: BoxFit.fitWidth,
            progressIndicatorBuilder: (context, url, progress) => Center(child: CircularProgressIndicator(value: progress.progress)),
            errorWidget: (context, url, error) => Column(children: [const Icon(Icons.error_outline), Text(error.toString())]),
          ),
        ),
      ),
    );
  }

  void _splitItems() {
    final paragraphs = widget.text.split('\n\n').where((e) => e.trim().isNotEmpty);

    _items = [];

    for (var para in paragraphs) {
      _items.add(ReaderItem.text(para.trimLeft()));
    }

    for (int i = 0; i < widget.images.length; i++) {
      _items.add(ReaderItem.image(widget.images[i], i));
    }
  }

  //�Ű漸�β�����ǩ��
  String _layoutSignature() {
    final s = widget.style;
    final p = widget.padding;

    return [
      s.fontSize,
      s.height,
      s.letterSpacing,
      s.wordSpacing,
      s.color?.toARGB32(),
      p.left,
      p.right,
      p.top,
      p.bottom,
      widget.paraIndent,
      widget.paraSpacing,
    ].join("|");
  }
}

enum ReaderItemType { text, image }

class ReaderItem {
  final ReaderItemType type;
  final String content;
  int? index;

  ReaderItem.text(this.content) : type = ReaderItemType.text;

  ReaderItem.image(this.content, this.index) : type = ReaderItemType.image;
}
