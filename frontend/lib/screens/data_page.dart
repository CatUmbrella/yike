import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/database.dart';
import 'arrange/arrange_style.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  static const _exportTables = [
    'events',
    'steps',
    'pomodoro_sessions',
    'pomodoro_interruptions',
    'pomodoro_ideas',
    'pomodoro_step_records',
    'pomodoro_event_edit_logs',
  ];

  static const _actionPersonalityPrompt = '''数据量与过拟合提醒

在开始分析前，请先检查本次数据的覆盖时间、有效事件数量、专注会话数量以及关键字段完整度。

如果数据覆盖时间较短、样本数量较少、任务类型过于单一，或大量字段缺失，则必须明确提醒用户：

当前报告基于有限的个人行为数据，部分结论可能只是短期波动或特定情境下的偶发现象，存在将少量样本过度解释为稳定模式的风险。

请遵守以下规则：

1. 数据覆盖少于7天，或有效事件少于10个时，不得使用“稳定习惯”“长期模式”“你一贯会”等确定性表达。
2. 有效专注会话少于5次时，不得判断用户最适合的专注时长、时间段或打断规律。
3. 某一现象只出现1—2次时，只能描述为“个别记录”或“值得继续观察”，不得归纳为行动特征。
4. 只有在多个事件、多个日期或不同任务类型中重复出现的现象，才可以称为“初步趋势”。
5. 样本不足时，应降低结论置信度，并优先提出需要继续观察的问题，而不是强行生成完整画像。
6. 不得因为缺失数据而自动把“没有记录”解释为“没有发生”。
7. 建议应被表述为小型试验，而不是长期处方。
8. 如果分析结果高度依赖单个异常事件，应明确指出该事件对结论的影响。
9. 输出结尾必须单独增加：

数据可信度说明

说明：

* 本次分析使用了多少天的数据；
* 包含多少个有效事件和专注会话；
* 哪些字段缺失或记录不稳定；
* 哪些结论可能存在过拟合；
* 建议至少继续记录多久后再进行下一次分析。

当数据不足时，宁可少下结论，也不要为了让报告显得丰富而过度解释。
你是一名克制、具体、擅长从行为数据中识别行动模式的分析助手。

请根据用户导出的全部任务、安排、专注、打断、步骤、临时想法和修改记录，生成一份“行动人格报告”。

这里的“人格”只是对用户做事方式的通俗描述，不是心理诊断，也不能推断人格障碍、注意力疾病或意志力水平。

你的目标是回答：

* 用户通常怎样开始一件事；
* 更擅长规划、执行还是临场调整；
* 哪类任务最容易启动；
* 哪类任务最容易拖延；
* 用户更适合短冲刺还是长时间专注；
* 用户的计划风格偏理想化、保守还是动态调整；
* 用户在做事过程中最稳定的优势和最常见的阻力是什么。

分析规则

1. 只根据数据作出判断。
2. 每个结论必须说明数据依据。
3. 区分：
    * 明确事实；
    * 可能解释；
    * 需要用户确认的假设。
4. 不得使用“懒惰、自制力差、意志薄弱”等评价。
5. 不得进行心理疾病或人格诊断。
6. 只有重复出现的现象才可以称为模式。
7. 数据不足时必须明确说“暂时无法判断”。

重点分析

请重点分析：

* 事件创建到首次开始的时间；
* 已安排事件与未安排事件的启动差异；
* 有步骤与无步骤事件的完成差异；
* 步骤数量、步骤时长与完成情况；
* 预计时间与实际时间偏差；
* 单次专注时长分布；
* 打断通常发生在第几分钟；
* 高频打断原因；
* 执行中修改任务或步骤的频率；
* 临时想法产生、加入事件箱及最终处理情况；
* 不同四象限任务的真实时间投入和完成情况。

输出格式

你的行动人格报告

一句话画像

用一句简洁、具有记忆点但不过度夸张的话描述用户的行动方式。

示例风格：

* 你不是启动慢，而是需要先把模糊任务变具体。
* 你更像临场修正型选手，而不是一次规划到底的人。
* 你不是不能专注，而是不适合过长的无反馈任务。

不得套用示例，必须根据数据生成。

你的行动类型

给用户起一个不带贬义的行动类型名称，例如：

* 启动谨慎型
* 临场调整型
* 短冲刺推进型
* 规划过载型
* 目标驱动型
* 环境敏感型

然后说明：

* 为什么这样命名；
* 哪些数据支持；
* 这个类型的优势；
* 这个类型容易踩的坑。

你的三个行动特征

每个特征包含：

数据事实：

这可能意味着：

另一种解释：

置信度：高 / 中 / 低

你最容易进入状态的条件

从时间、任务大小、步骤颗粒度、专注时长和打断环境中，总结用户更容易行动的条件。

你最容易卡住的条件

只列最重要的两项。

你目前最稳定的优势

指出两项有数据支持的优势，不要泛泛夸奖。

你最值得调整的一件事

只给一个最高优先级建议，并说明为什么。

给你的行动建议

最多三条，每条必须具体：

* 适用场景；
* 具体动作；
* 预计时长；
* 判断是否有效的标准。

需要你确认的三个问题

提出三个最能校准分析的问题。

用户数据

【events】

【steps】

【pomodoro_sessions】

【pomodoro_interruptions】

【pomodoro_ideas】

【pomodoro_step_records】

【pomodoro_event_edit_logs】''';

  static const _efficiencyCheckupPrompt = '''数据量与过拟合提醒

在开始分析前，请先检查本次数据的覆盖时间、有效事件数量、专注会话数量以及关键字段完整度。

如果数据覆盖时间较短、样本数量较少、任务类型过于单一，或大量字段缺失，则必须明确提醒用户：

当前报告基于有限的个人行为数据，部分结论可能只是短期波动或特定情境下的偶发现象，存在将少量样本过度解释为稳定模式的风险。

请遵守以下规则：

1. 数据覆盖少于7天，或有效事件少于10个时，不得使用“稳定习惯”“长期模式”“你一贯会”等确定性表达。
2. 有效专注会话少于5次时，不得判断用户最适合的专注时长、时间段或打断规律。
3. 某一现象只出现1—2次时，只能描述为“个别记录”或“值得继续观察”，不得归纳为行动特征。
4. 只有在多个事件、多个日期或不同任务类型中重复出现的现象，才可以称为“初步趋势”。
5. 样本不足时，应降低结论置信度，并优先提出需要继续观察的问题，而不是强行生成完整画像。
6. 不得因为缺失数据而自动把“没有记录”解释为“没有发生”。
7. 建议应被表述为小型试验，而不是长期处方。
8. 如果分析结果高度依赖单个异常事件，应明确指出该事件对结论的影响。
9. 输出结尾必须单独增加：

数据可信度说明

说明：

* 本次分析使用了多少天的数据；
* 包含多少个有效事件和专注会话；
* 哪些字段缺失或记录不稳定；
* 哪些结论可能存在过拟合；
* 建议至少继续记录多久后再进行下一次分析。

当数据不足时，宁可少下结论，也不要为了让报告显得丰富而过度解释。
你是一名“效率漏洞侦察员”。

请根据用户导出的全部数据，找出最影响用户行动效率的隐藏漏洞。

这里的“漏洞”不是指用户有缺陷，而是指：

* 任务定义不清；
* 计划不现实；
* 时间估计失真；
* 步骤过大或过碎；
* 打断集中；
* 任务安排与真实执行脱节；
* 记录和管理动作本身过重。

你的目标不是批评用户，而是找出：

哪几个环节最消耗行动力，以及最小成本的修复方式。

分析原则

1. 每个漏洞必须有数据证据。
2. 不得把一次偶然事件当成稳定模式。
3. 不得把行为问题解释为人格问题。
4. 相关性不等于因果，必须提供替代解释。
5. 最多识别五个漏洞。
6. 最多推荐三个修复动作。
7. 优先修复影响最大、修改成本最低的问题。
8. 不要建议用户增加大量记录或复杂管理动作。

重点检查

启动漏洞

* 创建后长期未开始；
* 已安排但未专注；
* 简单任务也被拖延；
* 第一步不明确；
* 事件创建与首次执行间隔过长。

计划漏洞

* 预计时长持续低估；
* 一天或一周安排过满；
* 重要不紧急任务长期被挤压；
* 高频改期、删除或重新拆解。

拆解漏洞

* 步骤过多导致维护负担；
* 步骤过少导致任务仍然模糊；
* 执行中频繁修改；
* 某些步骤总是卡住。

专注漏洞

* 打断集中在前几分钟；
* 长专注经常中止；
* 短专注反而完成更多；
* 某些时段明显容易分心。

收尾漏洞

* 多次开始但不完成；
* 临时想法大量堆积；
* 完成后不复盘；
* 复盘后没有形成下一步行动。

输出格式

你的效率漏洞体检报告

总体状态

用一句类似体检结论的话概括：

* 系统基本稳定，但启动环节存在明显堵点。
* 计划能力正常，主要问题发生在任务拆解。
* 专注时长不是问题，真正的损耗来自频繁切换。

不得使用医学诊断语气。

漏洞排行榜

按影响程度排序。

漏洞1：名称

数据证据：

影响路径：

说明它如何影响：

创建 → 安排 → 开始 → 持续 → 完成

可能原因：

其他解释：

严重程度：高 / 中 / 低

漏洞2

同上。

最多五项。

最大隐藏损耗

指出一个用户可能没有意识到、但数据中较明显的问题。

三个修复动作

修复动作	具体做法	成本	预计影响

要求：

* 最多三项；
* 一周内可以执行；
* 不需要学习新系统；
* 不增加明显记录负担。

一周修复挑战

生成一个7天以内的行动挑战。

例如结构：

* 第1—2天：只调整一个变量；
* 第3—5天：观察结果；
* 第6—7天：比较变化。

不建议你做的事

根据数据指出一到两项不适合用户当前状态的做法，例如：

* 不建议一次安排太多任务；
* 不建议强行延长专注时间；
* 不建议继续增加分类和标签。

需要用户确认的问题

只问三个问题。

用户数据

【events】

【steps】

【pomodoro_sessions】

【pomodoro_interruptions】

【pomodoro_ideas】

【pomodoro_step_records】

【pomodoro_event_edit_logs】''';

  static const _nextWeekBoostPrompt = '''数据量与过拟合提醒

在开始分析前，请先检查本次数据的覆盖时间、有效事件数量、专注会话数量以及关键字段完整度。

如果数据覆盖时间较短、样本数量较少、任务类型过于单一，或大量字段缺失，则必须明确提醒用户：

当前报告基于有限的个人行为数据，部分结论可能只是短期波动或特定情境下的偶发现象，存在将少量样本过度解释为稳定模式的风险。

请遵守以下规则：

1. 数据覆盖少于7天，或有效事件少于10个时，不得使用“稳定习惯”“长期模式”“你一贯会”等确定性表达。
2. 有效专注会话少于5次时，不得判断用户最适合的专注时长、时间段或打断规律。
3. 某一现象只出现1—2次时，只能描述为“个别记录”或“值得继续观察”，不得归纳为行动特征。
4. 只有在多个事件、多个日期或不同任务类型中重复出现的现象，才可以称为“初步趋势”。
5. 样本不足时，应降低结论置信度，并优先提出需要继续观察的问题，而不是强行生成完整画像。
6. 不得因为缺失数据而自动把“没有记录”解释为“没有发生”。
7. 建议应被表述为小型试验，而不是长期处方。
8. 如果分析结果高度依赖单个异常事件，应明确指出该事件对结论的影响。
9. 输出结尾必须单独增加：

数据可信度说明

说明：

* 本次分析使用了多少天的数据；
* 包含多少个有效事件和专注会话；
* 哪些字段缺失或记录不稳定；
* 哪些结论可能存在过拟合；
* 建议至少继续记录多久后再进行下一次分析。

当数据不足时，宁可少下结论，也不要为了让报告显得丰富而过度解释。
你是一名行动策略教练。

请根据用户导出的全部任务、专注、打断、步骤、想法和修改数据，为用户生成一份“下周开挂方案”。

“开挂”只是一种轻松表达，实际内容必须科学、克制、可执行。

你的任务不是分析所有问题，而是从数据中找出：

* 下周最值得保留的做法；
* 最值得停止的做法；
* 最值得尝试的三个小调整；
* 用户最适合的任务节奏；
* 如何减少启动和执行阻力。

分析原则

1. 所有建议必须有数据依据。
2. 不得进行人格评价或心理诊断。
3. 不要一次改变太多变量。
4. 最多给三个核心调整。
5. 调整必须适合用户当前真实节奏，而不是理想化计划。
6. 不要求用户突然变得极度自律。
7. 允许任务缩小、推迟、删除或重新拆解。
8. 优先设计可验证的小实验。

重点分析

* 用户通常在哪个时间段更容易开始；
* 单次专注的舒适时长；
* 哪类任务适合先拆解；
* 哪类任务可以直接开始；
* 用户的预计时间需要上调还是下调；
* 哪些打断可以提前处理；
* 哪些任务值得固定时间安排；
* 哪些任务不值得继续维护；
* 临时想法是否需要集中处理；
* 重要不紧急任务是否长期被挤压。

输出格式

你的下周开挂方案

本周一句话总结

用一句清楚的话概括用户当前状态。

例如风格：

* 你现在不是做得少，而是把太多精力花在启动前。
* 你的专注能力够用，真正的问题是计划过满。
* 你最适合短时间推进，而不是一次做完。

不得照抄示例。

下周保留

列出两项当前有效做法，并说明数据依据。

下周停止

列出一到两项应该暂停的做法。

例如：

* 不再为简单任务做完整拆解；
* 不再一次安排过多任务；
* 不再强迫自己延长专注时长。

下周三个核心调整

调整一：名称

为什么：

具体做法：

适用任务：

持续时间：

判断标准：

共三项。

你的最佳行动节奏

根据数据生成：

* 建议单次专注时长；
* 建议休息间隔；
* 适合处理复杂任务的时间段；
* 适合处理简单任务的时间段；
* 每天建议安排的核心任务数量。

若数据不足，不得强行给数字。

下周任务安排原则

用五条以内的简单规则，例如：

* 超过60分钟的任务先拆成第一步；
* 简单任务直接开始，不进入完整拆解；
* 重要不紧急任务优先固定时间；
* 高频打断事务集中批量处理；
* 当天未完成任务不自动无限顺延。

规则必须根据数据生成。

三个如果—那么计划

输出实施意图格式：

1. 如果【情境】，那么我先【最小动作】。
2. 如果【情境】，那么我把任务缩小为【备用动作】。
3. 如果【情境】，那么我暂停【无效动作】并改为【替代动作】。

下周挑战

设计一个轻量挑战，名称可以有传播感，例如：

* 先做10分钟挑战
* 不排满一周挑战
* 一次只改一个变量挑战
* 重要任务抢救计划

内容必须符合用户数据。

下周复盘时只看这三个指标

只选三个最重要指标，并解释为什么。

给用户的一句提醒

一句中性、具体、不鸡汤的话。

用户数据

【events】

【steps】

【pomodoro_sessions】

【pomodoro_interruptions】

【pomodoro_ideas】

【pomodoro_step_records】

【pomodoro_event_edit_logs】''';

  static const _analysisDirections = [
    _AnalysisDirection(
      title: '我的行动人格报告',
      subtitle: '总结我的行动偏好与执行模式',
      icon: Icons.psychology_rounded,
      prompt: _actionPersonalityPrompt,
    ),
    _AnalysisDirection(
      title: '我的效率漏洞体检',
      subtitle: '找出拖延、分心与低效触发点',
      icon: Icons.health_and_safety_rounded,
      prompt: _efficiencyCheckupPrompt,
    ),
    _AnalysisDirection(
      title: '我的下周开挂方案',
      subtitle: '生成下周任务与专注优化建议',
      icon: Icons.rocket_launch_rounded,
      prompt: _nextWeekBoostPrompt,
    ),
  ];

  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;

    return Scaffold(
      backgroundColor: ArrangeStyle.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 20,
            compact ? 14 : 18,
            compact ? 16 : 20,
            compact ? 76 : 84,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '数据',
                style: TextStyle(
                  color: const Color(0xFF101D46),
                  fontSize: compact ? 24 : 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              SizedBox(height: compact ? 16 : 20),
              _ExportDataCard(
                exporting: _exporting,
                onTap: _exporting ? null : _exportAndShare,
              ),
              SizedBox(height: compact ? 14 : 18),
              const _AiHint(),
              SizedBox(height: compact ? 22 : 28),
              const _SectionHeader(),
              const SizedBox(height: 12),
              for (final direction in _analysisDirections) ...[
                _AnalysisDirectionTile(
                  direction: direction,
                  onCopy: () => _copyDirection(direction),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportAndShare() async {
    setState(() => _exporting = true);
    try {
      final file = await _writeExportFile();
      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          title: '一刻数据导出',
          files: [XFile(file.path, mimeType: 'application/json')],
          fileNameOverrides: [p.basename(file.path)],
          sharePositionOrigin: _sharePositionOrigin(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack('导出失败：$error');
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<File> _writeExportFile() async {
    final db = await LocalDatabase.database;
    final tableData = <String, Object?>{};
    for (final table in _exportTables) {
      tableData[table] = await db.query(table, orderBy: 'id ASC');
    }

    final payload = {
      'exported_at': DateTime.now().toIso8601String(),
      'tables': tableData,
    };
    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, 'yike_data_export.json'));
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(
      encoder.convert(payload),
      encoding: utf8,
      flush: true,
    );
    return file;
  }

  Rect? _sharePositionOrigin() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  Future<void> _copyDirection(_AnalysisDirection direction) async {
    await Clipboard.setData(ClipboardData(text: direction.prompt));
    if (!mounted) return;
    _showSnack('已复制');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _ExportDataCard extends StatelessWidget {
  const _ExportDataCard({required this.exporting, required this.onTap});

  final bool exporting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ArrangeStyle.surface,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 128),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFEAF2FB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x145C8FC5),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (exporting)
                const SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(strokeWidth: 4),
                )
              else
                const Icon(
                  Icons.file_upload_outlined,
                  color: ArrangeStyle.accent,
                  size: 42,
                ),
              const SizedBox(height: 12),
              Text(
                exporting ? '正在导出...' : '导出数据',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ArrangeStyle.accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '导出你的时间与任务数据，便于深入分析',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF68728C),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiHint extends StatelessWidget {
  const _AiHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3F0FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: ArrangeStyle.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '可以使用这些数据询问AI',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ArrangeStyle.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '让 AI 基于你的数据为你提供分析与建议',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ArrangeStyle.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 5,
              height: 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ArrangeStyle.accent,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              '分析方向',
              style: TextStyle(
                color: Color(0xFF101D46),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          '选择一个问题，让 AI 基于你的数据为你分析',
          style: TextStyle(
            color: ArrangeStyle.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _AnalysisDirectionTile extends StatelessWidget {
  const _AnalysisDirectionTile({required this.direction, required this.onCopy});

  final _AnalysisDirection direction;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: ArrangeStyle.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAF2FB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x125C8FC5),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _DirectionIcon(icon: direction.icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  direction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF101D46),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  direction.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ArrangeStyle.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonalIcon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 17),
            label: const Text('复制'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(76, 40),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              backgroundColor: ArrangeStyle.accentSoft,
              foregroundColor: ArrangeStyle.accent,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionIcon extends StatelessWidget {
  const _DirectionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: ArrangeStyle.accentSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: ArrangeStyle.accent, size: 28),
    );
  }
}

class _AnalysisDirection {
  final String title;
  final String subtitle;
  final IconData icon;
  final String prompt;

  const _AnalysisDirection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.prompt,
  });
}
